// swiftlint:disable file_length
import Engine
import PrepFlowData
import SwiftUI

@MainActor
final class BoardStore: ObservableObject {
    @Published private(set) var completed: Set<String>
    @Published private(set) var catalog: CatalogTemplate
    @Published private(set) var service: ServiceDaySettings
    @Published private(set) var simulation: SimulationSummary
    @Published private(set) var settingsLocked = true
    @Published private(set) var etaOverride: ETA?
    @Published private(set) var dayrailItems: [DayrailItem] = []
    @Published private(set) var sharedPrepAggregate: AggregatedQuantity?
    @Published private(set) var closeLoopSummary: CloseLoopSummary?
    @Published private(set) var reservationDiffSummary: ReservationDiffSummary?
    @Published private(set) var reservationPlanDiff: PlanDiff?
    @Published private(set) var latestPrepLabel: PrepLabel?
    @Published private(set) var larderItems: [PrepLarderItem] = []
    @Published private(set) var latestConnectorReservation: NormalizedReservation?
    @Published private(set) var latestDirectBooking: DirectBooking?
    @Published private(set) var serviceSyncState: ServiceSyncState?
    @Published private(set) var servicePacingProposal: PacingProposal?
    @Published private(set) var latestDirectDecision: DirectBookingDecision?
    @Published private(set) var latestNoShowSettlement: DirectNoShowSettlement?
    @Published private(set) var specialPrepTasks: [SpecialPrepTask] = []
    @Published private(set) var allergenLabels: [AllergenLabel] = []
    @Published private(set) var guestMessages: [GuestMessage] = []
    @Published private(set) var passSeatFlags: [PassSeatFlag] = []
    @Published private(set) var passState: ServicePassState?
    @Published private(set) var storeSummaries: [StoreServiceSummary] = []

    private let database: PrepFlowDatabase?
    private let tenantID: String
    private let restaurantID = "restaurant-hayashi"
    private let sectionOwnerID = "section-oyakata"
    private let sectionGardeID = "section-garde"
    private let serviceCoverID = "cover-omakase"
    private let storageColdID = "storage-cold-2"
    private let tableCheckConnectorID = "connector-tablecheck-mock"
    private var eventSequence = 0
    private var catalogSequence = 0
    private var wasteSequence = 0
    private var serviceSyncEvents: [ServiceSyncEvent] = []

    init(
        completed: Set<String> = ["sake", "shari", "neta"],
        catalog: CatalogTemplate = .seed,
        service: ServiceDaySettings = .seed,
        simulation: SimulationSummary = .seed,
        database: PrepFlowDatabase? = AppDatabaseFactory.makeDatabase(),
        tenantID: String = "tenant-local"
    ) {
        self.completed = completed
        self.catalog = catalog
        self.service = service
        self.simulation = simulation
        self.database = database
        self.tenantID = tenantID
        syncNikiriRollup()
        persistCatalogSeed()
        persistServiceSeed()
    }

    var nikiriRollupStatus: TaskStatus {
        rollup(TaskNode(id: "nikiri", children: focusTaskNodes)).status ?? .notStarted
    }

    var eta: ETA {
        if let etaOverride {
            return etaOverride
        }
        return etaProjection(now: "17:25", t0: "18:00", remainingDurationsMin: [15, 15, 17])
    }

    var selectedCatalogTask: CatalogPrepTask {
        task(id: catalog.selectedTaskID) ?? CatalogTemplate.seed.dishes[0].components[1].tasks[0]
    }

    var nikiriTask: PrepTask {
        (task(id: "task-nikiri") ?? selectedCatalogTask).engineTask
    }

    var nikiriQuantity: Quantity {
        calcQty(nikiriTask, covers: service.omakaseCovers)
    }

    var nikiriSchedule: Scheduled {
        schedule(task: nikiriTask, serviceDate: service.date, t0: service.openTime, closedDates: [])
    }

    var covers: Int {
        service.totalCovers
    }

    var serviceTime: String {
        service.openTime
    }

    func selectTask(_ id: String) {
        guard task(id: id) != nil else {
            return
        }
        catalog.selectedTaskID = id
    }

    func addDish() {
        catalogSequence += 1
        let dish = CatalogDish(id: "dish-custom-\(catalogSequence)", name: "新しい料理 \(catalogSequence)", components: [], sort: catalog.dishes.count)
        catalog.dishes.append(dish)
        persistDish(dish)
    }

    func addComponent() {
        guard let dishIndex = selectedDishIndex else {
            return
        }
        catalogSequence += 1
        let component = CatalogComponent(id: "component-custom-\(catalogSequence)", name: "構成要素 \(catalogSequence)", tasks: [], sort: catalog.dishes[dishIndex].components.count)
        catalog.dishes[dishIndex].components.append(component)
        persistComponent(component, dishID: catalog.dishes[dishIndex].id)
    }

    func addTask() {
        guard let selectedPath else {
            return
        }
        catalogSequence += 1
        let task = CatalogPrepTask(
            id: "task-custom-\(catalogSequence)",
            name: "サブ仕込み \(catalogSequence)",
            coeffPerCover: 1,
            unit: "個",
            sectionName: "親方",
            sort: catalog.dishes[selectedPath.dish].components[selectedPath.component].tasks.count
        )
        catalog.dishes[selectedPath.dish].components[selectedPath.component].tasks.append(task)
        catalog.selectedTaskID = task.id
        persistTask(task, componentID: catalog.dishes[selectedPath.dish].components[selectedPath.component].id)
    }

    func updateSelectedTask(
        name: String? = nil,
        coeffPerCover: Double? = nil,
        yieldPercent: Double? = nil,
        durationMin: Int? = nil,
        leadMinBeforeOpen: Int? = nil,
        sectionName: String? = nil,
        instruction: String? = nil
    ) {
        guard let selectedPath else {
            return
        }

        var task = catalog.dishes[selectedPath.dish].components[selectedPath.component].tasks[selectedPath.task]
        task.name = name ?? task.name
        task.coeffPerCover = coeffPerCover ?? task.coeffPerCover
        task.yieldPercent = yieldPercent ?? task.yieldPercent
        task.durationMin = durationMin ?? task.durationMin
        task.leadMinBeforeOpen = leadMinBeforeOpen ?? task.leadMinBeforeOpen
        task.sectionName = sectionName ?? task.sectionName
        task.instruction = instruction ?? task.instruction
        catalog.dishes[selectedPath.dish].components[selectedPath.component].tasks[selectedPath.task] = task
        persistTaskUpdate(task)
    }

    func updateOmakaseCovers(_ covers: Int) {
        service.omakaseCovers = max(0, covers)
        persistServiceCover()
    }

    func updateOtherCovers(_ covers: Int) {
        service.otherCovers = max(0, covers)
        persistServiceCover()
    }

    func updateOpenTime(_ openTime: String) {
        service.openTime = openTime
        persistServiceDayUpdate()
    }

    func selectServicePeriod(_ id: String) {
        guard let period = service.periods.first(where: { $0.id == id }) else {
            return
        }

        service.selectedPeriodID = period.id
        service.period = period.label
        service.openTime = period.openTime
        persistServicePeriods()
        persistServiceDayUpdate()
        persistEvent(type: "service_period.selected", payload: "{\"service_period_id\":\"\(period.id)\",\"open_time\":\"\(period.openTime)\"}")
    }

    func assignNikiri(toSectionName sectionName: String) {
        selectTask("task-nikiri")
        updateSelectedTask(sectionName: sectionName)
        persistTaskInstances()
        persistEvent(type: "task.assigned", payload: "{\"task_id\":\"task-nikiri\",\"section\":\"\(sectionName)\"}")
    }

    func recordETAInput(now: String, remainingDurationsMin: [Int]) {
        etaOverride = etaProjection(now: now, t0: service.openTime, remainingDurationsMin: remainingDurationsMin)
        persistEvent(
            type: "eta.recorded",
            payload: "{\"landing\":\"\(etaOverride?.landing ?? "")\",\"shortfall_min\":\(etaOverride?.shortfallMin ?? 0)}"
        )
        try? database?.create(.settings, values: [
            "id": "setting-eta-last",
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "key": "eta.last",
            "value": "{\"now\":\"\(now)\",\"landing\":\"\(etaOverride?.landing ?? "")\"}",
        ])
        try? database?.update(.settings, id: "setting-eta-last", tenantID: tenantID, values: [
            "value": "{\"now\":\"\(now)\",\"landing\":\"\(etaOverride?.landing ?? "")\"}",
        ])
    }

    func addManualReservation() {
        catalogSequence += 1
        let reservation = ManualReservation(
            id: "reservation-manual-\(catalogSequence)",
            visitTime: service.openTime,
            partyName: "手入力 \(catalogSequence)組",
            note: "手入力・当日追加",
            covers: 2
        )
        service.reservations.append(reservation)
        recalculateCoversFromReservations()
        persistReservation(reservation)
        persistServiceCover()
        persistEvent(type: "reservation.created", payload: "{\"reservation_id\":\"\(reservation.id)\",\"covers\":\(reservation.covers)}")
    }

    func editReservation(_ id: String) {
        guard let index = service.reservations.firstIndex(where: { $0.id == id }) else {
            return
        }

        service.reservations[index].covers += 1
        service.reservations[index].note = "編集済み・\(service.reservations[index].covers)名"
        recalculateCoversFromReservations()
        try? database?.update(.reservation, id: id, tenantID: tenantID, values: [
            "covers": String(service.reservations[index].covers),
            "party_name": service.reservations[index].partyName,
        ])
        persistServiceCover()
        persistEvent(type: "reservation.updated", payload: "{\"reservation_id\":\"\(id)\",\"covers\":\(service.reservations[index].covers)}")
    }

    func generateBoardFromService() {
        persistServiceDayUpdate()
        persistServiceCover()
        persistTaskInstances()
        persistEvent(type: "board.generated", payload: "{\"service_day_id\":\"\(service.id)\",\"covers\":\(service.totalCovers)}")
    }

    func prepareDayrail() {
        dayrailItems = planDayrail(
            prepTasks: allCatalogTasks.map(\.engineTask),
            serviceDate: service.date,
            t0: service.openTime,
            closedDates: [],
            operations: [
                DayrailOperation(id: "ops-service-standup", kind: .service, title: "営業前ミーティング", startOffsetMin: -30, durationMin: 10),
                DayrailOperation(id: "ops-close-handoff", kind: .close, title: "締め申し送り", startOffsetMin: 150, durationMin: 20),
            ]
        )
        persistDayrailItems()
        persistEvent(type: "dayrail.planned", payload: "{\"service_day_id\":\"\(service.id)\",\"items\":\(dayrailItems.count)}")
    }

    @discardableResult
    func aggregateSharedPrep() -> AggregatedQuantity {
        var references: [(course: String, covers: Int)] = [("omakase", service.omakaseCovers)]
        if service.otherCovers > 0 {
            references.append(("walkin", service.otherCovers))
        }
        let aggregate = aggregateSubrecipes(nikiriTask, references: references)
        sharedPrepAggregate = aggregate
        persistSubrecipeAggregate(aggregate, status: nikiriRollupStatus)
        persistEvent(
            type: "subrecipe.aggregated",
            payload: "{\"task_id\":\"\(aggregate.task)\",\"total_covers\":\(aggregate.totalCovers),\"total_qty\":\(numberString(aggregate.quantity.total))}"
        )
        return aggregate
    }

    func completeSharedPrepAggregate() {
        markAllNowDone()
        let aggregate = sharedPrepAggregate ?? aggregateSharedPrep()
        persistSubrecipeAggregate(aggregate, status: nikiriRollupStatus)
        persistEvent(type: "subrecipe.rollup_completed", payload: "{\"task_id\":\"\(aggregate.task)\",\"status\":\"\(nikiriRollupStatus.rawValue)\"}")
    }

    func recordNikiriWaste(madeQty: Double = 240, leftoverQty: Double = 40) {
        wasteSequence += 1
        try? database?.create(.wasteLog, values: [
            "id": "waste-nikiri-\(wasteSequence)",
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "prep_task_id": "task-nikiri",
            "covers": String(service.omakaseCovers),
            "planned_qty": numberString(nikiriQuantity.total),
            "made_qty": numberString(madeQty),
            "leftover_qty": numberString(leftoverQty),
            "waste_reason": "overmade",
            "carryover_to_next": "1",
            "unit": "ml",
            "recorded_by": "local-ipad",
        ])
        persistEvent(type: "waste.recorded", payload: "{\"task_id\":\"task-nikiri\",\"leftover_qty\":\(numberString(leftoverQty))}")
    }

    func recordNikiriCarryover(qty: Double = 40) {
        let carryoverID = "carryover-nikiri-\(wasteSequence + 1)"
        try? database?.create(named: "carryover", values: [
            "id": carryoverID,
            "tenant_id": tenantID,
            "from_service_day_id": service.id,
            "to_service_day_id": nil,
            "prep_task_id": "task-nikiri",
            "qty": numberString(qty),
            "unit": "ml",
            "expire_at": "\(service.date)T23:59:00Z",
            "status": "available",
        ])
        persistEvent(type: "carryover.created", payload: "{\"task_id\":\"task-nikiri\",\"qty\":\(numberString(qty))}")
    }

    func applySimulationCoefficients() {
        selectTask("task-nikiri")
        updateSelectedTask(coeffPerCover: 12, yieldPercent: selectedCatalogTask.yieldPercent)
        persistEvent(type: "simulation.applied", payload: "{\"task_id\":\"task-nikiri\",\"coeff_per_cover\":12}")
    }

    func applySimulationAdjustment() {
        simulation.hitRatePercent = min(99, simulation.hitRatePercent + 1)
        simulation.stockoutRisks = max(0, simulation.stockoutRisks - 1)
        persistEvent(type: "simulation.adjusted", payload: "{\"hit_rate_percent\":\(simulation.hitRatePercent)}")
    }

    func changeSimulationPeriod() {
        simulation.lossSavingYen += 4000
        persistEvent(type: "simulation.period_changed", payload: "{\"period_days\":30}")
    }

    func saveCatalogForBoard() {
        persistCatalogSeed()
        persistTaskInstances()
        persistEvent(type: "catalog.saved", payload: "{\"course_template_id\":\"\(catalog.id)\"}")
    }

    func toggleSettingsLock() {
        settingsLocked.toggle()
        try? database?.create(.settings, values: [
            "id": "setting-lock",
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "key": "settings.lock",
            "value": settingsLocked ? "locked" : "unlocked",
        ])
        try? database?.update(.settings, id: "setting-lock", tenantID: tenantID, values: [
            "value": settingsLocked ? "locked" : "unlocked",
        ])
        persistEvent(type: "settings.lock_toggled", payload: "{\"locked\":\(settingsLocked)}")
    }

    func exportSnapshotJSON() -> String {
        let payload = [
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "service_period_id": service.selectedPeriodID,
            "open_time": service.openTime,
            "covers": String(service.totalCovers),
            "eta_landing": eta.landing,
            "settings_lock": settingsLocked ? "locked" : "unlocked",
        ]
        persistEvent(type: "data.exported", payload: "{\"format\":\"json\"}")
        return "{\(payload.keys.sorted().map { "\"\($0)\":\"\(payload[$0] ?? "")\"" }.joined(separator: ","))}"
    }

    func toggle(_ id: String) {
        if id == "nikiri" {
            markAllNowDone()
            return
        }

        if completed.contains(id) {
            completed.remove(id)
        } else {
            completed.insert(id)
        }
        syncNikiriRollup()
        persistOfflineEvent(taskID: id)
    }

    func markAllNowDone() {
        completed.formUnion(["sake", "tare", "rest"])
        syncNikiriRollup()
        persistOfflineEvent(taskID: "nikiri")
    }
}

extension BoardStore {
    @discardableResult
    func replayConnectorReservation(_ event: SourceReservationEvent) -> ReservationDiffSummary {
        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
        let normalized = normalizeReservationEvent(event)
        latestConnectorReservation = normalized
        persistConnectorAccount(provider: event.provider)
        persistSourceReservationEvent(event, normalized: normalized)
        applyNormalizedReservation(normalized)
        persistServiceCover()

        let diff = reservationDiff(previous: previous, current: reservationSnapshots())
        reservationDiffSummary = diff
        reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
        persistReservationDiff(diff, kind: "connector")
        persistEvent(
            type: "connector.reservation_applied",
            payload: "{\"source\":\"\(normalized.source)\",\"reservation_id\":\"\(normalized.id)\",\"status\":\"\(normalized.status)\"}"
        )
        return diff
    }

    @discardableResult
    func acceptDirectBooking(_ booking: DirectBooking, depositRequired: Bool = true) -> ReservationDiffSummary {
        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
        let checkout = startDirectBookingCheckout(booking, depositRequired: depositRequired)
        let confirmed = confirmedDirectBooking(booking, checkout: checkout)
        let normalized = normalizeDirectBooking(confirmed)

        latestDirectBooking = confirmed
        persistDirectBooking(confirmed)
        applyNormalizedReservation(normalized)
        persistServiceCover()

        let diff = reservationDiff(previous: previous, current: reservationSnapshots())
        reservationDiffSummary = diff
        reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
        persistReservationDiff(diff, kind: "direct")
        persistEvent(
            type: "direct_booking.accepted",
            payload: "{\"booking_id\":\"\(confirmed.id)\",\"reservation_id\":\"\(normalized.id)\",\"checkout_id\":\"\(checkout.checkoutID ?? "")\"}"
        )
        return diff
    }

    @discardableResult
    func cancelDirectBooking(_ bookingID: String) -> ReservationDiffSummary {
        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
        let current = latestDirectBooking ?? DirectBooking(
            id: bookingID,
            visitTime: service.openTime,
            covers: 0,
            course: catalog.courseName,
            guestName: "Direct guest",
            status: .cancelled
        )
        let cancelled = DirectBooking(
            id: current.id,
            visitTime: current.visitTime,
            covers: current.covers,
            course: current.course,
            guestName: current.guestName,
            guestNote: current.guestNote,
            status: .cancelled,
            stripeCheckoutID: current.stripeCheckoutID
        )
        let normalized = normalizeDirectBooking(cancelled)

        latestDirectBooking = cancelled
        persistDirectBooking(cancelled)
        applyNormalizedReservation(normalized)
        persistServiceCover()

        let diff = reservationDiff(previous: previous, current: reservationSnapshots())
        reservationDiffSummary = diff
        reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
        persistReservationDiff(diff, kind: "direct_cancel")
        persistEvent(
            type: "direct_booking.cancelled",
            payload: "{\"booking_id\":\"\(cancelled.id)\",\"reservation_id\":\"\(normalized.id)\"}"
        )
        return diff
    }

    @discardableResult
    func evaluateDirectAllotment(_ booking: DirectBooking, allottedCovers: Int) -> DirectBookingDecision {
        let directRows = (try? database?.rows(named: "direct_booking", tenantID: tenantID)) ?? []
        let booked = directRows
            .filter { $0.values["status"] == "confirmed" }
            .reduce(0) { $0 + (Int($1.values["covers"] ?? "") ?? 0) }
        let decision = evaluateDirectBooking(
            booking,
            allotment: DirectAllotment(
                id: "allotment-\(service.id)-\(booking.visitTime)",
                serviceDayID: service.id,
                slot: booking.visitTime,
                allottedCovers: allottedCovers,
                bookedCovers: booked
            )
        )
        latestDirectDecision = decision
        if decision.status == .request {
            persistDirectBooking(booking)
            persistWaitlistEntry(booking)
        }
        persistEvent(
            type: "direct_booking.evaluated",
            payload: "{\"booking_id\":\"\(booking.id)\",\"reason\":\"\(decision.reason)\",\"waitlist_covers\":\(decision.waitlistCovers)}"
        )
        return decision
    }

    @discardableResult
    func recordDirectNoShow(_ booking: DirectBooking, forfeitsDeposit: Bool = true) -> DirectNoShowSettlement {
        let settlement = Engine.recordDirectNoShow(booking, forfeitsDeposit: forfeitsDeposit)
        let noshow = DirectBooking(
            id: booking.id,
            visitTime: booking.visitTime,
            covers: booking.covers,
            course: booking.course,
            guestName: booking.guestName,
            guestNote: booking.guestNote,
            status: .noshow,
            stripeCheckoutID: booking.stripeCheckoutID
        )
        latestNoShowSettlement = settlement
        persistDirectBooking(noshow)
        persistEvent(
            type: "direct_booking.noshow_recorded",
            payload: "{\"booking_id\":\"\(booking.id)\",\"forfeits_deposit\":\(settlement.forfeitsDeposit),\"prep_impact_covers\":\(settlement.prepImpactCovers)}"
        )
        return settlement
    }

    @discardableResult
    func replayGuestSignals(_ reservation: NormalizedReservation, seatRef: String = "卓3", language: String = "ja") -> [GuestSignal] {
        let signals = guestSignals(from: reservation)
        let prepTasks = Engine.specialPrepTasks(from: signals)
        let labels = Engine.allergenLabels(from: signals, seatRef: seatRef, language: language)
        let message = guestConfirmationMessage(reservation, language: language)

        specialPrepTasks.append(contentsOf: prepTasks)
        allergenLabels.append(contentsOf: labels)
        guestMessages.append(message)
        passSeatFlags.append(contentsOf: labels.map {
            PassSeatFlag(
                id: "pass-flag-\($0.id)",
                reservationID: $0.reservationID,
                seatRef: $0.seatRef,
                kind: .allergy,
                displayText: $0.displayText
            )
        })

        for task in prepTasks {
            persistSpecialPrep(task)
        }
        for label in labels {
            persistAllergenLabel(label)
        }
        persistGuestMessage(message)
        for flag in passSeatFlags {
            persistPassSeatFlag(flag)
        }
        refreshPassState()
        persistEvent(type: "guest_signals.replayed", payload: "{\"reservation_id\":\"\(reservation.id)\",\"signals\":\(signals.count)}")
        return signals
    }

    @discardableResult
    func replayServiceSyncEvent(
        _ event: ServiceSyncEvent,
        elapsedMinutes: Int = 60,
        serviceMinutes: Int = 120
    ) -> ServiceSyncState {
        if let index = serviceSyncEvents.firstIndex(where: { $0.id == event.id }) {
            serviceSyncEvents[index] = event
        } else {
            serviceSyncEvents.append(event)
        }

        persistServiceSyncEvent(event)
        let state = Engine.serviceSyncState(
            plannedCovers: service.omakaseCovers,
            events: serviceSyncEvents,
            elapsedMinutes: elapsedMinutes,
            serviceMinutes: serviceMinutes
        )
        serviceSyncState = state
        servicePacingProposal = state.pacing
        refreshPassState()
        refreshStoreSummary(state)
        let payload = """
        {"service_event_id":"\(event.id)","kind":"\(event.kind.rawValue)","remaining_covers":\(state.remainingCovers),"recommendation":"\(state.pacing.recommendation)"}
        """
        persistEvent(
            type: "service_sync.replayed",
            payload: payload
        )
        return state
    }

    @discardableResult
    func replayServiceSyncEvents(
        _ events: [ServiceSyncEvent],
        elapsedMinutes: Int = 60,
        serviceMinutes: Int = 120
    ) -> ServiceSyncState {
        var state = Engine.serviceSyncState(
            plannedCovers: service.omakaseCovers,
            events: serviceSyncEvents,
            elapsedMinutes: elapsedMinutes,
            serviceMinutes: serviceMinutes
        )
        for event in events {
            state = replayServiceSyncEvent(event, elapsedMinutes: elapsedMinutes, serviceMinutes: serviceMinutes)
        }
        return state
    }

    @discardableResult
    func issueNikiriPrepLabel(
        madeQty: Double? = nil,
        printedAt: String = "2026-06-11T16:20:00Z",
        storageUnitID: String? = nil
    ) -> PrepLabel {
        markAllNowDone()
        persistTaskInstances()
        let label = issuePrepLabel(
            task: nikiriTask,
            taskInstanceID: "instance-task-nikiri",
            madeQty: madeQty ?? nikiriQuantity.total,
            printedAt: printedAt,
            storageUnitID: storageUnitID ?? storageColdID
        )
        latestPrepLabel = label
        persistPrepLabel(label)
        upsertLarderItem(
            PrepLarderItem(
                id: "larder-\(label.id)",
                labelID: label.id,
                prepTaskID: label.prepTaskID,
                qty: label.madeQty,
                unit: label.unit,
                expireAt: label.expireAt,
                status: .available
            )
        )
        persistEvent(type: "label.printed", payload: "{\"label_id\":\"\(label.id)\",\"task_id\":\"\(label.prepTaskID)\",\"qty\":\(numberString(label.madeQty))}")
        return label
    }

    @discardableResult
    func scanLatestLabelRemaining(qty: Double) -> LabelScanResult {
        let label = latestPrepLabel ?? issueNikiriPrepLabel()
        let result = scanPrepLabel(label, action: .remaining(qty: qty))
        persistLabelScanResult(result, scanKind: "remaining")
        if let larder = result.larderItem, larder.qty > 0 {
            persistLabelCarryover(larder)
        }
        return result
    }

    @discardableResult
    func scanLatestLabelWaste(qty: Double, reason: WasteReason = .quality) -> LabelScanResult {
        let label = latestPrepLabel ?? issueNikiriPrepLabel()
        let result = scanPrepLabel(label, action: .wasted(qty: qty, reason: reason))
        persistLabelScanResult(result, scanKind: "wasted")
        return result
    }

    @discardableResult
    func recordCloseLoop(
        madeQty: Double = 240,
        leftoverQty: Double = 40,
        wasteReason: WasteReason = .overmade,
        carryoverToNext: Bool = true
    ) -> CloseLoopSummary {
        wasteSequence += 1
        let record = CloseTaskRecord(
            task: "task-nikiri",
            plannedQty: nikiriQuantity.total,
            madeQty: madeQty,
            leftoverQty: leftoverQty,
            unit: nikiriQuantity.unit,
            wasteReason: wasteReason,
            carryoverToNext: carryoverToNext
        )
        let summary = closeLoop(
            records: [record],
            nextDayPlan: [(task: "task-nikiri", base: nikiriQuantity.total, unit: nikiriQuantity.unit)]
        )
        closeLoopSummary = summary
        persistCloseRecord(record)
        for carryover in summary.carryovers {
            persistCarryover(carryover, sequence: wasteSequence)
        }
        persistEvent(
            type: "close.completed",
            payload: "{\"service_day_id\":\"\(service.id)\",\"records\":\(summary.records.count),\"carryovers\":\(summary.carryovers.count)}"
        )
        if let adjustment = summary.nextDayAdjustments.first {
            persistEvent(
                type: "nextday.previewed",
                payload: "{\"task_id\":\"\(adjustment.task)\",\"base\":\(numberString(adjustment.base)),\"adjusted\":\(numberString(adjustment.adjusted))}"
            )
        }
        return summary
    }

    @discardableResult
    func previewReservationIncrease(_ id: String, addedCovers: Int = 1) -> ReservationDiffSummary {
        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
        guard let index = service.reservations.firstIndex(where: { $0.id == id }) else {
            let unchanged = reservationDiff(previous: previous, current: previous)
            reservationDiffSummary = unchanged
            reservationPlanDiff = PlanDiff()
            return unchanged
        }

        service.reservations[index].covers += max(0, addedCovers)
        service.reservations[index].note = "差分確認・\(service.reservations[index].covers)名"
        recalculateCoversFromReservations()
        try? database?.update(.reservation, id: id, tenantID: tenantID, values: [
            "covers": String(service.reservations[index].covers),
            "party_name": service.reservations[index].partyName,
        ])
        persistServiceCover()
        let diff = reservationDiff(previous: previous, current: reservationSnapshots())
        reservationDiffSummary = diff
        reservationPlanDiff = diffPlan(
            task: nikiriTaskWithRollupStatus,
            currentCovers: previousCovers,
            madeTotal: calcQty(nikiriTask, covers: previousCovers).total,
            change: .reservationAdded(deltaCovers: max(0, addedCovers), course: catalog.id)
        )
        persistReservationDiff(diff, kind: "increase")
        return diff
    }

    @discardableResult
    func previewReservationCancellation(_ id: String) -> ReservationDiffSummary {
        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
        guard let index = service.reservations.firstIndex(where: { $0.id == id }) else {
            let unchanged = reservationDiff(previous: previous, current: previous)
            reservationDiffSummary = unchanged
            reservationPlanDiff = PlanDiff()
            return unchanged
        }

        let cancelled = service.reservations.remove(at: index)
        recalculateCoversFromReservations()
        try? database?.softDelete(.reservation, id: cancelled.id, tenantID: tenantID)
        persistServiceCover()
        let diff = reservationDiff(previous: previous, current: reservationSnapshots())
        reservationDiffSummary = diff
        reservationPlanDiff = diffPlan(
            task: nikiriTaskWithRollupStatus,
            currentCovers: previousCovers,
            madeTotal: calcQty(nikiriTask, covers: previousCovers).total,
            change: .reservationCancelled(deltaCovers: -cancelled.covers, course: catalog.id)
        )
        persistReservationDiff(diff, kind: "cancel")
        if reservationPlanDiff?.reduced.contains(where: \.carryoverCandidate) == true {
            persistEvent(
                type: "reservation.carryover_candidate",
                payload: "{\"reservation_id\":\"\(cancelled.id)\",\"cancelled_covers\":\(cancelled.covers)}"
            )
        }
        return diff
    }
}

private extension BoardStore {
    private var focusTaskNodes: [TaskNode] {
        ["sake", "tare", "rest"].map { id in
            TaskNode(id: id, status: completed.contains(id) ? .done : .notStarted)
        }
    }

    private var selectedDishIndex: Int? {
        selectedPath?.dish ?? (catalog.dishes.isEmpty ? nil : 0)
    }

    private var selectedPath: (dish: Int, component: Int, task: Int)? {
        for dishIndex in catalog.dishes.indices {
            for componentIndex in catalog.dishes[dishIndex].components.indices {
                let tasks = catalog.dishes[dishIndex].components[componentIndex].tasks
                if let taskIndex = tasks.firstIndex(where: { $0.id == catalog.selectedTaskID }) {
                    return (dishIndex, componentIndex, taskIndex)
                }
            }
        }
        return nil
    }

    private func task(id: String) -> CatalogPrepTask? {
        for dish in catalog.dishes {
            for component in dish.components {
                if let task = component.tasks.first(where: { $0.id == id }) {
                    return task
                }
            }
        }
        return nil
    }

    private var nikiriTaskWithRollupStatus: PrepTask {
        var task = nikiriTask
        task.status = nikiriRollupStatus
        return task
    }

    private var allCatalogTasks: [CatalogPrepTask] {
        catalog.dishes.flatMap { dish in
            dish.components.flatMap(\.tasks)
        }
    }

    private func reservationSnapshots() -> [ReservationSnapshot] {
        service.reservations.map {
            ReservationSnapshot(id: $0.id, covers: $0.covers, course: catalog.id)
        }
    }

    private func planDiffForReservationDiff(_ diff: ReservationDiffSummary, previousCovers: Int) -> PlanDiff {
        if diff.addedCovers > 0 {
            return diffPlan(
                task: nikiriTaskWithRollupStatus,
                currentCovers: previousCovers,
                madeTotal: calcQty(nikiriTask, covers: previousCovers).total,
                change: .reservationAdded(deltaCovers: diff.addedCovers, course: catalog.id)
            )
        }
        if diff.cancelledCovers > 0 {
            return diffPlan(
                task: nikiriTaskWithRollupStatus,
                currentCovers: previousCovers,
                madeTotal: calcQty(nikiriTask, covers: previousCovers).total,
                change: .reservationCancelled(deltaCovers: -diff.cancelledCovers, course: catalog.id)
            )
        }
        return PlanDiff()
    }

    private func syncNikiriRollup() {
        if nikiriRollupStatus == .done {
            completed.insert("nikiri")
        } else {
            completed.remove("nikiri")
        }
    }

    private func recalculateCoversFromReservations() {
        service.omakaseCovers = service.reservations.reduce(0) { $0 + $1.covers }
    }

    private func persistOfflineEvent(taskID: String) {
        persistEvent(
            type: "task.completed",
            payload: "{\"task_id\":\"\(taskID)\",\"status\":\"\(nikiriRollupStatus.rawValue)\"}"
        )
    }

    private func persistEvent(type: String, payload: String) {
        eventSequence += 1
        try? database?.create(.eventLog, values: [
            "id": "event-\(eventSequence)-\(type.replacingOccurrences(of: ".", with: "-"))",
            "tenant_id": tenantID,
            "type": type,
            "payload": payload,
            "occurred_at": "2026-06-17T09:00:00Z",
            "actor": "local-ipad",
        ])
    }

    private func persistServiceSeed() {
        try? database?.create(.serviceDay, values: [
            "id": service.id,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "date": service.date,
            "service_period": "dinner",
            "open_time": service.openTime,
            "note": "P0 manual covers",
        ])
        persistServiceCover()
        persistServicePeriods()
        for reservation in service.reservations {
            persistReservation(reservation)
        }
    }

    private func persistServiceDayUpdate() {
        try? database?.update(.serviceDay, id: service.id, tenantID: tenantID, values: [
            "open_time": service.openTime,
            "service_period": service.periodCode,
        ])
    }

    private func persistServiceCover() {
        try? database?.create(.serviceCover, values: [
            "id": serviceCoverID,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "course_template_id": catalog.id,
            "covers": String(service.omakaseCovers),
        ])
        try? database?.update(.serviceCover, id: serviceCoverID, tenantID: tenantID, values: [
            "covers": String(service.omakaseCovers),
        ])
    }

    private func persistReservation(_ reservation: ManualReservation) {
        try? database?.create(.reservation, values: [
            "id": reservation.id,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "source": "manual",
            "visit_time": reservation.visitTime,
            "covers": String(reservation.covers),
            "course_template_id": catalog.id,
            "course_text": catalog.courseName,
            "party_name": reservation.partyName,
            "structured": "1",
        ])
    }

    private func applyNormalizedReservation(_ reservation: NormalizedReservation) {
        if reservation.status == "cancelled" {
            service.reservations.removeAll { $0.id == reservation.id }
            try? database?.softDelete(.reservation, id: reservation.id, tenantID: tenantID)
            recalculateCoversFromReservations()
            return
        }

        let manual = ManualReservation(
            id: reservation.id,
            visitTime: reservation.visitTime,
            partyName: reservation.partyName,
            note: reservation.prepNote ?? "外部予約・\(reservation.source)",
            covers: reservation.covers
        )
        if let index = service.reservations.firstIndex(where: { $0.id == reservation.id }) {
            service.reservations[index] = manual
            updateNormalizedReservation(reservation)
        } else {
            service.reservations.append(manual)
            persistNormalizedReservation(reservation)
        }
        recalculateCoversFromReservations()
    }

    private func persistNormalizedReservation(_ reservation: NormalizedReservation) {
        try? database?.create(.reservation, values: normalizedReservationValues(reservation))
    }

    private func updateNormalizedReservation(_ reservation: NormalizedReservation) {
        try? database?.update(.reservation, id: reservation.id, tenantID: tenantID, values: normalizedReservationValues(reservation))
    }

    private func normalizedReservationValues(_ reservation: NormalizedReservation) -> [String: String?] {
        [
            "id": reservation.id,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "source": reservation.source == "direct" ? "direct" : "api",
            "visit_time": reservation.visitTime,
            "covers": String(reservation.covers),
            "course_template_id": catalog.id,
            "course_text": reservation.course,
            "party_name": reservation.partyName,
            "structured": "1",
            "dup_group": reservation.externalID,
        ]
    }

    private func persistConnectorAccount(provider: ConnectorProvider) {
        let values: [String: String?] = [
            "id": connectorID(for: provider),
            "tenant_id": tenantID,
            "provider": provider.rawValue,
            "status": "mock",
            "external_account_id": "mock-\(restaurantID)",
            "last_sync_at": "2026-06-17T09:00:00Z",
        ]
        try? database?.create(named: "connector_account", values: values)
        try? database?.update(named: "connector_account", id: connectorID(for: provider), tenantID: tenantID, values: values)
    }

    private func persistSourceReservationEvent(_ event: SourceReservationEvent, normalized: NormalizedReservation) {
        let values: [String: String?] = [
            "id": event.id,
            "tenant_id": tenantID,
            "connector_account_id": connectorID(for: event.provider),
            "source": event.provider.rawValue,
            "external_id": event.externalID,
            "type": "reservation.\(event.status == "cancelled" ? "cancelled" : "upserted")",
            "payload": sourceReservationPayload(event, normalized: normalized),
            "occurred_at": "2026-06-17T09:00:00Z",
            "processed_at": "2026-06-17T09:00:01Z",
        ]
        try? database?.create(named: "source_event", values: values)
        try? database?.update(named: "source_event", id: event.id, tenantID: tenantID, values: values)
    }

    private func sourceReservationPayload(_ event: SourceReservationEvent, normalized: NormalizedReservation) -> String {
        "{\"external_id\":\"\(event.externalID)\",\"reservation_id\":\"\(normalized.id)\",\"covers\":\(event.covers),\"status\":\"\(event.status)\"}"
    }

    private func connectorID(for provider: ConnectorProvider) -> String {
        switch provider {
        case .tablecheck:
            tableCheckConnectorID
        case .toreta:
            "connector-toreta-mock"
        }
    }

    private func confirmedDirectBooking(_ booking: DirectBooking, checkout: DirectBookingCheckout) -> DirectBooking {
        DirectBooking(
            id: booking.id,
            visitTime: booking.visitTime,
            covers: booking.covers,
            course: booking.course,
            guestName: booking.guestName,
            guestNote: booking.guestNote,
            status: .confirmed,
            stripeCheckoutID: checkout.checkoutID
        )
    }

    private func persistDirectBooking(_ booking: DirectBooking) {
        let values: [String: String?] = [
            "id": booking.id,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "status": booking.status.rawValue,
            "visit_time": booking.visitTime,
            "covers": String(booking.covers),
            "course_text": booking.course,
            "guest_note": booking.guestNote,
            "stripe_checkout_id": booking.stripeCheckoutID,
        ]
        try? database?.create(named: "direct_booking", values: values)
        try? database?.update(named: "direct_booking", id: booking.id, tenantID: tenantID, values: values)
    }

    private func persistWaitlistEntry(_ booking: DirectBooking) {
        let values: [String: String?] = [
            "id": "waitlist-\(booking.id)",
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "direct_booking_id": booking.id,
            "visit_time": booking.visitTime,
            "covers": String(max(0, booking.covers)),
            "guest_name": booking.guestName,
            "status": "waiting",
        ]
        try? database?.create(named: "waitlist_entry", values: values)
        try? database?.update(named: "waitlist_entry", id: "waitlist-\(booking.id)", tenantID: tenantID, values: values)
    }

    private func persistSpecialPrep(_ task: SpecialPrepTask) {
        let values: [String: String?] = [
            "id": task.id,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "reservation_id": task.reservationID,
            "title": task.title,
            "note": task.note,
            "status": "not_started",
        ]
        try? database?.create(named: "special_prep", values: values)
        try? database?.update(named: "special_prep", id: task.id, tenantID: tenantID, values: values)
    }

    private func persistAllergenLabel(_ label: AllergenLabel) {
        let values: [String: String?] = [
            "id": label.id,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "reservation_id": label.reservationID,
            "seat_ref": label.seatRef,
            "display_text": label.displayText,
            "language": label.language,
        ]
        try? database?.create(named: "allergen_label", values: values)
        try? database?.update(named: "allergen_label", id: label.id, tenantID: tenantID, values: values)
    }

    private func persistGuestMessage(_ message: GuestMessage) {
        let values: [String: String?] = [
            "id": message.id,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "reservation_id": message.reservationID,
            "channel": "tablecheck_message",
            "language": message.language,
            "body": message.body,
            "status": message.status,
        ]
        try? database?.create(named: "guest_message", values: values)
        try? database?.update(named: "guest_message", id: message.id, tenantID: tenantID, values: values)
    }

    private func persistPassSeatFlag(_ flag: PassSeatFlag) {
        let values: [String: String?] = [
            "id": flag.id,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "reservation_id": flag.reservationID,
            "seat_ref": flag.seatRef,
            "kind": flag.kind.rawValue,
            "display_text": flag.displayText,
        ]
        try? database?.create(named: "pass_seat_flag", values: values)
        try? database?.update(named: "pass_seat_flag", id: flag.id, tenantID: tenantID, values: values)
    }

    private func refreshPassState() {
        guard let serviceSyncState else {
            return
        }
        passState = servicePassState(syncState: serviceSyncState, seatFlags: passSeatFlags)
    }

    private func refreshStoreSummary(_ state: ServiceSyncState) {
        let summary = storeServiceSummary(
            restaurantID: restaurantID,
            restaurantName: "鮨 はやし",
            serviceDate: service.date,
            syncState: state
        )
        if let index = storeSummaries.firstIndex(where: { $0.id == summary.id }) {
            storeSummaries[index] = summary
        } else {
            storeSummaries.append(summary)
        }
    }

    private func persistServiceSyncEvent(_ event: ServiceSyncEvent) {
        let values: [String: String?] = [
            "id": event.id,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "type": event.kind.rawValue,
            "payload": serviceSyncPayload(event),
            "occurred_at": event.occurredAt,
            "source": event.source.rawValue,
        ]
        try? database?.create(named: "service_event", values: values)
        try? database?.update(named: "service_event", id: event.id, tenantID: tenantID, values: values)
    }

    private func serviceSyncPayload(_ event: ServiceSyncEvent) -> String {
        let reservation = event.reservationID ?? ""
        let offline = event.offlineSequence.map(String.init) ?? ""
        return "{\"covers\":\(max(0, event.covers)),\"reservation_id\":\"\(reservation)\",\"offline_sequence\":\"\(offline)\"}"
    }

    private func persistCloseRecord(_ record: CloseTaskRecord) {
        try? database?.create(.wasteLog, values: [
            "id": "waste-close-\(record.task)-\(wasteSequence)",
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "prep_task_id": record.task,
            "covers": String(service.omakaseCovers),
            "planned_qty": numberString(record.plannedQty),
            "made_qty": numberString(record.madeQty),
            "leftover_qty": numberString(record.leftoverQty),
            "waste_reason": record.wasteReason.rawValue,
            "carryover_to_next": record.carryoverToNext ? "1" : "0",
            "unit": record.unit,
            "recorded_by": "local-ipad",
        ])
    }

    private func persistCarryover(_ carryover: CarryoverItem, sequence: Int) {
        let carryoverID = "carryover-\(carryover.task)-close-\(sequence)"
        let values: [String: String?] = [
            "id": carryoverID,
            "tenant_id": tenantID,
            "from_service_day_id": service.id,
            "to_service_day_id": nil,
            "prep_task_id": carryover.task,
            "qty": numberString(carryover.qty),
            "unit": carryover.unit,
            "expire_at": "\(service.date)T23:59:00Z",
            "status": "available",
        ]
        try? database?.create(named: "carryover", values: values)
        try? database?.update(named: "carryover", id: carryoverID, tenantID: tenantID, values: values)
    }

    private func persistReservationDiff(_ diff: ReservationDiffSummary, kind: String) {
        let changed = diff.changedReservationIDs.joined(separator: ",")
        persistEvent(
            type: "reservation.diffed",
            payload: "{\"kind\":\"\(kind)\",\"added_covers\":\(diff.addedCovers),\"cancelled_covers\":\(diff.cancelledCovers),\"changed\":\"\(changed)\"}"
        )
    }

    private func persistPrepLabel(_ label: PrepLabel) {
        let values: [String: String?] = [
            "id": label.id,
            "tenant_id": tenantID,
            "task_instance_id": label.taskInstanceID,
            "printed_at": label.printedAt,
            "made_qty": numberString(label.madeQty),
            "expire_at": label.expireAt,
            "qr_token": label.qrToken,
            "status": label.status.rawValue,
            "remaining_qty": label.remainingQty.map(numberString),
            "storage_unit_id": label.storageUnitID,
        ]
        try? database?.create(named: "label", values: values)
        try? database?.update(named: "label", id: label.id, tenantID: tenantID, values: values)
    }

    private func persistLabelScanResult(_ result: LabelScanResult, scanKind: String) {
        latestPrepLabel = result.label
        persistPrepLabel(result.label)
        if let larderItem = result.larderItem {
            upsertLarderItem(larderItem)
        }
        if let wasteRecord = result.wasteRecord {
            persistLabelWasteRecord(wasteRecord, labelID: result.label.id)
        }
        persistEvent(
            type: "label.scanned",
            payload: "{\"label_id\":\"\(result.label.id)\",\"kind\":\"\(scanKind)\",\"status\":\"\(result.label.status.rawValue)\"}"
        )
    }

    private func upsertLarderItem(_ item: PrepLarderItem) {
        if let index = larderItems.firstIndex(where: { $0.id == item.id }) {
            larderItems[index] = item
        } else {
            larderItems.append(item)
        }
        let values: [String: String?] = [
            "id": item.id,
            "tenant_id": tenantID,
            "label_id": item.labelID,
            "prep_task_id": item.prepTaskID,
            "qty": numberString(item.qty),
            "unit": item.unit,
            "expire_at": item.expireAt,
            "status": item.status.rawValue,
        ]
        try? database?.create(named: "larder_item", values: values)
        try? database?.update(named: "larder_item", id: item.id, tenantID: tenantID, values: values)
    }

    private func persistLabelCarryover(_ item: PrepLarderItem) {
        let carryoverID = "carryover-\(item.prepTaskID)-\(item.labelID)"
        let values: [String: String?] = [
            "id": carryoverID,
            "tenant_id": tenantID,
            "from_service_day_id": service.id,
            "to_service_day_id": nil,
            "prep_task_id": item.prepTaskID,
            "qty": numberString(item.qty),
            "unit": item.unit,
            "expire_at": item.expireAt,
            "status": "available",
        ]
        try? database?.create(named: "carryover", values: values)
        try? database?.update(named: "carryover", id: carryoverID, tenantID: tenantID, values: values)
    }

    private func persistLabelWasteRecord(_ record: CloseTaskRecord, labelID: String) {
        wasteSequence += 1
        try? database?.create(.wasteLog, values: [
            "id": "waste-\(labelID)-\(wasteSequence)",
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "prep_task_id": record.task,
            "covers": String(service.omakaseCovers),
            "planned_qty": numberString(record.plannedQty),
            "made_qty": numberString(record.madeQty),
            "leftover_qty": numberString(record.leftoverQty),
            "waste_reason": record.wasteReason.rawValue,
            "carryover_to_next": "0",
            "unit": record.unit,
            "recorded_by": "label-qr",
        ])
    }

    private func persistCatalogSeed() {
        try? database?.create(.restaurant, values: [
            "id": restaurantID,
            "tenant_id": tenantID,
            "name": "鮨 はやし",
            "seats": "14",
        ])
        try? database?.create(.section, values: [
            "id": sectionOwnerID,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "name": "親方",
            "sort": "0",
        ])
        try? database?.create(.section, values: [
            "id": sectionGardeID,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "name": "ガルド",
            "sort": "1",
        ])
        try? database?.create(.courseTemplate, values: [
            "id": catalog.id,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "name": catalog.courseName,
        ])
        for dish in catalog.dishes {
            persistDish(dish)
            for component in dish.components {
                persistComponent(component, dishID: dish.id)
                for task in component.tasks {
                    persistTask(task, componentID: component.id)
                }
            }
        }
    }

    private func persistDish(_ dish: CatalogDish) {
        try? database?.create(.dish, values: [
            "id": dish.id,
            "tenant_id": tenantID,
            "course_template_id": catalog.id,
            "name": dish.name,
            "sort": String(dish.sort),
        ])
    }

    private func persistComponent(_ component: CatalogComponent, dishID: String) {
        try? database?.create(.component, values: [
            "id": component.id,
            "tenant_id": tenantID,
            "dish_id": dishID,
            "name": component.name,
            "sort": String(component.sort),
        ])
    }

    private func persistTask(_ task: CatalogPrepTask, componentID: String) {
        try? database?.create(.prepTask, values: taskValues(task, componentID: componentID))
    }

    private func persistTaskUpdate(_ task: CatalogPrepTask) {
        try? database?.update(.prepTask, id: task.id, tenantID: tenantID, values: [
            "name": task.name,
            "coeff_per_cover": numberString(task.coeffPerCover),
            "yield": numberString(task.yieldPercent / 100),
            "duration_min": String(task.durationMin),
            "lead_min_before_open": String(task.leadMinBeforeOpen),
            "section_id": sectionID(for: task.sectionName),
        ])
    }

    private func persistServicePeriods() {
        for period in service.periods {
            let values: [String: String?] = [
                "id": period.id,
                "tenant_id": tenantID,
                "restaurant_id": restaurantID,
                "label": period.label,
                "service_period": period.servicePeriod,
                "open_time": period.openTime,
                "sort": String(period.sort),
            ]
            try? database?.create(named: "service_period", values: values)
            try? database?.update(named: "service_period", id: period.id, tenantID: tenantID, values: values)
        }
    }

    private func persistTaskInstances() {
        for dish in catalog.dishes {
            for component in dish.components {
                for task in component.tasks {
                    let quantity = calcQty(task.engineTask, covers: service.omakaseCovers)
                    let scheduled = schedule(task: task.engineTask, serviceDate: service.date, t0: service.openTime, closedDates: [])
                    let id = "instance-\(task.id)"
                    let status = completed.contains(task.id.replacingOccurrences(of: "task-", with: "")) ? "done" : "not_started"
                    let values: [String: String?] = [
                        "id": id,
                        "tenant_id": tenantID,
                        "service_day_id": service.id,
                        "prep_task_id": task.id,
                        "status": status,
                        "assignee_section_id": sectionID(for: task.sectionName),
                        "prep_day": scheduled.prepDate ?? service.date,
                        "planned_qty": numberString(quantity.total),
                        "unit": task.unit,
                        "start_at": scheduled.start,
                        "finish_at": scheduled.finish,
                        "sort": String(task.sort),
                    ]
                    try? database?.create(.taskInstance, values: values)
                    try? database?.update(.taskInstance, id: id, tenantID: tenantID, values: values)
                }
            }
        }
    }

    private func persistDayrailItems() {
        for item in dayrailItems {
            let values: [String: String?] = [
                "id": item.id,
                "tenant_id": tenantID,
                "service_day_id": service.id,
                "kind": item.kind.rawValue,
                "ref_id": item.refID,
                "title": item.title,
                "prep_day_offset": String(item.prepDayOffset),
                "start_at": item.start,
                "finish_at": item.finish,
                "status": statusDBValue(item.status),
                "sort": String(item.sort),
            ]
            try? database?.create(named: "dayrail_item", values: values)
            try? database?.update(named: "dayrail_item", id: item.id, tenantID: tenantID, values: values)
        }
    }

    private func persistSubrecipeAggregate(_ aggregate: AggregatedQuantity, status: TaskStatus) {
        let aggregateID = "aggregate-\(aggregate.task)-\(service.id)"
        let aggregateValues: [String: String?] = [
            "id": aggregateID,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "prep_task_id": aggregate.task,
            "total_covers": String(aggregate.totalCovers),
            "total_qty": numberString(aggregate.quantity.total),
            "unit": aggregate.quantity.unit,
            "sources": aggregate.sources.joined(separator: ","),
            "status": statusDBValue(status),
        ]
        try? database?.create(named: "subrecipe_aggregate", values: aggregateValues)
        try? database?.update(named: "subrecipe_aggregate", id: aggregateID, tenantID: tenantID, values: aggregateValues)

        for source in aggregate.sources {
            let parts = source.split(separator: ":")
            guard let course = parts.first, let covers = parts.last else {
                continue
            }
            let referenceID = "aggregate-ref-\(aggregate.task)-\(course)-\(service.id)"
            let referenceValues: [String: String?] = [
                "id": referenceID,
                "tenant_id": tenantID,
                "aggregate_id": aggregateID,
                "course_key": String(course),
                "covers": String(covers),
                "rollup_status": statusDBValue(status),
            ]
            try? database?.create(named: "subrecipe_reference", values: referenceValues)
            try? database?.update(named: "subrecipe_reference", id: referenceID, tenantID: tenantID, values: referenceValues)
        }
    }

    private func taskValues(_ task: CatalogPrepTask, componentID: String) -> [String: String?] {
        [
            "id": task.id,
            "tenant_id": tenantID,
            "component_id": componentID,
            "name": task.name,
            "scale_mode": "per_cover",
            "coeff_per_cover": numberString(task.coeffPerCover),
            "yield": numberString(task.yieldPercent / 100),
            "round_step": numberString(task.roundStep),
            "unit": task.unit,
            "duration_min": String(task.durationMin),
            "lead_min_before_open": String(task.leadMinBeforeOpen),
            "shelf_life_days": String(task.shelfLifeDays),
            "section_id": sectionOwnerID,
            "sort": String(task.sort),
        ]
    }

    private func numberString(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 3)))
    }

    private func sectionID(for sectionName: String) -> String {
        sectionName == "ガルド" ? sectionGardeID : sectionOwnerID
    }

    private func statusDBValue(_ status: TaskStatus) -> String {
        switch status {
        case .notStarted:
            "not_started"
        case .inProgress:
            "in_progress"
        case .done:
            "done"
        }
    }
}

private extension ServiceDaySettings {
    var periodCode: String {
        periods.first(where: { $0.id == selectedPeriodID })?.servicePeriod ?? "dinner"
    }
}
