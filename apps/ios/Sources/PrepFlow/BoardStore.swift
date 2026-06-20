// swiftlint:disable file_length
import Engine
import PrepFlowData
import SwiftUI

struct CloseNextDayPrepReservation: Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
    var timing: String
    var isReserved: Bool
}

struct LabelPrinterDevice: Identifiable, Equatable {
    var id: String
    var name: String
    var detail: String
    var connection: String
    var paperSize: String
    var status: String
    var isDefault: Bool
}

struct LabelPrintJob: Equatable {
    var labelID: String
    var destination: String
    var paperSize: String
    var outputPath: String?
    var status: String
    var createdAt: String
}

struct ConnectorDiffReviewItem: Identifiable, Equatable {
    var id: String
    var sourceLabel: String
    var partyName: String
    var visitTime: String
    var covers: Int
    var course: String
    var status: String
    var prepNote: String
    var diffLabel: String
    var state: String
}

struct TodayPrepImpactItem: Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
    var sourceLabel: String
    var actionLabel: String
    var targetStepID: String
    var checkTitle: String
    var checkDetail: String
    var isUrgent: Bool
}

struct LineGateStatus: Equatable {
    var completedCount: Int
    var totalCount: Int
    var unresolvedImpactCount: Int
    var recheckCount: Int
    var labelReprintRequired: Bool
    var lastAction: String

    var canOpen: Bool {
        completedCount == totalCount
            && unresolvedImpactCount == 0
            && recheckCount == 0
            && !labelReprintRequired
    }

    var blockingCount: Int {
        (totalCount - completedCount) + unresolvedImpactCount + recheckCount + (labelReprintRequired ? 1 : 0)
    }
}

@MainActor
// swiftlint:disable:next type_body_length
final class BoardStore: ObservableObject {
    @Published private(set) var completed: Set<String>
    @Published private(set) var catalog: CatalogTemplate
    @Published private(set) var service: ServiceDaySettings
    @Published private(set) var simulation: SimulationSummary
    @Published private(set) var settingsLocked = true
    @Published private(set) var latestExportSummary = "CSV / JSON"
    @Published private(set) var catalogSaveCount = 0
    @Published private(set) var catalogLastSavedAt: String?
    @Published private(set) var catalogBoardPreviewSummary: String?
    @Published private(set) var serviceBoardGenerateCount = 0
    @Published private(set) var serviceBoardGeneratedAt: String?
    @Published private(set) var serviceBoardPreviewSummary: String?
    @Published private(set) var simulationPeriodDays = 14
    @Published private(set) var simulationDateRange = "6/1〜6/14"
    @Published private(set) var simulationAdjustmentCount = 0
    @Published private(set) var simulationLastAdjustmentSummary: String?
    @Published private(set) var simulationAppliedCount = 0
    @Published private(set) var simulationAppliedAt: String?
    @Published private(set) var simulationBoardImpactSummary: String?
    @Published private(set) var etaOverride: ETA?
    @Published private(set) var dayrailItems: [DayrailItem] = []
    @Published private(set) var sharedPrepAggregate: AggregatedQuantity?
    @Published private(set) var closeLoopSummary: CloseLoopSummary?
    @Published private(set) var closeLoopCommitCount = 0
    @Published private(set) var closeLoopLastAction = "締め未記録"
    @Published private(set) var closeGateCompletedAt: String?
    @Published private(set) var closeGateLastAction = "締め表未記録"
    @Published private(set) var closeNextDayPrepReservations = BoardStore.defaultCloseNextDayPrepReservations
    @Published private(set) var reservationDiffSummary: ReservationDiffSummary?
    @Published private(set) var reservationPlanDiff: PlanDiff?
    @Published private(set) var reservationHubDuplicateDecision: String?
    @Published private(set) var reservationHubAssignedCourses: [String: String] = [:]
    @Published private(set) var reservationHubApplyCount = 0
    @Published private(set) var reservationHubAppliedAt: String?
    @Published private(set) var connectorDiffReviewItems: [ConnectorDiffReviewItem] = []
    @Published private(set) var connectorLastSyncSummary = "外部同期は未実行"
    @Published private(set) var connectorReplayCount = 0
    @Published private(set) var latestPrepLabel: PrepLabel?
    @Published private(set) var larderItems: [PrepLarderItem] = []
    @Published private(set) var latestConnectorReservation: NormalizedReservation?
    @Published private(set) var latestDirectBooking: DirectBooking?
    @Published private(set) var serviceSyncState: ServiceSyncState?
    @Published private(set) var servicePacingProposal: PacingProposal?
    @Published private(set) var latestDirectDecision: DirectBookingDecision?
    @Published private(set) var latestWaitlistPromotion: DirectWaitlistPromotion?
    @Published private(set) var latestNoShowSettlement: DirectNoShowSettlement?
    @Published private(set) var specialPrepTasks: [SpecialPrepTask] = []
    @Published private(set) var allergenLabels: [AllergenLabel] = []
    @Published private(set) var guestMessages: [GuestMessage] = []
    @Published private(set) var passSeatFlags: [PassSeatFlag] = []
    @Published private(set) var passState: ServicePassState?
    @Published private(set) var specialPrepLastAction = "特別対応は未生成"
    @Published private(set) var allergenLabelPrintCount = 0
    @Published private(set) var allergenLabelPrintedAt: String?
    @Published private(set) var guestMessageLastAction = "事前確認は未送信"
    @Published private(set) var guestReplyRecheckCount = 0
    @Published private(set) var guestReplyRecheckLastAction = "返信変更なし"
    @Published private(set) var guestReplyRequiresLabelReprint = false
    @Published private(set) var servicePassLastAction = "ホール着信待ち"
    @Published private(set) var storeSummaries: [StoreServiceSummary] = []
    @Published private(set) var larderAlerts: [LarderAlert] = []
    @Published private(set) var larderConsumptionPlan: LarderConsumptionPlan?
    @Published private(set) var latestLarderUseSummary = "FIFO未適用"
    @Published private(set) var fridgeInspectionCompletedAt: String?
    @Published private(set) var fridgeInspectionMissingCount = 0
    @Published private(set) var fridgeTemperatureC = 3
    @Published private(set) var fridgeTemperatureLoggedAt: String?
    @Published private(set) var labelModeEnabled = true
    @Published private(set) var labelPrinterDevices = BoardStore.defaultLabelPrinters
    @Published private(set) var selectedLabelPrinterID = BoardStore.defaultLabelPrinters[0].id
    @Published private(set) var labelPaperSize = "62mm 連続"
    @Published private(set) var labelScanLastAction = "QR未記録"
    @Published private(set) var latestLabelPrintJob: LabelPrintJob?
    @Published private(set) var latestLabelPDFPath: String?
    @Published private(set) var latestQRReturnRoute = "QR未読取"
    @Published private(set) var latestLearningWasteRecords: [WasteRecord] = []
    @Published private(set) var multistoreSummary: StoreServiceSummary?
    @Published private(set) var todayPrepProgress = BoardStore.emptyTodayPrepProgress
    @Published private(set) var lastTodayPrepUndo: TodayPrepUndo?
    @Published private(set) var nowGuidanceTitle = "煮切り仕込み"
    @Published private(set) var nowGuidanceBody = "次の手順を確認してください。"
    @Published private(set) var todayPrepOperators = BoardStore.defaultTodayPrepOperators
    @Published private(set) var selectedTodayPrepOperatorID = BoardStore.defaultTodayPrepOperators[0].id
    @Published private(set) var todayPrepStepOperatorOverrides: [String: String] = [:]
    @Published private(set) var todayPrepCompletedBy: [String: String] = [:]
    @Published private(set) var todayPrepAssistProposal: TodayPrepAssistProposal?
    @Published private(set) var todayPrepAssistAppliedSummary: String?
    @Published private(set) var todayPrepAssistETAAfterApply: ETA?
    @Published private(set) var todayPrepStartedAt: [String: String] = [:]
    @Published private(set) var todayPrepCheckedAt: [String: String] = [:]
    @Published private(set) var todayPrepActuals: [String: TodayPrepActual] = [:]
    @Published private(set) var todayPrepCompletedCheckIDs: Set<String> = []
    @Published private(set) var todayPrepActiveHold: TodayPrepHold?
    @Published private(set) var todayPrepHoldHistory: [TodayPrepHold] = []
    @Published private(set) var todayPrepManualActualMinutes: [String: Int] = [:]
    @Published private(set) var todayPrepCompletionBlockReason = "確認項目待ち"
    @Published private(set) var todayPrepImpactItems: [TodayPrepImpactItem] = []
    @Published private(set) var todayPrepDynamicChecks: [TodayPrepCheck] = []
    @Published private(set) var todayPrepImpactLastAction = "外部変化なし"
    @Published private(set) var todayPrepImpactAppliedCount = 0
    @Published private(set) var lineGateLastAction = "ライン点検待ち"

    var p0VerticalSliceStatus: String {
        if latestExportSummary != Self.defaultExportSummary {
            return "settings_exported"
        }
        if completed.isSuperset(of: Self.focusStepIDs) {
            return "checkoff_rolled_up"
        }
        if serviceBoardGenerateCount > 0 {
            return "board_generated"
        }
        if simulationAdjustmentCount > 0 {
            return "simulation_ready"
        }
        return "activation_pending"
    }

    private let database: PrepFlowDatabase?
    private let tenantID: String
    private let restaurantID = "restaurant-hayashi"
    private let sectionOwnerID = "section-oyakata"
    private let sectionShariID = "section-shari"
    private let sectionGardeID = "section-garde"
    private let serviceCoverID = "cover-omakase"
    private let storageColdID = "storage-cold-2"
    private let tableCheckConnectorID = "connector-tablecheck-mock"
    private let maximumServiceCovers = 200
    private let maximumReservationCovers = 60
    private let maximumReservationNoteLength = 160
    private var eventSequence = 0
    private var catalogSequence = 0
    private var wasteSequence = 0
    private var serviceSyncEvents: [ServiceSyncEvent] = []
    private var todayPrepAssistRequestedAt = "17:45"
    private var connectorPendingEvents: [String: SourceReservationEvent] = [:]
    private var appliedLarderUseIntentKeys: Set<String> = []
    private var reservationHubAppliedSignature: String?
    private var closeBatchSignature: String?
    private var serviceBoardGeneratedSignature: String?
    private var catalogSavedSignature: String?
    private var catalogPreviewedSignature: String?
    private var simulationAppliedSignature: String?
    private var simulationAdjustedSignature: String?
    private var servicePeriodSelectedSignature: String?
    private var etaRecordedSignature: String?
    private var dayrailPlannedSignature: String?
    private var subrecipeAggregatedSignature: String?
    private var nikiriWasteRecordedSignatures: Set<String> = []
    private var nikiriCarryoverRecordedSignatures: Set<String> = []
    private var fridgeTemperatureRecordedSignatures: Set<String> = []
    private var nikiriLabelIssuedSignatures: Set<String> = []
    private var labelPrintTestedSignatures: Set<String> = []
    private var labelPDFExportedSignatures: Set<String> = []
    private var labelQROpenedSignatures: Set<String> = []
    private var labelOutputBlockedSignatures: Set<String> = []
    private var labelScanBlockedSignatures: Set<String> = []
    private var todayPrepAssistAppliedSignature: String?
    private var todayPrepAppliedImpactIDs: Set<String> = []
    private var specialPrepCompletedIDs: Set<String> = []
    private var specialPrepSkippedIDs: Set<String> = []

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
        refreshTodayPrepProgress()
        persistCatalogSeed()
        restoreCatalogState()
        restoreServiceState()
        persistServiceSeed()
        persistLabelModeSeed()
        restoreSettingsState()
        restoreCatalogBoardState()
        restoreSimulationState()
        restoreBoardGenerationState()
        restoreDailyOpsState()
        restoreCloseOpsState()
        restoreReservationHubState()
        restoreConnectorReviewState()
        restoreLabelOpsState()
        restoreGuestOpsState()
        restoreDirectServiceOpsState()
        restoreTodayPrepAssignments()
        restoreTodayPrepOperationalState()
        syncNikiriRollup()
        refreshTodayPrepProgress()
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
            persistEvent(
                type: "catalog.task_select_blocked",
                payload: "{\"task_id\":\"\(id)\",\"reason\":\"missing\"}"
            )
            return
        }
        catalog.selectedTaskID = id
        persistSelectedCatalogTask()
    }

    func addDish() {
        catalogSequence += 1
        let dish = CatalogDish(id: "dish-custom-\(catalogSequence)", name: "新しい料理 \(catalogSequence)", components: [], sort: catalog.dishes.count)
        catalog.dishes.append(dish)
        persistDish(dish)
    }

    func addComponent() {
        guard let dishIndex = selectedDishIndex else {
            persistEvent(
                type: "catalog.component_add_blocked",
                payload: "{\"reason\":\"dish_missing\"}"
            )
            return
        }
        catalogSequence += 1
        let component = CatalogComponent(id: "component-custom-\(catalogSequence)", name: "構成要素 \(catalogSequence)", tasks: [], sort: catalog.dishes[dishIndex].components.count)
        catalog.dishes[dishIndex].components.append(component)
        persistComponent(component, dishID: catalog.dishes[dishIndex].id)
    }

    func addTask() {
        guard let selectedPath else {
            persistEvent(
                type: "catalog.task_add_blocked",
                payload: "{\"selected_task_id\":\"\(catalog.selectedTaskID)\",\"reason\":\"selection_missing\"}"
            )
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
        persistSelectedCatalogTask()
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
            persistEvent(
                type: "catalog.task_update_blocked",
                payload: "{\"selected_task_id\":\"\(catalog.selectedTaskID)\",\"reason\":\"selection_missing\"}"
            )
            return
        }

        if let reason = invalidCatalogTaskUpdateReason(
            coeffPerCover: coeffPerCover,
            yieldPercent: yieldPercent,
            durationMin: durationMin,
            leadMinBeforeOpen: leadMinBeforeOpen
        ) {
            persistEvent(
                type: "catalog.task_update_blocked",
                payload: "{\"selected_task_id\":\"\(catalog.selectedTaskID)\",\"reason\":\"\(reason)\"}"
            )
            return
        }
        if let reason = invalidCatalogTaskTextUpdateReason(name: name, sectionName: sectionName) {
            persistEvent(
                type: "catalog.task_update_blocked",
                payload: "{\"selected_task_id\":\"\(catalog.selectedTaskID)\",\"reason\":\"\(reason)\"}"
            )
            return
        }

        var task = catalog.dishes[selectedPath.dish].components[selectedPath.component].tasks[selectedPath.task]
        task.name = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? task.name
        task.coeffPerCover = coeffPerCover ?? task.coeffPerCover
        task.yieldPercent = yieldPercent ?? task.yieldPercent
        task.durationMin = durationMin ?? task.durationMin
        task.leadMinBeforeOpen = leadMinBeforeOpen ?? task.leadMinBeforeOpen
        task.sectionName = sectionName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? task.sectionName
        task.instruction = instruction ?? task.instruction
        catalog.dishes[selectedPath.dish].components[selectedPath.component].tasks[selectedPath.task] = task
        persistTaskUpdate(task)
    }

    func updateOmakaseCovers(_ covers: Int) {
        let resolvedCovers = resolvedServiceCovers(covers)
        persistClampedServiceCoversIfNeeded(course: "omakase", requestedCovers: covers, resolvedCovers: resolvedCovers)
        service.omakaseCovers = resolvedCovers
        persistServiceCover()
    }

    func updateOtherCovers(_ covers: Int) {
        let resolvedCovers = resolvedServiceCovers(covers)
        persistClampedServiceCoversIfNeeded(course: "other", requestedCovers: covers, resolvedCovers: resolvedCovers)
        service.otherCovers = resolvedCovers
        persistServiceOtherCovers()
        persistServiceCover()
    }

    func updateOpenTime(_ openTime: String) {
        guard isValidOpenTime(openTime) else {
            persistEvent(
                type: "service_time.update_blocked",
                payload: "{\"requested_open_time\":\"\(openTime)\",\"reason\":\"invalid_hhmm\",\"current_open_time\":\"\(service.openTime)\"}"
            )
            return
        }
        service.openTime = openTime
        refreshServicePeriodSelectionGuard()
        persistServiceDayUpdate()
    }

    func selectServicePeriod(_ id: String) {
        guard let period = service.periods.first(where: { $0.id == id }) else {
            persistEvent(
                type: "service_period.select_blocked",
                payload: "{\"service_period_id\":\"\(id)\",\"reason\":\"missing\"}"
            )
            return
        }

        let signature = servicePeriodSignature(period)
        guard signature != servicePeriodSelectedSignature else {
            persistEvent(
                type: "service_period.select_skipped",
                payload: "{\"service_period_id\":\"\(period.id)\",\"reason\":\"duplicate_signature\"}"
            )
            return
        }

        service.selectedPeriodID = period.id
        service.period = period.label
        service.openTime = period.openTime
        persistServicePeriods()
        persistServiceDayUpdate()
        servicePeriodSelectedSignature = signature
        persistEvent(type: "service_period.selected", payload: "{\"service_period_id\":\"\(period.id)\",\"open_time\":\"\(period.openTime)\"}")
    }

    func assignNikiri(toSectionName sectionName: String) {
        selectTask("task-nikiri")
        guard selectedCatalogTask.sectionName != sectionName else {
            persistEvent(
                type: "task.assignment_skipped",
                payload: "{\"task_id\":\"task-nikiri\",\"reason\":\"unchanged\",\"section\":\"\(sectionName)\"}"
            )
            return
        }
        updateSelectedTask(sectionName: sectionName)
        persistTaskInstances()
        persistEvent(type: "task.assigned", payload: "{\"task_id\":\"task-nikiri\",\"section\":\"\(sectionName)\"}")
    }

    func recordETAInput(now: String, remainingDurationsMin: [Int]) {
        if let reason = invalidETAInputReason(now: now, remainingDurationsMin: remainingDurationsMin) {
            persistEvent(
                type: "eta.record_blocked",
                payload: "{\"now\":\"\(now)\",\"reason\":\"\(reason)\",\"remaining_count\":\(remainingDurationsMin.count)}"
            )
            return
        }

        let signature = etaInputSignature(now: now, remainingDurationsMin: remainingDurationsMin)
        guard signature != etaRecordedSignature else {
            persistEvent(
                type: "eta.record_skipped",
                payload: "{\"now\":\"\(now)\",\"reason\":\"duplicate_signature\"}"
            )
            return
        }

        etaOverride = etaProjection(now: now, t0: service.openTime, remainingDurationsMin: remainingDurationsMin)
        etaRecordedSignature = signature
        persistEvent(
            type: "eta.recorded",
            payload: "{\"landing\":\"\(etaOverride?.landing ?? "")\",\"shortfall_min\":\(etaOverride?.shortfallMin ?? 0)}"
        )
        persistETAState(now: now, remainingDurationsMin: remainingDurationsMin, signature: signature)
    }

    func addManualReservation() {
        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
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
        recordManualReservationDiff(
            previous: previous,
            previousCovers: previousCovers,
            kind: "manual_create",
            sourceLabel: "手入力予約"
        )
    }

    func editReservation(_ id: String) {
        guard let index = service.reservations.firstIndex(where: { $0.id == id }) else {
            persistEvent(
                type: "reservation.update_blocked",
                payload: "{\"reservation_id\":\"\(id)\",\"reason\":\"missing\"}"
            )
            return
        }

        updateReservation(
            id,
            covers: service.reservations[index].covers + 1,
            note: "編集済み・\(service.reservations[index].covers + 1)名"
        )
    }

    func updateReservation(_ id: String, covers: Int, note: String? = nil) {
        guard let index = service.reservations.firstIndex(where: { $0.id == id }) else {
            persistEvent(
                type: "reservation.update_blocked",
                payload: "{\"reservation_id\":\"\(id)\",\"reason\":\"missing\",\"covers\":\(resolvedReservationCovers(covers))}"
            )
            return
        }

        let resolvedCovers = resolvedReservationCovers(covers)
        persistClampedReservationCoversIfNeeded(reservationID: id, requestedCovers: covers, resolvedCovers: resolvedCovers)
        let resolvedNote = note.map(resolvedReservationNote)
        persistNormalizedReservationNoteIfNeeded(reservationID: id, requestedNote: note, resolvedNote: resolvedNote)
        let isUnchanged = service.reservations[index].covers == resolvedCovers
            && (resolvedNote == nil || resolvedNote == service.reservations[index].note)
        if isUnchanged {
            persistEvent(
                type: "reservation.update_skipped",
                payload: "{\"reservation_id\":\"\(id)\",\"reason\":\"unchanged\",\"covers\":\(resolvedCovers)}"
            )
            return
        }

        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
        service.reservations[index].covers = resolvedCovers
        service.reservations[index].note = resolvedNote ?? service.reservations[index].note
        recalculateCoversFromReservations()
        try? database?.update(.reservation, id: id, tenantID: tenantID, values: [
            "covers": String(service.reservations[index].covers),
            "party_name": service.reservations[index].partyName,
            "note": service.reservations[index].note,
        ])
        persistServiceCover()
        persistEvent(type: "reservation.updated", payload: "{\"reservation_id\":\"\(id)\",\"covers\":\(service.reservations[index].covers)}")
        recordManualReservationDiff(
            previous: previous,
            previousCovers: previousCovers,
            kind: "manual_update",
            sourceLabel: "手入力予約"
        )
    }

    func deleteReservation(_ id: String) {
        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
        guard let index = service.reservations.firstIndex(where: { $0.id == id }) else {
            persistEvent(
                type: "reservation.delete_blocked",
                payload: "{\"reservation_id\":\"\(id)\",\"reason\":\"missing\"}"
            )
            return
        }

        let reservation = service.reservations.remove(at: index)
        recalculateCoversFromReservations()
        try? database?.softDelete(.reservation, id: reservation.id, tenantID: tenantID)
        persistServiceCover()
        persistEvent(type: "reservation.deleted", payload: "{\"reservation_id\":\"\(reservation.id)\",\"covers\":\(reservation.covers)}")
        recordManualReservationDiff(
            previous: previous,
            previousCovers: previousCovers,
            kind: "manual_delete",
            sourceLabel: "手入力予約"
        )
    }

    func generateBoardFromService() {
        let signature = serviceBoardSignature()
        guard signature != serviceBoardGeneratedSignature else {
            persistEvent(
                type: "board.generate_skipped",
                payload: "{\"service_day_id\":\"\(service.id)\",\"reason\":\"duplicate_signature\",\"covers\":\(service.totalCovers)}"
            )
            return
        }

        persistServiceDayUpdate()
        persistServiceCover()
        persistTaskInstances()
        serviceBoardGenerateCount += 1
        serviceBoardGeneratedAt = "\(service.date)T\(service.openTime):00Z"
        serviceBoardPreviewSummary = "\(service.totalCovers)名 / \(Int(nikiriQuantity.total))\(nikiriQuantity.unit) / \(nikiriSchedule.start)着手"
        serviceBoardGeneratedSignature = signature
        persistBoardGenerationState()
        persistEvent(type: "board.generated", payload: "{\"service_day_id\":\"\(service.id)\",\"covers\":\(service.totalCovers)}")
    }

    func prepareDayrail() {
        let signature = dayrailPlanSignature()
        guard signature != dayrailPlannedSignature else {
            persistEvent(
                type: "dayrail.plan_skipped",
                payload: "{\"service_day_id\":\"\(service.id)\",\"reason\":\"duplicate_signature\",\"items\":\(dayrailItems.count)}"
            )
            return
        }

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
        dayrailPlannedSignature = signature
        persistEvent(type: "dayrail.planned", payload: "{\"service_day_id\":\"\(service.id)\",\"items\":\(dayrailItems.count)}")
    }

    @discardableResult
    func aggregateSharedPrep() -> AggregatedQuantity {
        let signature = subrecipeAggregateSignature()
        if signature == subrecipeAggregatedSignature, let sharedPrepAggregate {
            persistEvent(
                type: "subrecipe.aggregate_skipped",
                payload: "{\"task_id\":\"\(sharedPrepAggregate.task)\",\"reason\":\"duplicate_signature\"}"
            )
            return sharedPrepAggregate
        }

        var references: [(course: String, covers: Int)] = [("omakase", service.omakaseCovers)]
        if service.otherCovers > 0 {
            references.append(("walkin", service.otherCovers))
        }
        let aggregate = aggregateSubrecipes(nikiriTask, references: references)
        sharedPrepAggregate = aggregate
        persistSubrecipeAggregate(aggregate, status: nikiriRollupStatus)
        subrecipeAggregatedSignature = signature
        persistEvent(
            type: "subrecipe.aggregated",
            payload: "{\"task_id\":\"\(aggregate.task)\",\"total_covers\":\(aggregate.totalCovers),\"total_qty\":\(numberString(aggregate.quantity.total))}"
        )
        return aggregate
    }

    func completeSharedPrepAggregate(now: String = "17:25") {
        let aggregate = sharedPrepAggregate ?? aggregateSharedPrep()
        persistSubrecipeAggregate(aggregate, status: nikiriRollupStatus)
        guard todayPrepProgress.isComplete else {
            handleTodayPrepAggregateBoardTap(sourceID: aggregate.task, sourceKind: "subrecipe", now: now)
            persistSubrecipeAggregate(aggregate, status: nikiriRollupStatus)
            persistEvent(
                type: "subrecipe.rollup_completion_blocked",
                payload: "{\"task_id\":\"\(aggregate.task)\",\"next_step_id\":\"\(todayPrepProgress.nextStepID ?? "")\"}"
            )
            return
        }
        persistEvent(type: "subrecipe.rollup_completed", payload: "{\"task_id\":\"\(aggregate.task)\",\"status\":\"\(nikiriRollupStatus.rawValue)\"}")
    }

    func recordNikiriWaste(madeQty: Double = 240, leftoverQty: Double = 40) {
        guard isValidWasteRecord(madeQty: madeQty, leftoverQty: leftoverQty) else {
            persistEvent(
                type: "waste.record_blocked",
                payload: "{\"task_id\":\"task-nikiri\",\"reason\":\"invalid_qty\",\"made_qty\":\(jsonNumberOrNull(madeQty)),\"leftover_qty\":\(jsonNumberOrNull(leftoverQty))}"
            )
            return
        }
        let signature = nikiriWasteSignature(madeQty: madeQty, leftoverQty: leftoverQty)
        guard !nikiriWasteRecordedSignatures.contains(signature) else {
            persistEvent(
                type: "waste.record_skipped",
                payload: "{\"task_id\":\"task-nikiri\",\"reason\":\"duplicate_signature\",\"leftover_qty\":\(numberString(leftoverQty))}"
            )
            return
        }
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
        nikiriWasteRecordedSignatures.insert(signature)
        persistEvent(type: "waste.recorded", payload: "{\"task_id\":\"task-nikiri\",\"leftover_qty\":\(numberString(leftoverQty))}")
    }

    func recordNikiriCarryover(qty: Double = 40) {
        guard isValidPositiveQuantity(qty) else {
            persistEvent(
                type: "carryover.create_blocked",
                payload: "{\"task_id\":\"task-nikiri\",\"reason\":\"invalid_qty\",\"qty\":\(jsonNumberOrNull(qty))}"
            )
            return
        }
        let signature = nikiriCarryoverSignature(qty: qty)
        guard !nikiriCarryoverRecordedSignatures.contains(signature) else {
            persistEvent(
                type: "carryover.create_skipped",
                payload: "{\"task_id\":\"task-nikiri\",\"reason\":\"duplicate_signature\",\"qty\":\(numberString(qty))}"
            )
            return
        }
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
        nikiriCarryoverRecordedSignatures.insert(signature)
        persistEvent(type: "carryover.created", payload: "{\"task_id\":\"task-nikiri\",\"qty\":\(numberString(qty))}")
    }

    func applySimulationCoefficients() {
        let signature = simulationApplySignature()
        guard signature != simulationAppliedSignature else {
            persistEvent(
                type: "simulation.apply_skipped",
                payload: "{\"task_id\":\"task-nikiri\",\"reason\":\"duplicate_signature\",\"period_days\":\(simulationPeriodDays)}"
            )
            return
        }

        selectTask("task-nikiri")
        updateSelectedTask(coeffPerCover: 12, yieldPercent: selectedCatalogTask.yieldPercent)
        generateBoardFromService()
        simulationAppliedCount += 1
        simulationAppliedAt = "\(service.date)T15:20:00Z"
        simulationBoardImpactSummary = serviceBoardPreviewSummary ?? "\(service.totalCovers)名 / 煮切り \(Int(nikiriQuantity.total))\(nikiriQuantity.unit) / \(nikiriSchedule.start)着手"
        simulationAppliedSignature = simulationApplySignature()
        persistSimulationState()
        persistEvent(
            type: "simulation.applied",
            payload: "{"
                + "\"task_id\":\"task-nikiri\","
                + "\"coeff_per_cover\":12,"
                + "\"period_days\":\(simulationPeriodDays),"
                + "\"board_summary\":\"\(simulationBoardImpactSummary ?? "")\""
                + "}"
        )
    }

    func applySimulationAdjustment() {
        let signature = simulationAdjustmentSignature()
        guard signature != simulationAdjustedSignature else {
            persistEvent(
                type: "simulation.adjust_skipped",
                payload: "{\"reason\":\"duplicate_signature\",\"period_days\":\(simulationPeriodDays),\"adjustment_count\":\(simulationAdjustmentCount)}"
            )
            return
        }

        simulationAdjustmentCount += 1
        simulation.hitRatePercent = min(99, simulation.hitRatePercent + 1)
        simulation.stockoutRisks = max(0, simulation.stockoutRisks - 1)
        simulation.items = simulation.items.map { item in
            guard item.outcome == .risk else {
                return item
            }
            var adjusted = item
            adjusted.recommended += 1
            adjusted.deltaLabel = "＋\(Int(adjusted.recommended - adjusted.actual))客"
            return adjusted
        }
        simulationLastAdjustmentSummary = "安全係数 +10% / 的中率 \(simulation.hitRatePercent)% / リスク \(simulation.stockoutRisks)件"
        persistSimulationState()
        persistEvent(
            type: "simulation.adjusted",
            payload: "{"
                + "\"hit_rate_percent\":\(simulation.hitRatePercent),"
                + "\"stockout_risks\":\(simulation.stockoutRisks),"
                + "\"adjustment_count\":\(simulationAdjustmentCount)"
                + "}"
        )
        simulationAdjustedSignature = signature
    }

    func changeSimulationPeriod() {
        switch simulationPeriodDays {
        case 14:
            simulationPeriodDays = 30
            simulationDateRange = "5/16〜6/14"
            simulation.lossSavingYen += 4000
        case 30:
            simulationPeriodDays = 60
            simulationDateRange = "4/16〜6/14"
            simulation.lossSavingYen += 6000
            simulation.hitRatePercent = max(simulation.hitRatePercent, 90)
        default:
            simulationPeriodDays = 14
            simulationDateRange = "6/1〜6/14"
            simulation.lossSavingYen = SimulationSummary.seed.lossSavingYen
            simulation.hitRatePercent = max(simulation.hitRatePercent, SimulationSummary.seed.hitRatePercent)
        }
        simulationLastAdjustmentSummary = "期間 \(simulationPeriodDays)日 / \(simulationDateRange) / 削減見込み \(simulation.lossSavingText)"
        persistSimulationState()
        persistEvent(type: "simulation.period_changed", payload: "{\"period_days\":\(simulationPeriodDays),\"date_range\":\"\(simulationDateRange)\"}")
    }

    func saveCatalogForBoard() {
        let signature = catalogSaveSignature()
        guard signature != catalogSavedSignature else {
            persistEvent(
                type: "catalog.save_skipped",
                payload: "{\"course_template_id\":\"\(catalog.id)\",\"reason\":\"duplicate_signature\"}"
            )
            return
        }

        persistCatalogSeed()
        persistTaskInstances()
        catalogSaveCount += 1
        catalogLastSavedAt = "\(service.date)T15:08:00Z"
        catalogBoardPreviewSummary = catalogBoardPreviewText()
        catalogSavedSignature = signature
        persistCatalogBoardState()
        persistEvent(type: "catalog.saved", payload: "{\"course_template_id\":\"\(catalog.id)\"}")
    }

    func previewCatalogOnBoard() {
        let signature = catalogPreviewSignature()
        guard signature != catalogPreviewedSignature else {
            persistEvent(
                type: "catalog.preview_skipped",
                payload: "{\"course_template_id\":\"\(catalog.id)\",\"reason\":\"duplicate_signature\"}"
            )
            return
        }

        saveCatalogForBoard()
        generateBoardFromService()
        catalogPreviewedSignature = signature
        persistCatalogBoardState()
        persistEvent(
            type: "catalog.previewed_on_board",
            payload: "{\"course_template_id\":\"\(catalog.id)\",\"summary\":\"\(catalogBoardPreviewSummary ?? "")\"}"
        )
    }

    func toggleSettingsLock() {
        settingsLocked.toggle()
        persistSetting(id: "setting-lock", key: "settings.lock", value: settingsLocked ? "locked" : "unlocked")
        persistEvent(type: "settings.lock_toggled", payload: "{\"locked\":\(settingsLocked)}")
    }

    func exportSnapshotJSON(authReadinessLabel: String = "SQLite 起動可") -> String {
        latestExportSummary = "JSON / \(authReadinessLabel)"
        persistSetting(id: "setting-data-export-last", key: "data.export.last", value: latestExportSummary)
        let payload = [
            "auth_readiness": authReadinessLabel,
            "p0_flow_status": p0VerticalSliceStatus,
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

    func toggleLabelMode() {
        labelModeEnabled.toggle()
        persistSetting(id: "setting-label-mode", key: "label.mode", value: labelModeEnabled ? "enabled" : "disabled")
        persistEvent(type: "label_mode.toggled", payload: "{\"enabled\":\(labelModeEnabled)}")
    }

    func selectLabelPrinter(_ id: String) {
        guard labelPrinterDevices.contains(where: { $0.id == id }) else {
            persistEvent(
                type: "label_printer.default_select_blocked",
                payload: "{\"printer_id\":\"\(id)\",\"reason\":\"missing\"}"
            )
            return
        }
        guard selectedLabelPrinterID != id else {
            persistEvent(
                type: "label_printer.default_select_skipped",
                payload: "{\"printer_id\":\"\(id)\",\"reason\":\"already_default\"}"
            )
            return
        }
        selectedLabelPrinterID = id
        for index in labelPrinterDevices.indices {
            labelPrinterDevices[index].isDefault = labelPrinterDevices[index].id == id
            persistPrinter(labelPrinterDevices[index])
        }
        persistEvent(type: "label_printer.default_selected", payload: "{\"printer_id\":\"\(id)\"}")
    }

    func selectLabelPaperSize(_ paperSize: String) {
        guard labelPaperSize != paperSize else {
            persistEvent(
                type: "label_printer.paper_select_skipped",
                payload: "{\"paper_size\":\"\(paperSize)\",\"reason\":\"already_selected\"}"
            )
            return
        }
        labelPaperSize = paperSize
        if let index = labelPrinterDevices.firstIndex(where: { $0.id == selectedLabelPrinterID }) {
            labelPrinterDevices[index].paperSize = paperSize
            persistPrinter(labelPrinterDevices[index])
        }
        persistEvent(type: "label_printer.paper_selected", payload: "{\"paper_size\":\"\(paperSize)\"}")
    }

    @discardableResult
    func testLabelPrint(now: String = "2026-06-12T16:22:00Z") -> LabelPrintJob {
        guard let label = latestPrepLabel else {
            if let skippedJob = skippedBlockedLabelPrintJob(kind: "label_print", now: now) {
                return skippedJob
            }
            let requestedLabel = issueNikiriPrepLabel(printedAt: now)
            let job = LabelPrintJob(
                labelID: requestedLabel.id,
                destination: "ラベル未発行",
                paperSize: labelPaperSize,
                outputPath: nil,
                status: "blocked",
                createdAt: now
            )
            latestLabelPrintJob = job
            labelOutputBlockedSignatures.insert(labelOutputBlockedSignature(kind: "label_print", labelID: requestedLabel.id, now: now))
            persistLabelOpsState()
            persistEvent(type: "label_print.blocked", payload: "{\"label_id\":\"\(requestedLabel.id)\",\"reason\":\"label_missing\"}")
            return job
        }
        let printer = selectedLabelPrinter
        let signature = labelPrintTestSignature(labelID: label.id, printer: printer, now: now)
        let duplicateTest = labelPrintTestedSignatures.contains(signature)
            && latestLabelPrintJob?.labelID == label.id
        if duplicateTest, let latestLabelPrintJob {
            persistEvent(
                type: "label_print.test_skipped",
                payload: "{\"label_id\":\"\(label.id)\",\"printer_id\":\"\(printer.id)\",\"reason\":\"duplicate_signature\"}"
            )
            return latestLabelPrintJob
        }
        let job = LabelPrintJob(
            labelID: label.id,
            destination: printer.status == "connected" ? printer.name : "PDF / A4",
            paperSize: printer.status == "connected" ? printer.paperSize : "PDF / A4",
            outputPath: printer.status == "connected" ? nil : labelPDFPath(labelID: label.id),
            status: printer.status == "connected" ? "printed" : "pdf_ready",
            createdAt: now
        )
        latestLabelPrintJob = job
        latestLabelPDFPath = job.outputPath
        persistPrinterTest(printerID: printer.id, testedAt: now)
        labelPrintTestedSignatures.insert(signature)
        persistLabelOpsState()
        persistEvent(
            type: "label_print.tested",
            payload: "{\"label_id\":\"\(label.id)\",\"destination\":\"\(job.destination)\",\"status\":\"\(job.status)\"}"
        )
        return job
    }

    @discardableResult
    func exportLatestLabelPDF(now: String = "2026-06-12T16:24:00Z") -> LabelPrintJob {
        guard let label = latestPrepLabel else {
            if let skippedJob = skippedBlockedLabelPrintJob(kind: "label_pdf", now: now) {
                return skippedJob
            }
            let requestedLabel = issueNikiriPrepLabel(printedAt: now)
            let job = LabelPrintJob(
                labelID: requestedLabel.id,
                destination: "PDF / A4",
                paperSize: "PDF / A4",
                outputPath: nil,
                status: "blocked",
                createdAt: now
            )
            latestLabelPrintJob = job
            labelOutputBlockedSignatures.insert(labelOutputBlockedSignature(kind: "label_pdf", labelID: requestedLabel.id, now: now))
            persistLabelOpsState()
            persistEvent(type: "label_pdf.blocked", payload: "{\"label_id\":\"\(requestedLabel.id)\",\"reason\":\"label_missing\"}")
            return job
        }
        let path = labelPDFPath(labelID: label.id)
        let signature = labelPDFExportSignature(labelID: label.id, path: path)
        let duplicateExport = labelPDFExportedSignatures.contains(signature)
            && latestLabelPrintJob?.labelID == label.id
            && latestLabelPrintJob?.outputPath == path
        if duplicateExport, let latestLabelPrintJob {
            persistEvent(
                type: "label_pdf.export_skipped",
                payload: "{\"label_id\":\"\(label.id)\",\"reason\":\"duplicate_signature\",\"path\":\"\(path)\"}"
            )
            return latestLabelPrintJob
        }
        let job = LabelPrintJob(
            labelID: label.id,
            destination: "PDF / A4",
            paperSize: "PDF / A4",
            outputPath: path,
            status: "pdf_ready",
            createdAt: now
        )
        latestLabelPrintJob = job
        latestLabelPDFPath = path
        labelPDFExportedSignatures.insert(signature)
        persistLabelOpsState()
        persistEvent(type: "label_pdf.exported", payload: "{\"label_id\":\"\(label.id)\",\"path\":\"\(path)\"}")
        return job
    }

    @discardableResult
    func openLatestLabelQR() -> String {
        guard let label = latestPrepLabel else {
            let previewLabel = makeNikiriPrepLabel(madeQty: nil, printedAt: "2026-06-11T16:20:00Z", storageUnitID: nil)
            let signature = labelOutputBlockedSignature(kind: "label_qr", labelID: previewLabel.id, now: "route")
            if labelOutputBlockedSignatures.contains(signature) {
                latestQRReturnRoute = "ラベル未発行 → 仕込み完了後にQR"
                persistEvent(
                    type: "label_qr.blocked_skipped",
                    payload: "{\"label_id\":\"\(previewLabel.id)\",\"reason\":\"duplicate_missing_label\"}"
                )
                return latestQRReturnRoute
            }
            let requestedLabel = issueNikiriPrepLabel()
            latestQRReturnRoute = "ラベル未発行 → 仕込み完了後にQR"
            labelOutputBlockedSignatures.insert(signature)
            persistLabelOpsState()
            persistEvent(type: "label_qr.blocked", payload: "{\"label_id\":\"\(requestedLabel.id)\",\"reason\":\"label_missing\"}")
            return latestQRReturnRoute
        }
        let signature = labelQROpenSignature(labelID: label.id)
        if labelQROpenedSignatures.contains(signature) {
            latestQRReturnRoute = "QR → \(label.id) → 残量/使い切り/廃棄"
            persistEvent(
                type: "label_qr.open_skipped",
                payload: "{\"label_id\":\"\(label.id)\",\"reason\":\"already_opened\"}"
            )
            return latestQRReturnRoute
        }
        latestQRReturnRoute = "QR → \(label.id) → 残量/使い切り/廃棄"
        labelQROpenedSignatures.insert(signature)
        persistLabelOpsState()
        persistEvent(type: "label_qr.opened", payload: "{\"label_id\":\"\(label.id)\",\"route\":\"label_ops\"}")
        return latestQRReturnRoute
    }

    func toggle(_ id: String) {
        if Self.focusStepIDs.contains(id) {
            toggleTodayPrepStep(id)
            return
        }

        if id == "nikiri" {
            handleTodayPrepAggregateBoardTap(sourceID: id, sourceKind: "direct")
            return
        }

        if completed.contains(id) {
            completed.remove(id)
        } else {
            completed.insert(id)
        }
        syncNikiriRollup()
        refreshTodayPrepProgress()
        persistOfflineEvent(taskID: id)
    }

    func toggleDishBoardTask(_ id: String) {
        let taskID = Self.boardTaskID(for: id)
        if taskID == "nikiri" {
            handleTodayPrepAggregateBoardTap(sourceID: id, sourceKind: "dish")
            persistEvent(type: "board.dish_task_toggled", payload: "{\"task_id\":\"\(taskID)\",\"source_id\":\"\(id)\",\"routed\":\"today_prep\"}")
            return
        }
        if Self.focusStepIDs.contains(taskID) {
            handleTodayPrepBoardStepTap(taskID)
            persistEvent(type: "board.dish_task_toggled", payload: "{\"task_id\":\"\(taskID)\",\"source_id\":\"\(id)\",\"routed\":\"today_prep\"}")
            return
        }
        toggle(taskID)
        persistEvent(type: "board.dish_task_toggled", payload: "{\"task_id\":\"\(taskID)\",\"source_id\":\"\(id)\"}")
    }

    func toggleStaffBoardTask(_ id: String) {
        let taskID = Self.boardTaskID(for: id)
        if taskID == "line-check" {
            handleLineCheckBoardTap(sourceID: id)
            persistEvent(type: "board.staff_task_toggled", payload: "{\"task_id\":\"\(taskID)\",\"source_id\":\"\(id)\",\"routed\":\"line_gate\"}")
            return
        }
        if taskID == "nikiri" {
            handleTodayPrepAggregateBoardTap(sourceID: id, sourceKind: "staff")
            persistEvent(type: "board.staff_task_toggled", payload: "{\"task_id\":\"\(taskID)\",\"source_id\":\"\(id)\",\"routed\":\"today_prep\"}")
            return
        }
        if Self.focusStepIDs.contains(taskID) {
            handleTodayPrepBoardStepTap(taskID)
            persistEvent(type: "board.staff_task_toggled", payload: "{\"task_id\":\"\(taskID)\",\"source_id\":\"\(id)\",\"routed\":\"today_prep\"}")
            return
        }
        toggle(taskID)
        persistEvent(type: "board.staff_task_toggled", payload: "{\"task_id\":\"\(taskID)\",\"source_id\":\"\(id)\"}")
    }

    func handleTodayPrepAggregateBoardTap(sourceID: String, sourceKind: String, now: String = "17:25") {
        guard let nextStepID = todayPrepProgress.nextStepID else {
            todayPrepCompletionBlockReason = "煮切り仕込みは完了済み"
            persistEvent(
                type: "today_prep.aggregate_tap_ignored",
                payload: "{\"source_id\":\"\(sourceID)\",\"source_kind\":\"\(sourceKind)\",\"reason\":\"complete\"}"
            )
            return
        }

        handleTodayPrepBoardStepTap(nextStepID, now: now)
        persistEvent(
            type: "today_prep.aggregate_step_routed",
            payload: "{\"source_id\":\"\(sourceID)\",\"source_kind\":\"\(sourceKind)\",\"step_id\":\"\(nextStepID)\"}"
        )
    }

    func handleLineCheckBoardTap(sourceID: String) {
        if completed.contains("line-check") {
            completed.remove("line-check")
            lineGateLastAction = "ライン点検を取り消し"
            persistOfflineEvent(taskID: "line-check")
            persistTodayPrepOperationalState()
            persistEvent(type: "line_gate.check_reopened", payload: "{\"source_id\":\"\(sourceID)\"}")
            return
        }

        let status = lineGateStatus
        guard status.canOpen else {
            lineGateLastAction = lineGateBlockDetail(status)
            todayPrepCompletionBlockReason = "ライン点検不可: \(lineGateLastAction)"
            persistTodayPrepOperationalState()
            persistEvent(
                type: "line_gate.check_blocked",
                payload: "{"
                    + "\"source_id\":\"\(sourceID)\","
                    + "\"remaining\":\(status.totalCount - status.completedCount),"
                    + "\"impacts\":\(status.unresolvedImpactCount),"
                    + "\"rechecks\":\(status.recheckCount),"
                    + "\"label_reprint\":\(status.labelReprintRequired)"
                    + "}"
            )
            return
        }

        completed.insert("line-check")
        lineGateLastAction = "ライン点検完了"
        persistOfflineEvent(taskID: "line-check")
        persistTodayPrepOperationalState()
        persistEvent(
            type: "line_gate.check_completed",
            payload: "{\"source_id\":\"\(sourceID)\",\"completed\":\(status.completedCount),\"total\":\(status.totalCount)}"
        )
    }

    func handleTodayPrepBoardStepTap(_ id: String, now: String = "17:25") {
        guard Self.focusStepIDs.contains(id) else {
            toggle(id)
            return
        }

        if completed.contains(id) {
            toggleTodayPrepStep(id, now: now)
            persistEvent(type: "today_prep.board_step_reopened", payload: "{\"step_id\":\"\(id)\"}")
            return
        }

        guard id == todayPrepProgress.nextStepID else {
            todayPrepCompletionBlockReason = "次は \(todayPrepProgress.nextStepTitle ?? "現在工程")"
            persistEvent(
                type: "today_prep.board_step_blocked",
                payload: "{\"step_id\":\"\(id)\",\"next_step_id\":\"\(todayPrepProgress.nextStepID ?? "")\"}"
            )
            return
        }

        if todayPrepStartedAt[id] == nil {
            startNextTodayStep(now: now)
            todayPrepCompletionBlockReason = "着手中。確認項目を終えると完了できます"
            persistEvent(type: "today_prep.board_step_started", payload: "{\"step_id\":\"\(id)\"}")
            return
        }

        completeNextTodayStep(now: now)
        persistEvent(type: "today_prep.board_step_completed_attempted", payload: "{\"step_id\":\"\(id)\"}")
    }

    func selectTodayPrepOperator(_ id: String) {
        guard todayPrepOperators.contains(where: { $0.id == id }) else {
            persistEvent(
                type: "today_prep.operator_select_blocked",
                payload: "{\"operator_id\":\"\(id)\",\"reason\":\"missing\"}"
            )
            return
        }
        guard selectedTodayPrepOperatorID != id else {
            persistEvent(
                type: "today_prep.operator_select_skipped",
                payload: "{\"operator_id\":\"\(id)\",\"reason\":\"already_selected\"}"
            )
            return
        }
        selectedTodayPrepOperatorID = id
        let stepID = todayPrepProgress.nextStepID
        if let stepID {
            todayPrepStepOperatorOverrides[stepID] = id
            persistTodayPrepAssignments()
            persistTaskInstances()
        }
        persistTodayPrepOperationalState()
        persistEvent(
            type: "today_prep.operator_selected",
            payload: "{\"operator_id\":\"\(id)\",\"step_id\":\"\(stepID ?? "")\"}"
        )
    }

    func startNextTodayStep(now: String = "17:25") {
        guard let nextStepID = todayPrepProgress.nextStepID else {
            todayPrepCompletionBlockReason = "着手対象なし"
            persistEvent(
                type: "today_prep.step_start_blocked",
                payload: "{\"reason\":\"complete\"}"
            )
            return
        }
        guard isValidOpenTime(now) else {
            todayPrepCompletionBlockReason = "着手時刻を確認"
            persistEvent(
                type: "today_prep.step_start_blocked",
                payload: "{\"step_id\":\"\(nextStepID)\",\"reason\":\"invalid_time\",\"started_at\":\"\(now)\"}"
            )
            return
        }
        guard todayPrepStartedAt[nextStepID] == nil else {
            todayPrepCompletionBlockReason = "着手済み \(todayPrepStartedAt[nextStepID] ?? "")"
            persistEvent(
                type: "today_prep.step_start_ignored",
                payload: "{\"step_id\":\"\(nextStepID)\",\"started_at\":\"\(todayPrepStartedAt[nextStepID] ?? "")\"}"
            )
            return
        }
        todayPrepStartedAt[nextStepID] = now
        persistTodayPrepOperationalState()
        persistEvent(type: "today_prep.step_started", payload: "{\"step_id\":\"\(nextStepID)\",\"started_at\":\"\(now)\"}")
    }

    func toggleTodayPrepCheck(_ id: String) {
        guard let check = todayPrepCheck(id) else {
            persistEvent(
                type: "today_prep.check_toggle_blocked",
                payload: "{\"check_id\":\"\(id)\",\"reason\":\"missing\"}"
            )
            return
        }

        if todayPrepCompletedCheckIDs.contains(id) {
            todayPrepCompletedCheckIDs.remove(id)
        } else {
            todayPrepCompletedCheckIDs.insert(id)
        }
        persistEvent(
            type: "today_prep.check_toggled",
            payload: "{\"check_id\":\"\(id)\",\"step_id\":\"\(check.stepID)\",\"done\":\(todayPrepCompletedCheckIDs.contains(id))}"
        )
        todayPrepCompletionBlockReason = currentTodayPrepReadiness.canComplete ? "確認項目OK" : "確認項目待ち"
        persistTodayPrepOperationalState()
    }

    func completeCurrentTodayPrepChecks() {
        guard !currentTodayPrepChecks.isEmpty else {
            todayPrepCompletionBlockReason = "確認項目なし"
            persistEvent(
                type: "today_prep.checks_completed_batch_blocked",
                payload: "{\"step_id\":\"\(todayPrepProgress.nextStepID ?? "done")\",\"reason\":\"empty\"}"
            )
            return
        }
        let ids = currentTodayPrepChecks.map(\.id)
        if ids.allSatisfy(todayPrepCompletedCheckIDs.contains) {
            todayPrepCompletionBlockReason = "\(ids.count)件は確認済み"
            persistEvent(
                type: "today_prep.checks_completed_batch_skipped",
                payload: "{\"step_id\":\"\(todayPrepProgress.nextStepID ?? "")\",\"reason\":\"already_completed\",\"count\":\(ids.count)}"
            )
            return
        }
        for id in ids {
            todayPrepCompletedCheckIDs.insert(id)
        }
        todayPrepCompletionBlockReason = "\(ids.count)件を一括確認"
        persistTodayPrepOperationalState()
        persistEvent(
            type: "today_prep.checks_completed_batch",
            payload: "{\"step_id\":\"\(todayPrepProgress.nextStepID ?? "")\",\"count\":\(ids.count)}"
        )
    }

    func pauseTodayPrep(reason: String, now: String = "17:31") {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty, isValidOpenTime(now) else {
            todayPrepCompletionBlockReason = "停止理由と時刻を確認"
            persistEvent(
                type: "today_prep.pause_blocked",
                payload: "{\"reason\":\"invalid_input\",\"hold_reason\":\"\(reason)\",\"paused_at\":\"\(now)\"}"
            )
            return
        }
        if let hold = todayPrepActiveHold {
            todayPrepCompletionBlockReason = "\(hold.reason)で停止中"
            persistEvent(
                type: "today_prep.pause_skipped",
                payload: "{\"step_id\":\"\(hold.stepID)\",\"reason\":\"already_paused\",\"hold_reason\":\"\(hold.reason)\"}"
            )
            return
        }
        guard let stepID = todayPrepProgress.nextStepID else {
            todayPrepCompletionBlockReason = "停止対象なし"
            persistEvent(
                type: "today_prep.pause_blocked",
                payload: "{\"reason\":\"complete\"}"
            )
            return
        }
        if let startedAt = todayPrepStartedAt[stepID], isHHMM(now, before: startedAt) {
            todayPrepCompletionBlockReason = "停止時刻が着手前です"
            persistEvent(
                type: "today_prep.pause_blocked",
                payload: "{\"step_id\":\"\(stepID)\",\"reason\":\"before_start\",\"started_at\":\"\(startedAt)\",\"paused_at\":\"\(now)\"}"
            )
            return
        }
        if todayPrepStartedAt[stepID] == nil {
            todayPrepStartedAt[stepID] = now
        }
        let hold = Engine.todayPrepHold(stepID: stepID, reason: trimmedReason, pausedAt: now)
        todayPrepActiveHold = hold
        todayPrepHoldHistory.append(hold)
        persistTodayPrepOperationalState()
        persistEvent(
            type: "today_prep.paused",
            payload: "{\"step_id\":\"\(stepID)\",\"reason\":\"\(trimmedReason)\",\"paused_at\":\"\(now)\"}"
        )
    }

    func resumeTodayPrep(now: String = "17:36") {
        guard isValidOpenTime(now) else {
            todayPrepCompletionBlockReason = "再開時刻を確認"
            persistEvent(
                type: "today_prep.resume_blocked",
                payload: "{\"reason\":\"invalid_time\",\"resumed_at\":\"\(now)\"}"
            )
            return
        }
        guard let hold = todayPrepActiveHold else {
            todayPrepCompletionBlockReason = "停止中の作業なし"
            persistEvent(
                type: "today_prep.resume_skipped",
                payload: "{\"reason\":\"not_paused\"}"
            )
            return
        }
        guard !isHHMM(now, before: hold.pausedAt) else {
            todayPrepCompletionBlockReason = "再開時刻が停止前です"
            persistEvent(
                type: "today_prep.resume_blocked",
                payload: "{\"step_id\":\"\(hold.stepID)\",\"reason\":\"before_pause\",\"paused_at\":\"\(hold.pausedAt)\",\"resumed_at\":\"\(now)\"}"
            )
            return
        }
        let resumed = Engine.todayPrepResume(hold, resumedAt: now)
        todayPrepActiveHold = nil
        if let index = todayPrepHoldHistory.lastIndex(where: { $0.id == hold.id }) {
            todayPrepHoldHistory[index] = resumed
        }
        persistTodayPrepOperationalState()
        persistEvent(
            type: "today_prep.resumed",
            payload: "{\"step_id\":\"\(resumed.stepID)\",\"reason\":\"\(resumed.reason)\",\"resumed_at\":\"\(now)\"}"
        )
    }

    func adjustTodayPrepActualMinutes(stepID: String, delta: Int) {
        guard let actual = todayPrepActuals[stepID] else {
            persistEvent(
                type: "today_prep.actual_adjust_blocked",
                payload: "{\"step_id\":\"\(stepID)\",\"reason\":\"missing_actual\",\"delta\":\(delta)}"
            )
            return
        }
        guard isValidTodayPrepActualDelta(delta) else {
            persistEvent(
                type: "today_prep.actual_adjust_blocked",
                payload: "{\"step_id\":\"\(stepID)\",\"reason\":\"invalid_delta\",\"delta\":\(delta)}"
            )
            return
        }
        let currentActual = todayPrepManualActualMinutes[stepID] ?? actual.actualMinutes
        let added = currentActual.addingReportingOverflow(delta)
        guard !added.overflow else {
            persistEvent(
                type: "today_prep.actual_adjust_blocked",
                payload: "{\"step_id\":\"\(stepID)\",\"reason\":\"overflow\",\"delta\":\(delta)}"
            )
            return
        }
        let nextActual = max(0, added.partialValue)
        todayPrepManualActualMinutes[stepID] = nextActual
        todayPrepActuals[stepID] = Engine.todayPrepActualOverride(
            taskID: stepID,
            plannedMinutes: actual.plannedMinutes,
            actualMinutes: nextActual,
            startedAt: actual.startedAt,
            checkedAt: actual.checkedAt
        )
        persistTodayPrepOperationalState()
        persistEvent(
            type: "today_prep.actual_adjusted",
            payload: "{\"step_id\":\"\(stepID)\",\"actual_min\":\(nextActual),\"delta\":\(delta)}"
        )
    }

    @discardableResult
    func markAllNowDone() -> LineGateStatus {
        let previous = completed
        for stepID in Self.focusStepIDs where !completed.contains(stepID) {
            completeTodayPrepChecks(for: stepID)
            recordTodayPrepCompletion(stepID, checkedAt: "2026-06-17T17:25:00Z")
        }
        syncNikiriRollup()
        refreshTodayPrepProgress()
        lastTodayPrepUndo = Engine.todayPrepUndo(action: "now_batch_done", previousCompletedIDs: previous, nextCompletedIDs: completed)
        persistTaskInstances()
        persistTodayPrepOperationalState()
        persistOfflineEvent(taskID: "nikiri")
        persistEvent(
            type: "today_prep.batch_completed",
            payload: "{\"completed\":\(todayPrepProgress.completedCount),\"remaining_min\":\(todayPrepProgress.remainingMinutes)}"
        )
        let status = lineGateStatus
        if status.canOpen {
            lineGateLastAction = "開店ゲートOK"
            persistEvent(
                type: "line_gate.ready",
                payload: "{\"completed\":\(status.completedCount),\"total\":\(status.totalCount)}"
            )
        } else {
            lineGateLastAction = lineGateBlockDetail(status)
            persistEvent(
                type: "line_gate.blocked",
                payload: "{"
                    + "\"remaining\":\(status.totalCount - status.completedCount),"
                    + "\"impacts\":\(status.unresolvedImpactCount),"
                    + "\"rechecks\":\(status.recheckCount),"
                    + "\"label_reprint\":\(status.labelReprintRequired)"
                    + "}"
            )
        }
        return status
    }

    @discardableResult
    func requestLineGateFromBoard() -> LineGateStatus {
        if let hold = todayPrepActiveHold {
            lineGateLastAction = "\(hold.reason)で停止中"
            todayPrepCompletionBlockReason = "ライン点検不可: \(lineGateLastAction)"
            persistTodayPrepOperationalState()
            persistEvent(
                type: "line_gate.board_request_blocked",
                payload: "{"
                    + "\"reason\":\"hold\","
                    + "\"step_id\":\"\(hold.stepID)\","
                    + "\"hold_reason\":\"\(hold.reason)\""
                    + "}"
            )
            return lineGateStatus
        }

        let status = lineGateStatus
        guard status.canOpen else {
            lineGateLastAction = lineGateBlockDetail(status)
            todayPrepCompletionBlockReason = "ライン点検不可: \(lineGateLastAction)"
            persistTodayPrepOperationalState()
            persistEvent(
                type: "line_gate.board_request_blocked",
                payload: "{"
                    + "\"reason\":\"blocked\","
                    + "\"remaining\":\(status.totalCount - status.completedCount),"
                    + "\"impacts\":\(status.unresolvedImpactCount),"
                    + "\"rechecks\":\(status.recheckCount),"
                    + "\"label_reprint\":\(status.labelReprintRequired)"
                    + "}"
            )
            return lineGateStatus
        }

        if lineGateLastAction == "開店ゲートOK" {
            persistTodayPrepOperationalState()
            persistEvent(
                type: "line_gate.ready_skipped",
                payload: "{\"source\":\"board_bottom\",\"reason\":\"already_ready\",\"completed\":\(status.completedCount),\"total\":\(status.totalCount)}"
            )
            return lineGateStatus
        }
        lineGateLastAction = "開店ゲートOK"
        persistTodayPrepOperationalState()
        persistEvent(
            type: "line_gate.ready",
            payload: "{\"source\":\"board_bottom\",\"completed\":\(status.completedCount),\"total\":\(status.totalCount)}"
        )
        return lineGateStatus
    }

    func toggleTodayPrepStep(_ id: String, now: String = "17:25") {
        guard Self.focusStepIDs.contains(id) else {
            return
        }
        guard isValidOpenTime(now) else {
            todayPrepCompletionBlockReason = "操作時刻を確認"
            persistEvent(
                type: "today_prep.step_toggle_blocked",
                payload: "{\"step_id\":\"\(id)\",\"reason\":\"invalid_time\",\"now\":\"\(now)\"}"
            )
            return
        }

        let previous = completed
        if completed.contains(id) {
            completed.remove(id)
            todayPrepCompletedBy[id] = nil
            todayPrepCheckedAt[id] = nil
            todayPrepActuals[id] = nil
            clearTodayPrepOperationalState(for: id)
            if id == "nikiri" {
                todayPrepCompletedBy["nikiri"] = nil
                todayPrepCheckedAt["nikiri"] = nil
            }
        } else {
            completeTodayPrepChecks(for: id)
            recordTodayPrepCompletion(id, checkedAt: now)
        }
        syncNikiriRollup()
        refreshTodayPrepProgress(now: now)
        lastTodayPrepUndo = Engine.todayPrepUndo(action: "toggle-\(id)", previousCompletedIDs: previous, nextCompletedIDs: completed)
        persistTaskInstances()
        persistTodayPrepOperationalState()
        persistOfflineEvent(taskID: id)
        persistEvent(
            type: "today_prep.step_toggled",
            payload: "{"
                + "\"step_id\":\"\(id)\","
                + "\"completed_by\":\"\(todayPrepCompletedBy[id] ?? "")\","
                + "\"actual_min\":\(todayPrepActuals[id]?.actualMinutes ?? 0),"
                + "\"variance_min\":\(todayPrepActuals[id]?.varianceMinutes ?? 0),"
                + "\"next_step_id\":\"\(todayPrepProgress.nextStepID ?? "done")\","
                + "\"remaining_min\":\(todayPrepProgress.remainingMinutes),"
                + "\"eta\":\"\(todayPrepProgress.eta.landing)\""
                + "}"
        )
    }

    func completeNextTodayStep(now: String = "17:25") {
        guard let nextStepID = todayPrepProgress.nextStepID else {
            todayPrepCompletionBlockReason = "完了対象なし"
            persistEvent(
                type: "today_prep.completion_skipped",
                payload: "{\"reason\":\"complete\"}"
            )
            return
        }
        if let hold = todayPrepActiveHold, hold.stepID == nextStepID {
            todayPrepCompletionBlockReason = "\(hold.reason)で停止中。再開してから完了"
            persistEvent(
                type: "today_prep.completion_blocked",
                payload: "{\"step_id\":\"\(nextStepID)\",\"hold_reason\":\"\(hold.reason)\"}"
            )
            return
        }
        let checks = currentTodayPrepChecks
        let readiness = Engine.todayPrepReadiness(checks: checks, completedCheckIDs: todayPrepCompletedCheckIDs)
        guard readiness.canComplete else {
            todayPrepCompletionBlockReason = "未完: \(readiness.remainingTitles.joined(separator: " / "))"
            persistEvent(
                type: "today_prep.completion_blocked",
                payload: "{\"step_id\":\"\(nextStepID)\",\"remaining_checks\":\(readiness.remainingTitles.count)}"
            )
            return
        }
        guard isValidOpenTime(now) else {
            todayPrepCompletionBlockReason = "完了時刻を確認"
            persistEvent(
                type: "today_prep.completion_blocked",
                payload: "{\"step_id\":\"\(nextStepID)\",\"reason\":\"invalid_time\",\"checked_at\":\"\(now)\"}"
            )
            return
        }
        if let startedAt = todayPrepStartedAt[nextStepID], isHHMM(now, before: startedAt) {
            todayPrepCompletionBlockReason = "完了時刻が着手前です"
            persistEvent(
                type: "today_prep.completion_blocked",
                payload: "{\"step_id\":\"\(nextStepID)\",\"reason\":\"before_start\",\"started_at\":\"\(startedAt)\",\"checked_at\":\"\(now)\"}"
            )
            return
        }
        todayPrepCompletionBlockReason = "確認項目OK"
        toggleTodayPrepStep(nextStepID, now: now)
    }

    func undoLastTodayPrepAction(now: String = "17:25") {
        guard let undo = lastTodayPrepUndo else {
            todayPrepCompletionBlockReason = "取り消す操作なし"
            persistEvent(
                type: "today_prep.undo_skipped",
                payload: "{\"reason\":\"empty\"}"
            )
            return
        }
        completed = Set(undo.previousCompletedIDs)
        todayPrepCompletedBy = todayPrepCompletedBy.filter { completed.contains($0.key) }
        todayPrepCheckedAt = todayPrepCheckedAt.filter { completed.contains($0.key) }
        todayPrepActuals = todayPrepActuals.filter { completed.contains($0.key) }
        todayPrepManualActualMinutes = todayPrepManualActualMinutes.filter { completed.contains($0.key) }
        if let hold = todayPrepActiveHold, !completed.contains(hold.stepID) {
            todayPrepActiveHold = nil
        }
        todayPrepCompletedCheckIDs = todayPrepCompletedCheckIDs.filter { checkID in
            guard let check = Self.todayPrepChecks.first(where: { $0.id == checkID }) else {
                return false
            }
            return completed.contains(check.stepID)
        }
        syncNikiriRollup()
        refreshTodayPrepProgress(now: now)
        lastTodayPrepUndo = nil
        persistTaskInstances()
        persistTodayPrepOperationalState()
        persistEvent(
            type: "today_prep.undo_applied",
            payload: "{\"action\":\"\(undo.action)\",\"remaining_min\":\(todayPrepProgress.remainingMinutes)}"
        )
    }

    func startNowGuidance() {
        let title = todayPrepProgress.nextStepTitle ?? "ライン点検へ進む"
        nowGuidanceTitle = title
        nowGuidanceBody = guidanceBody(for: todayPrepProgress.nextStepID)
        persistEvent(
            type: "today_prep.guidance_opened",
            payload: "{\"step_id\":\"\(todayPrepProgress.nextStepID ?? "done")\",\"remaining_min\":\(todayPrepProgress.remainingMinutes)}"
        )
    }

    func requestTodayPrepAssist(now: String = "17:55") {
        guard isValidOpenTime(now) else {
            persistEvent(
                type: "today_prep.assist_request_blocked",
                payload: "{\"reason\":\"invalid_time\",\"requested_at\":\"\(now)\"}"
            )
            return
        }
        todayPrepAssistRequestedAt = now
        refreshTodayPrepProgress(now: now)
        todayPrepAssistProposal = Engine.todayPrepAssistProposal(progress: todayPrepProgress, operators: todayPrepOperators)
        todayPrepAssistAppliedSummary = nil
        todayPrepAssistETAAfterApply = nil
        todayPrepAssistAppliedSignature = nil
        persistEvent(
            type: "today_prep.assist_requested",
            payload: "{\"shortfall_min\":\(todayPrepProgress.eta.shortfallMin),\"proposal_id\":\"\(todayPrepAssistProposal?.id ?? "")\"}"
        )
        persistTodayPrepOperationalState()
    }

    func applyTodayPrepAssist() {
        guard let proposal = todayPrepAssistProposal else {
            persistEvent(
                type: "today_prep.assist_apply_blocked",
                payload: "{\"reason\":\"missing_proposal\"}"
            )
            return
        }
        let signature = todayPrepAssistApplySignature(proposal)
        guard todayPrepAssistAppliedSignature != signature else {
            persistEvent(
                type: "today_prep.assist_apply_skipped",
                payload: "{\"proposal_id\":\"\(proposal.id)\",\"reason\":\"duplicate_signature\"}"
            )
            return
        }
        if let operatorID = proposal.suggestedOperatorID {
            selectedTodayPrepOperatorID = operatorID
            if let stepID = todayPrepProgress.nextStepID {
                todayPrepStepOperatorOverrides[stepID] = operatorID
                persistTodayPrepAssignments()
                persistTaskInstances()
            }
        }
        let adjustedRemaining = max(0, todayPrepProgress.remainingMinutes - proposal.savesMinutes)
        todayPrepAssistETAAfterApply = etaProjection(
            now: todayPrepAssistRequestedAt,
            t0: service.openTime,
            remainingDurationsMin: [adjustedRemaining]
        )
        let operatorName = proposal.suggestedOperatorName ?? "手空き担当"
        let landing = todayPrepAssistETAAfterApply?.landing ?? todayPrepProgress.eta.landing
        todayPrepAssistAppliedSummary = "\(operatorName)へ割当 / −\(proposal.savesMinutes)分 / 着地 \(landing)"
        todayPrepAssistAppliedSignature = signature
        persistTodayPrepOperationalState()
        persistEvent(
            type: "today_prep.assist_applied",
            payload: "{"
                + "\"proposal_id\":\"\(proposal.id)\","
                + "\"step_id\":\"\(todayPrepProgress.nextStepID ?? "")\","
                + "\"operator\":\"\(proposal.suggestedOperatorName ?? "")\","
                + "\"saves_min\":\(proposal.savesMinutes),"
                + "\"landing\":\"\(todayPrepAssistETAAfterApply?.landing ?? "")\","
                + "\"shortfall_min\":\(todayPrepAssistETAAfterApply?.shortfallMin ?? 0)"
                + "}"
        )
    }

    func applyTodayPrepImpact(_ id: String) {
        guard let item = todayPrepImpactItems.first(where: { $0.id == id }) else {
            if todayPrepAppliedImpactIDs.contains(id) {
                persistEvent(
                    type: "today_prep.impact_apply_skipped",
                    payload: "{\"impact_id\":\"\(id)\",\"reason\":\"already_applied\"}"
                )
            } else {
                persistEvent(
                    type: "today_prep.impact_apply_blocked",
                    payload: "{\"impact_id\":\"\(id)\",\"reason\":\"missing\"}"
                )
            }
            return
        }
        let check = TodayPrepCheck(
            id: "check-\(item.id)",
            stepID: item.targetStepID,
            title: item.checkTitle,
            detail: item.checkDetail
        )
        upsertTodayPrepDynamicCheck(check)
        if completed.contains(item.targetStepID) {
            completed.remove(item.targetStepID)
            todayPrepCompletedBy[item.targetStepID] = nil
            todayPrepCheckedAt[item.targetStepID] = nil
            todayPrepActuals[item.targetStepID] = nil
            clearTodayPrepOperationalState(for: item.targetStepID)
        }
        todayPrepImpactItems.removeAll { $0.id == id }
        todayPrepAppliedImpactIDs.insert(id)
        todayPrepImpactAppliedCount += 1
        todayPrepImpactLastAction = "\(item.sourceLabel)を\(stepTitle(for: item.targetStepID))へ追加"
        syncNikiriRollup()
        refreshTodayPrepProgress()
        nowGuidanceTitle = todayPrepProgress.nextStepTitle ?? nowGuidanceTitle
        nowGuidanceBody = "\(guidanceBody(for: todayPrepProgress.nextStepID)) \(item.detail)"
        persistTodayPrepOperationalState()
        persistEvent(
            type: "today_prep.impact_applied",
            payload: "{\"impact_id\":\"\(item.id)\",\"source\":\"\(item.sourceLabel)\",\"step_id\":\"\(item.targetStepID)\"}"
        )
    }

    func dismissTodayPrepImpact(_ id: String) {
        guard let item = todayPrepImpactItems.first(where: { $0.id == id }) else {
            let reason = todayPrepAppliedImpactIDs.contains(id) ? "already_applied" : "missing"
            persistEvent(
                type: todayPrepAppliedImpactIDs.contains(id) ? "today_prep.impact_dismiss_skipped" : "today_prep.impact_dismiss_blocked",
                payload: "{\"impact_id\":\"\(id)\",\"reason\":\"\(reason)\"}"
            )
            return
        }
        todayPrepImpactItems.removeAll { $0.id == id }
        todayPrepImpactLastAction = "\(item.sourceLabel)を後で確認"
        persistTodayPrepOperationalState()
        persistEvent(
            type: "today_prep.impact_dismissed",
            payload: "{\"impact_id\":\"\(item.id)\",\"source\":\"\(item.sourceLabel)\"}"
        )
    }

    func todayPrepCompletionDisplay(for id: String) -> String? {
        todayPrepCompletedBy[id]
    }

    func todayPrepActualDisplay(for id: String) -> TodayPrepActual? {
        todayPrepActuals[id]
    }

    var currentTodayPrepChecks: [TodayPrepCheck] {
        guard let nextStepID = todayPrepProgress.nextStepID else {
            return []
        }
        return Self.todayPrepChecks(for: nextStepID)
            + todayPrepDynamicChecks.filter { $0.stepID == nextStepID }
    }

    var currentTodayPrepReadiness: TodayPrepReadiness {
        Engine.todayPrepReadiness(checks: currentTodayPrepChecks, completedCheckIDs: todayPrepCompletedCheckIDs)
    }

    var todayPrepOperatorWorkloads: [TodayPrepOperatorWorkload] {
        Engine.todayPrepOperatorWorkload(
            operators: todayPrepOperators,
            steps: Self.focusSteps,
            completedIDs: completed,
            stepAssignments: currentTodayPrepStepAssignments,
            activeStepID: todayPrepProgress.nextStepID.flatMap { todayPrepStartedAt[$0] == nil ? nil : $0 }
        )
    }

    private var currentTodayPrepStepAssignments: [String: String] {
        Self.todayPrepStepAssignments.merging(todayPrepStepOperatorOverrides) { _, override in
            override
        }
    }

    var lineGateStatus: LineGateStatus {
        LineGateStatus(
            completedCount: todayPrepProgress.completedCount,
            totalCount: todayPrepProgress.totalCount,
            unresolvedImpactCount: todayPrepImpactItems.count,
            recheckCount: guestReplyRecheckCount,
            labelReprintRequired: guestReplyRequiresLabelReprint,
            lastAction: lineGateLastAction
        )
    }

    var closeGateRecords: [CloseTaskRecord] {
        Self.defaultCloseGateRecords(nikiriBase: nikiriQuantity.total, unit: nikiriQuantity.unit)
    }
}

extension BoardStore {
    @discardableResult
    func queueConnectorReservationDiffs(
        _ events: [SourceReservationEvent] = BoardStore.defaultConnectorReviewEvents,
        receivedAt: String = "2026-06-17T09:04:00Z"
    ) -> [ConnectorDiffReviewItem] {
        persistConnectorAccount(provider: .tablecheck)
        var queuedCount = 0
        for event in events {
            guard isValidConnectorReservationEvent(event) else {
                persistBlockedConnectorReservationEvent(event, reason: "invalid_event")
                continue
            }
            let normalized = normalizeReservationEvent(event)
            let reviewState = connectorSourceEventReviewState(event.id)
            if let reviewState, isTerminalConnectorReviewState(reviewState) {
                upsertConnectorReviewItem(
                    reviewItem(
                        for: event,
                        normalized: normalized,
                        state: connectorReviewDisplayState(reviewState)
                    )
                )
                persistEvent(
                    type: "connector.sync_event_skipped",
                    payload: "{\"source_event_id\":\"\(event.id)\",\"reason\":\"review_\(reviewState)\"}"
                )
                continue
            }
            connectorPendingEvents[event.id] = event
            queuedCount += 1
            upsertConnectorReviewItem(reviewItem(for: event, normalized: normalized, state: "未処理"))
            persistSourceReservationEvent(
                event,
                normalized: normalized,
                processedAt: nil,
                reviewState: "pending",
                occurredAt: receivedAt
            )
        }
        connectorLastSyncSummary = "TableCheck \(queuedCount)件・承認待ち \(connectorPendingEvents.count)件"
        persistEvent(
            type: "connector.sync_replayed",
            payload: "{\"provider\":\"tablecheck\",\"pending\":\(connectorPendingEvents.count),\"received_at\":\"\(receivedAt)\"}"
        )
        return connectorDiffReviewItems
    }

    @discardableResult
    func acceptConnectorDiff(_ sourceEventID: String) -> ReservationDiffSummary {
        guard let event = connectorPendingEvents[sourceEventID] else {
            let previousCovers = service.omakaseCovers
            let unchanged = reservationDiff(previous: reservationSnapshots(), current: reservationSnapshots())
            reservationDiffSummary = unchanged
            reservationPlanDiff = planDiffForReservationDiff(unchanged, previousCovers: previousCovers)
            connectorLastSyncSummary = "TableCheck 承認対象なし・残り \(connectorPendingEvents.count)件"
            persistEvent(
                type: "connector.diff_accept_blocked",
                payload: "{\"source_event_id\":\"\(sourceEventID)\",\"reason\":\"not_pending\"}"
            )
            return unchanged
        }

        let diff = replayConnectorReservation(event)
        connectorPendingEvents.removeValue(forKey: sourceEventID)
        markConnectorReviewItem(sourceEventID, state: "承認済み")
        let normalized = normalizeReservationEvent(event)
        let signals = replayGuestSignals(
            normalized,
            seatRef: connectorSeatRef(for: event),
            language: "ja"
        )
        connectorReplayCount += 1
        connectorLastSyncSummary = "TableCheck 承認済み \(connectorReplayCount)件・特別対応 \(signals.count)件・残り \(connectorPendingEvents.count)件"
        persistEvent(
            type: "connector.diff_accepted",
            payload: "{\"source_event_id\":\"\(sourceEventID)\",\"signals\":\(signals.count),\"remaining\":\(connectorPendingEvents.count)}"
        )
        queueReservationTodayPrepImpact(diff, sourceLabel: "TableCheck")
        return diff
    }

    func rejectConnectorDiff(_ sourceEventID: String) {
        guard let event = connectorPendingEvents.removeValue(forKey: sourceEventID) else {
            connectorLastSyncSummary = "TableCheck 却下対象なし・残り \(connectorPendingEvents.count)件"
            persistEvent(
                type: "connector.diff_reject_blocked",
                payload: "{\"source_event_id\":\"\(sourceEventID)\",\"reason\":\"not_pending\"}"
            )
            return
        }

        let normalized = normalizeReservationEvent(event)
        markConnectorReviewItem(sourceEventID, state: "却下")
        connectorLastSyncSummary = "TableCheck 却下・残り \(connectorPendingEvents.count)件"
        persistSourceReservationEvent(
            event,
            normalized: normalized,
            processedAt: "2026-06-17T09:05:00Z",
            reviewState: "rejected",
            occurredAt: "2026-06-17T09:04:00Z"
        )
        persistEvent(
            type: "connector.diff_rejected",
            payload: "{\"source_event_id\":\"\(sourceEventID)\",\"reservation_id\":\"\(normalized.id)\"}"
        )
    }

    @discardableResult
    func replayConnectorReservation(_ event: SourceReservationEvent) -> ReservationDiffSummary {
        let previousCovers = service.omakaseCovers
        guard isValidConnectorReservationEvent(event) else {
            let unchanged = unchangedReservationDiff()
            reservationDiffSummary = unchanged
            reservationPlanDiff = planDiffForReservationDiff(unchanged, previousCovers: previousCovers)
            connectorLastSyncSummary = "TableCheck 不正イベントをスキップ"
            persistBlockedConnectorReservationEvent(event, reason: "invalid_event")
            return unchanged
        }
        if let reviewState = connectorSourceEventReviewState(event.id), isTerminalConnectorReviewState(reviewState) {
            let unchanged = unchangedReservationDiff()
            reservationDiffSummary = unchanged
            reservationPlanDiff = planDiffForReservationDiff(unchanged, previousCovers: previousCovers)
            connectorLastSyncSummary = "TableCheck 同期済みイベントをスキップ"
            persistEvent(
                type: "connector.reservation_replay_skipped",
                payload: "{\"source_event_id\":\"\(event.id)\",\"reason\":\"review_\(reviewState)\"}"
            )
            return unchanged
        }

        let previous = reservationSnapshots()
        let normalized = normalizeReservationEvent(event)
        latestConnectorReservation = normalized
        persistConnectorAccount(provider: event.provider)
        persistSourceReservationEvent(event, normalized: normalized, reviewState: "accepted")
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
        guard isValidDirectBookingCovers(booking.covers) else {
            let diff = unchangedReservationDiff()
            reservationDiffSummary = diff
            reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
            persistEvent(
                type: "direct_booking.accept_blocked",
                payload: "{\"booking_id\":\"\(booking.id)\",\"reason\":\"invalid_covers\",\"covers\":\(booking.covers)}"
            )
            return diff
        }
        if let status = directBookingStatus(booking.id), status != .request {
            let diff = unchangedReservationDiff()
            reservationDiffSummary = diff
            reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
            persistEvent(
                type: "direct_booking.accept_blocked",
                payload: "{\"booking_id\":\"\(booking.id)\",\"reason\":\"status_\(status.rawValue)\"}"
            )
            return diff
        }
        let checkout = startDirectBookingCheckout(booking, depositRequired: depositRequired)
        let confirmed = confirmedDirectBooking(booking, checkout: checkout)
        let normalized = normalizeDirectBooking(confirmed)

        latestDirectBooking = confirmed
        persistDirectBooking(confirmed)
        persistDirectServiceOpsState()
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
        queueReservationTodayPrepImpact(diff, sourceLabel: "Direct")
        return diff
    }

    @discardableResult
    func cancelDirectBooking(_ bookingID: String) -> ReservationDiffSummary {
        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
        guard let current = currentDirectBooking(id: bookingID), current.status == .confirmed || current.status == .request else {
            let diff = unchangedReservationDiff()
            reservationDiffSummary = diff
            reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
            persistEvent(type: "direct_booking.cancel_blocked", payload: "{\"booking_id\":\"\(bookingID)\",\"reason\":\"not_cancelable\"}")
            return diff
        }
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
        persistDirectServiceOpsState()
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
        queueReservationTodayPrepImpact(diff, sourceLabel: "Direct取消")
        return diff
    }

    @discardableResult
    func evaluateDirectAllotment(_ booking: DirectBooking, allottedCovers: Int) -> DirectBookingDecision {
        guard isValidDirectBookingCovers(booking.covers) else {
            return blockDirectBookingEvaluation(booking, allottedCovers: allottedCovers)
        }
        if let status = directBookingStatus(booking.id) {
            let skipped = DirectBookingDecision(
                status: status,
                confirmedCovers: status == .confirmed ? booking.covers : 0,
                waitlistCovers: status == .request ? booking.covers : 0,
                remainingAllotment: 0,
                reason: status == .request ? "waitlist_registered" : "status_\(status.rawValue)"
            )
            latestDirectDecision = skipped
            persistDirectServiceOpsState()
            persistEvent(
                type: "direct_booking.evaluate_skipped",
                payload: "{\"booking_id\":\"\(booking.id)\",\"reason\":\"status_\(status.rawValue)\",\"waitlist_covers\":\(skipped.waitlistCovers)}"
            )
            return skipped
        }

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
        persistDirectServiceOpsState()
        persistEvent(
            type: "direct_booking.evaluated",
            payload: "{\"booking_id\":\"\(booking.id)\",\"reason\":\"\(decision.reason)\",\"waitlist_covers\":\(decision.waitlistCovers)}"
        )
        return decision
    }

    @discardableResult
    func promoteWaitlistedDirectBooking(_ booking: DirectBooking, allottedCovers: Int) -> DirectWaitlistPromotion {
        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
        guard isValidDirectBookingCovers(booking.covers) else {
            return blockWaitlistPromotion(
                booking,
                reason: "invalid_covers",
                allottedCovers: allottedCovers,
                previousCovers: previousCovers
            )
        }
        guard allottedCovers >= 0 else {
            return blockWaitlistPromotion(
                booking,
                reason: "invalid_allotment",
                allottedCovers: allottedCovers,
                previousCovers: previousCovers
            )
        }
        if let status = directBookingStatus(booking.id), status != .request {
            return blockWaitlistPromotion(booking, status: status, allottedCovers: allottedCovers, previousCovers: previousCovers)
        }
        let booked = confirmedDirectCovers(excluding: booking.id)
        let promotion = promoteDirectWaitlist(
            booking,
            allotment: DirectAllotment(
                id: "allotment-\(service.id)-\(booking.visitTime)",
                serviceDayID: service.id,
                slot: booking.visitTime,
                allottedCovers: allottedCovers,
                bookedCovers: booked
            )
        )
        latestWaitlistPromotion = promotion
        persistDirectServiceOpsState()

        guard promotion.status == .confirmed else {
            persistEvent(
                type: "direct_waitlist.promotion_blocked",
                payload: "{\"booking_id\":\"\(booking.id)\",\"reason\":\"\(promotion.reason)\",\"remaining_allotment\":\(promotion.remainingAllotment)}"
            )
            return promotion
        }

        persistPromotedWaitlistDirectBooking(
            booking,
            promotion: promotion,
            previous: previous,
            previousCovers: previousCovers
        )
        return promotion
    }

    @discardableResult
    func recordDirectNoShow(_ booking: DirectBooking, forfeitsDeposit: Bool = true) -> DirectNoShowSettlement {
        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
        guard directBookingStatus(booking.id) == .confirmed else {
            let blocked = DirectNoShowSettlement(
                id: "noshow-\(booking.id)",
                bookingID: booking.id,
                status: directBookingStatus(booking.id) ?? booking.status,
                forfeitsDeposit: false,
                prepImpactCovers: 0
            )
            latestNoShowSettlement = blocked
            persistDirectServiceOpsState()
            let diff = unchangedReservationDiff()
            reservationDiffSummary = diff
            reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
            persistEvent(type: "direct_booking.noshow_blocked", payload: "{\"booking_id\":\"\(booking.id)\",\"reason\":\"not_confirmed\"}")
            return blocked
        }
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
        latestDirectBooking = noshow
        persistDirectBooking(noshow)
        persistDirectServiceOpsState()
        applyNormalizedReservation(normalizeDirectBooking(noshow))
        persistServiceCover()
        let diff = reservationDiff(previous: previous, current: reservationSnapshots())
        reservationDiffSummary = diff
        reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
        persistReservationDiff(diff, kind: "direct_noshow")
        persistEvent(
            type: "direct_booking.noshow_recorded",
            payload: "{\"booking_id\":\"\(booking.id)\",\"forfeits_deposit\":\(settlement.forfeitsDeposit),\"prep_impact_covers\":\(settlement.prepImpactCovers)}"
        )
        queueReservationTodayPrepImpact(diff, sourceLabel: "Direct no-show")
        return settlement
    }

    @discardableResult
    func replayGuestSignals(_ reservation: NormalizedReservation, seatRef: String = "卓3", language: String = "ja") -> [GuestSignal] {
        let signals = guestSignals(from: reservation)
        let prepTasks = Engine.specialPrepTasks(from: signals)
        let labels = Engine.allergenLabels(from: signals, seatRef: seatRef, language: language)
        let message = guestConfirmationMessage(reservation, language: language)

        upsertSpecialPrepTasks(prepTasks)
        upsertAllergenLabels(labels)
        upsertGuestMessage(message)
        upsertPassSeatFlags(labels.map {
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
        if !prepTasks.isEmpty {
            specialPrepLastAction = "\(prepTasks.count)件の特別仕込みを生成"
        }
        if !labels.isEmpty {
            specialPrepLastAction = "\(seatRef) のアレルギー参考を厨房へ共有"
        }
        guestMessageLastAction = "\(reservation.partyName) へ確認文を下書き"
        refreshPassState()
        persistGuestOpsState()
        persistEvent(type: "guest_signals.replayed", payload: "{\"reservation_id\":\"\(reservation.id)\",\"signals\":\(signals.count)}")
        return signals
    }

    func completeSpecialPrepTask(_ id: String) {
        guard !specialPrepCompletedIDs.contains(id) else {
            specialPrepLastAction = "特別仕込みは完了済み / 再実行なし"
            persistGuestOpsState()
            persistEvent(
                type: "special_prep.complete_skipped",
                payload: "{\"special_prep_id\":\"\(id)\",\"reason\":\"already_completed\"}"
            )
            return
        }
        guard !specialPrepSkippedIDs.contains(id) else {
            specialPrepLastAction = "特別仕込みはスキップ済み / 完了不可"
            persistGuestOpsState()
            persistEvent(
                type: "special_prep.complete_blocked",
                payload: "{\"special_prep_id\":\"\(id)\",\"reason\":\"already_skipped\"}"
            )
            return
        }
        guard let task = specialPrepTasks.first(where: { $0.id == id }) else {
            specialPrepLastAction = "特別仕込みが見つかりません"
            persistGuestOpsState()
            persistEvent(
                type: "special_prep.complete_blocked",
                payload: "{\"special_prep_id\":\"\(id)\",\"reason\":\"missing\"}"
            )
            return
        }
        try? database?.update(named: "special_prep", id: id, tenantID: tenantID, values: [
            "status": "done",
        ])
        specialPrepCompletedIDs.insert(id)
        specialPrepTasks.removeAll { $0.id == id }
        specialPrepLastAction = "\(task.title) を完了"
        persistGuestOpsState()
        persistEvent(type: "special_prep.completed", payload: "{\"special_prep_id\":\"\(id)\",\"reservation_id\":\"\(task.reservationID)\"}")
    }

    func skipSpecialPrepTask(_ id: String) {
        guard !specialPrepSkippedIDs.contains(id) else {
            specialPrepLastAction = "特別仕込みはスキップ済み / 再実行なし"
            persistGuestOpsState()
            persistEvent(
                type: "special_prep.skip_skipped",
                payload: "{\"special_prep_id\":\"\(id)\",\"reason\":\"already_skipped\"}"
            )
            return
        }
        guard !specialPrepCompletedIDs.contains(id) else {
            specialPrepLastAction = "特別仕込みは完了済み / スキップ不可"
            persistGuestOpsState()
            persistEvent(
                type: "special_prep.skip_blocked",
                payload: "{\"special_prep_id\":\"\(id)\",\"reason\":\"already_completed\"}"
            )
            return
        }
        guard let task = specialPrepTasks.first(where: { $0.id == id }) else {
            specialPrepLastAction = "特別仕込みが見つかりません"
            persistGuestOpsState()
            persistEvent(
                type: "special_prep.skip_blocked",
                payload: "{\"special_prep_id\":\"\(id)\",\"reason\":\"missing\"}"
            )
            return
        }
        specialPrepTasks.removeAll { $0.id == id }
        try? database?.update(named: "special_prep", id: id, tenantID: tenantID, values: [
            "deleted_at": "2026-06-17T17:03:00Z",
        ])
        specialPrepSkippedIDs.insert(id)
        specialPrepLastAction = "\(task.title) をスキップ"
        persistGuestOpsState()
        persistEvent(type: "special_prep.skipped", payload: "{\"special_prep_id\":\"\(id)\",\"reservation_id\":\"\(task.reservationID)\"}")
    }

    func sendGuestConfirmationMessages(now: String = "2026-06-17T17:02:00Z") {
        let pendingMessages = guestMessages.filter { $0.status != "sent" }
        guard !pendingMessages.isEmpty else {
            guestMessageLastAction = "確認文は送信済み / 再送なし"
            persistGuestOpsState()
            persistEvent(type: "guest_message.send_skipped", payload: "{\"reason\":\"already_sent\",\"sent_at\":\"\(now)\"}")
            return
        }

        let pendingIDs = Set(pendingMessages.map(\.id))
        for message in pendingMessages {
            try? database?.update(named: "guest_message", id: message.id, tenantID: tenantID, values: [
                "status": "sent",
            ])
        }
        guestMessages = guestMessages.map {
            GuestMessage(
                id: $0.id,
                reservationID: $0.reservationID,
                language: $0.language,
                body: $0.body,
                status: pendingIDs.contains($0.id) ? "sent" : $0.status
            )
        }
        guestMessageLastAction = "\(pendingMessages.count)件を送信済み"
        persistGuestOpsState()
        persistEvent(type: "guest_message.sent", payload: "{\"count\":\(pendingMessages.count),\"sent_at\":\"\(now)\"}")
    }

    func recordLatestGuestReplyChange(note: String = "ゲスト返信：ナッツ不可を追記") {
        let reservationID = guestMessages.last?.reservationID ?? latestConnectorReservation?.id ?? "reservation-tablecheck-kimura-2030"
        recordGuestMessageReply(reservationID: reservationID, changed: true, note: note)
    }

    func recordGuestMessageReply(reservationID: String, changed: Bool, note: String = "ゲスト返信：内容変更") {
        let status = changed ? "変更あり" : "確認OK"
        guestMessageLastAction = "\(reservationID) \(status)"
        if changed {
            if hasOpenGuestReplyChange(for: reservationID) {
                guestReplyRecheckCount = activeGuestReplyRecheckCount
                guestReplyRequiresLabelReprint = guestReplyRequiresLabelReprint || hasAllergenLabel(forReservationID: reservationID)
                guestReplyRecheckLastAction = "\(seatRef(forReservationID: reservationID)) 返信変更は確認中"
                persistGuestOpsState()
                persistEvent(
                    type: "guest_message.reply_change_skipped",
                    payload: "{\"reservation_id\":\"\(reservationID)\",\"reason\":\"already_open\"}"
                )
                return
            }
            createGuestReplyRecheck(reservationID: reservationID, note: note)
        } else {
            guestReplyRecheckLastAction = "\(reservationID) 確認OK"
        }
        persistGuestOpsState()
        persistEvent(
            type: changed ? "guest_message.reply_changed" : "guest_message.reply_ok",
            payload: "{\"reservation_id\":\"\(reservationID)\",\"status\":\"\(status)\",\"note\":\"\(note)\"}"
        )
        if changed {
            queueGuestReplyTodayPrepImpact(reservationID: reservationID, note: note)
        }
    }

    func completeGuestReplyRecheck(_ reservationID: String? = nil) {
        let targetID = reservationID ?? guestMessages.last?.reservationID ?? latestConnectorReservation?.id ?? "reservation-tablecheck-kimura-2030"
        let taskID = guestReplyRecheckTaskID(reservationID: targetID)
        guard specialPrepTasks.contains(where: { $0.id == taskID }) else {
            guestReplyRecheckCount = activeGuestReplyRecheckCount
            guestReplyRecheckLastAction = "\(targetID) 再確認なし"
            persistGuestOpsState()
            persistEvent(
                type: "guest_reply.recheck_skipped",
                payload: "{\"reservation_id\":\"\(targetID)\",\"special_prep_id\":\"\(taskID)\",\"reason\":\"task_missing\"}"
            )
            return
        }
        completeSpecialPrepTask(taskID)
        specialPrepTasks.removeAll { $0.id == taskID }
        guestReplyRecheckCount = activeGuestReplyRecheckCount
        guestReplyRequiresLabelReprint = guestReplyRecheckCount > 0 && guestReplyRequiresLabelReprint
        guestReplyRecheckLastAction = "\(targetID) 再確認完了"
        persistGuestOpsState()
        persistEvent(type: "guest_reply.recheck_completed", payload: "{\"reservation_id\":\"\(targetID)\",\"special_prep_id\":\"\(taskID)\"}")
    }

    func printAllergenLabels(now: String = "2026-06-17T17:04:00Z") {
        guard !allergenLabels.isEmpty else {
            specialPrepLastAction = "印刷する席札なし"
            persistGuestOpsState()
            persistEvent(type: "allergen_label.print_blocked", payload: "{\"reason\":\"label_missing\",\"printed_at\":\"\(now)\"}")
            return
        }
        if allergenLabelPrintedAt != nil, !guestReplyRequiresLabelReprint {
            specialPrepLastAction = "席札印刷済み / 再印刷なし"
            persistGuestOpsState()
            persistEvent(type: "allergen_label.print_skipped", payload: "{\"reason\":\"already_printed\",\"printed_at\":\"\(now)\"}")
            return
        }
        allergenLabelPrintCount += allergenLabels.count
        allergenLabelPrintedAt = now
        guestReplyRequiresLabelReprint = false
        persistGuestOpsState()
        persistEvent(type: "allergen_label.printed", payload: "{\"count\":\(allergenLabels.count),\"printed_at\":\"\(now)\"}")
    }

    @discardableResult
    func replayServiceSyncEvent(
        _ event: ServiceSyncEvent,
        elapsedMinutes: Int = 60,
        serviceMinutes: Int = 120
    ) -> ServiceSyncState {
        guard isValidServiceSyncEvent(event) else {
            persistEvent(
                type: "service_sync.event_blocked",
                payload: "{\"service_event_id\":\"\(event.id)\",\"kind\":\"\(event.kind.rawValue)\",\"reason\":\"invalid_event\",\"covers\":\(event.covers)}"
            )
            return currentServiceSyncState(elapsedMinutes: elapsedMinutes, serviceMinutes: serviceMinutes)
        }
        if let index = serviceSyncEvents.firstIndex(where: { $0.id == event.id }) {
            let existing = serviceSyncEvents[index]
            if isOfflineFlushReplacement(existing: existing, replacement: event) {
                serviceSyncEvents[index] = event
            } else if existing == event {
                persistEvent(type: "service_sync.duplicate_ignored", payload: "{\"service_event_id\":\"\(event.id)\",\"kind\":\"\(event.kind.rawValue)\"}")
                return currentServiceSyncState(elapsedMinutes: elapsedMinutes, serviceMinutes: serviceMinutes)
            } else {
                persistEvent(type: "service_sync.conflict_blocked", payload: "{\"service_event_id\":\"\(event.id)\",\"kind\":\"\(event.kind.rawValue)\"}")
                return currentServiceSyncState(elapsedMinutes: elapsedMinutes, serviceMinutes: serviceMinutes)
            }
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
        persistDirectServiceOpsState()
        let payload = """
        {"service_event_id":"\(event.id)","kind":"\(event.kind.rawValue)","remaining_covers":\(state.remainingCovers),"recommendation":"\(state.pacing.recommendation)"}
        """
        persistEvent(
            type: "service_sync.replayed",
            payload: payload
        )
        queueServiceSyncTodayPrepImpact(state)
        return state
    }

    var serviceSyncEventTimeline: [ServiceSyncEvent] {
        serviceSyncEvents.sorted { $0.occurredAt < $1.occurredAt }
    }

    var servicePassPendingOfflineCount: Int {
        serviceSyncEvents.count { $0.offlineSequence != nil }
    }

    @discardableResult
    func acceptIncomingServiceFire() -> ServiceSyncState {
        let event = servicePassEvent(kind: .fire, covers: 4, occurredAt: "2026-06-17T18:42:00Z")
        let alreadyReplayed = serviceSyncEvents.contains { $0.id == event.id }
        let state = replayServiceSyncEvent(event)
        guard !alreadyReplayed else {
            servicePassLastAction = "卓3 握り FIRE は反映済み"
            persistDirectServiceOpsState()
            persistEvent(type: "service_pass.fire_accept_skipped", payload: "{\"reservation_id\":\"reservation-sato\",\"reason\":\"already_replayed\"}")
            return state
        }
        servicePassLastAction = "卓3 握り FIRE を厨房へ反映"
        persistDirectServiceOpsState()
        persistEvent(type: "service_pass.fire_accepted", payload: "{\"reservation_id\":\"reservation-sato\",\"covers\":4}")
        return state
    }

    @discardableResult
    func holdIncomingServiceFire() -> ServiceSyncState {
        let event = servicePassEvent(kind: .hold, covers: 4, occurredAt: "2026-06-17T18:43:00Z")
        let alreadyReplayed = serviceSyncEvents.contains { $0.id == event.id }
        let state = replayServiceSyncEvent(event)
        guard !alreadyReplayed else {
            servicePassLastAction = "卓3 握り HOLD は反映済み"
            persistDirectServiceOpsState()
            persistEvent(type: "service_pass.fire_hold_skipped", payload: "{\"reservation_id\":\"reservation-sato\",\"reason\":\"already_replayed\"}")
            return state
        }
        servicePassLastAction = "卓3 握りを HOLD"
        persistDirectServiceOpsState()
        persistEvent(type: "service_pass.fire_held", payload: "{\"reservation_id\":\"reservation-sato\",\"covers\":4}")
        return state
    }

    @discardableResult
    func markServiceCourseServed() -> ServiceSyncState {
        let event = servicePassEvent(kind: .served, covers: 4, occurredAt: "2026-06-17T18:54:00Z")
        let alreadyReplayed = serviceSyncEvents.contains { $0.id == event.id }
        let state = replayServiceSyncEvent(event)
        guard !alreadyReplayed else {
            servicePassLastAction = "卓3 握り提供は反映済み"
            persistDirectServiceOpsState()
            persistEvent(type: "service_pass.course_serve_skipped", payload: "{\"reservation_id\":\"reservation-sato\",\"reason\":\"already_replayed\"}")
            return state
        }
        servicePassLastAction = "卓3 握りを提供済みに更新"
        persistDirectServiceOpsState()
        persistEvent(type: "service_pass.course_served", payload: "{\"reservation_id\":\"reservation-sato\",\"covers\":4}")
        return state
    }

    @discardableResult
    func queueOfflineServiceServed() -> ServiceSyncState {
        if let existing = serviceSyncEvents.first(where: {
            $0.kind == .served
                && $0.reservationID == "reservation-yamada"
                && $0.offlineSequence != nil
        }) {
            servicePassLastAction = "卓1 握りはオフライン保存済み"
            persistDirectServiceOpsState()
            persistEvent(
                type: "service_pass.offline_queue_skipped",
                payload: "{\"service_event_id\":\"\(existing.id)\",\"reason\":\"already_pending\"}"
            )
            return currentServiceSyncState(elapsedMinutes: 75, serviceMinutes: 120)
        }
        let offlineSequence = servicePassPendingOfflineCount + 1
        let event = servicePassEvent(
            kind: .served,
            covers: 2,
            reservationID: "reservation-yamada",
            occurredAt: "2026-06-17T19:03:00Z",
            offlineSequence: offlineSequence
        )
        let state = replayServiceSyncEvent(event, elapsedMinutes: 75, serviceMinutes: 120)
        servicePassLastAction = "卓1 握りをオフライン保存"
        persistDirectServiceOpsState()
        persistEvent(type: "service_pass.offline_queued", payload: "{\"offline_sequence\":\(offlineSequence),\"covers\":2}")
        return state
    }

    @discardableResult
    func flushOfflineServiceEvents() -> ServiceSyncState {
        let offlineEvents = serviceSyncEvents.filter { $0.offlineSequence != nil }
        var state = serviceSyncState ?? Engine.serviceSyncState(
            plannedCovers: service.omakaseCovers,
            events: serviceSyncEvents,
            elapsedMinutes: 75,
            serviceMinutes: 120
        )

        guard !offlineEvents.isEmpty else {
            servicePassLastAction = "未送信なし"
            persistDirectServiceOpsState()
            persistEvent(type: "service_pass.offline_flush_skipped", payload: "{\"reason\":\"empty_queue\"}")
            return state
        }

        for event in offlineEvents {
            var synced = event
            synced.offlineSequence = nil
            state = replayServiceSyncEvent(synced, elapsedMinutes: 75, serviceMinutes: 120)
        }

        servicePassLastAction = "未送信 \(offlineEvents.count)件を再同期"
        persistDirectServiceOpsState()
        persistEvent(type: "service_pass.offline_flushed", payload: "{\"flushed\":\(offlineEvents.count)}")
        return state
    }

    private func servicePassEvent(
        kind: ServiceEventKind,
        covers: Int,
        reservationID: String = "reservation-sato",
        occurredAt: String,
        offlineSequence: Int? = nil
    ) -> ServiceSyncEvent {
        let suffix = offlineSequence == nil ? "live" : "offline"
        return ServiceSyncEvent(
            id: "service-pass-\(kind.rawValue)-\(reservationID)-\(suffix)",
            source: offlineSequence == nil ? .kds : .manual,
            kind: kind,
            covers: covers,
            reservationID: reservationID,
            occurredAt: occurredAt,
            offlineSequence: offlineSequence
        )
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
    func replayServiceSyncBatch(
        _ events: [ServiceSyncEvent],
        elapsedMinutes: Int = 60,
        serviceMinutes: Int = 120
    ) -> ServiceReplaySummary {
        let validEvents = events.filter { event in
            guard isValidServiceSyncEvent(event) else {
                persistEvent(
                    type: "service_sync.event_blocked",
                    payload: "{\"service_event_id\":\"\(event.id)\",\"kind\":\"\(event.kind.rawValue)\",\"reason\":\"invalid_event\",\"covers\":\(event.covers)}"
                )
                return false
            }
            return true
        }
        let existingEventIDs = Set(serviceSyncEvents.map(\.id))
        let replay = replayServiceEvents(
            plannedCovers: service.omakaseCovers,
            events: serviceSyncEvents + validEvents,
            elapsedMinutes: elapsedMinutes,
            serviceMinutes: serviceMinutes
        )
        guard validEvents.contains(where: { !existingEventIDs.contains($0.id) }) else {
            serviceSyncState = replay.state
            servicePacingProposal = replay.state.pacing
            refreshPassState()
            refreshStoreSummary(replay.state)
            persistDirectServiceOpsState()
            persistEvent(
                type: "service_sync.batch_replay_skipped",
                payload: "{\"accepted\":\(replay.acceptedEventIDs.count),\"duplicates\":\(replay.ignoredDuplicateEventIDs.count),\"reason\":\"no_new_events\"}"
            )
            return replay
        }

        serviceSyncEvents = replay.acceptedEventIDs.compactMap { id in
            (serviceSyncEvents + validEvents).first { $0.id == id }
        }
        for event in serviceSyncEvents {
            persistServiceSyncEvent(event)
        }
        serviceSyncState = replay.state
        servicePacingProposal = replay.state.pacing
        refreshPassState()
        refreshStoreSummary(replay.state)
        persistDirectServiceOpsState()
        persistEvent(
            type: "service_sync.batch_replayed",
            payload: "{\"accepted\":\(replay.acceptedEventIDs.count),\"duplicates\":\(replay.ignoredDuplicateEventIDs.count),\"remaining_covers\":\(replay.state.remainingCovers)}"
        )
        queueServiceSyncTodayPrepImpact(replay.state)
        return replay
    }

    @discardableResult
    func issueNikiriPrepLabel(
        madeQty: Double? = nil,
        printedAt: String = "2026-06-11T16:20:00Z",
        now: String = "17:25",
        storageUnitID: String? = nil
    ) -> PrepLabel {
        let requestedLabel = makeNikiriPrepLabel(
            madeQty: madeQty,
            printedAt: printedAt,
            storageUnitID: storageUnitID
        )
        if blockNikiriLabelIssueIfNeeded(requestedLabel, now: now) {
            return requestedLabel
        }
        if let existingLabel = existingNikiriLabelIssueBlockOrSkip(for: requestedLabel) {
            return existingLabel
        }
        persistIssuedNikiriPrepLabel(requestedLabel, printedAt: printedAt)
        return requestedLabel
    }

    @discardableResult
    func scanLatestLabelRemaining(qty: Double) -> LabelScanResult {
        guard let label = latestPrepLabel else {
            return blockedLabelScanResult(action: .remaining(qty: qty), scanKind: "remaining", reason: "label_missing")
        }
        guard canScanLabel(label) else {
            return blockedLabelScanResult(action: .remaining(qty: qty), scanKind: "remaining", existingLabel: label, reason: "terminal_status")
        }
        guard isValidPositiveLabelScanQty(qty) else {
            return blockedLabelScanResult(action: .remaining(qty: qty), scanKind: "remaining", existingLabel: label, reason: "invalid_qty")
        }
        let result = scanPrepLabel(label, action: .remaining(qty: cappedLabelScanQty(qty, for: label)))
        persistLabelScanResult(result, scanKind: "remaining")
        if let larder = result.larderItem, larder.qty > 0 {
            persistLabelCarryover(larder)
        }
        return result
    }

    @discardableResult
    func scanLatestLabelWaste(qty: Double, reason: WasteReason = .quality) -> LabelScanResult {
        guard let label = latestPrepLabel else {
            return blockedLabelScanResult(action: .wasted(qty: qty, reason: reason), scanKind: "wasted", reason: "label_missing")
        }
        guard canScanLabel(label) else {
            return blockedLabelScanResult(action: .wasted(qty: qty, reason: reason), scanKind: "wasted", existingLabel: label, reason: "terminal_status")
        }
        guard isValidPositiveLabelScanQty(qty) else {
            return blockedLabelScanResult(action: .wasted(qty: qty, reason: reason), scanKind: "wasted", existingLabel: label, reason: "invalid_qty")
        }
        let result = scanPrepLabel(label, action: .wasted(qty: cappedLabelScanQty(qty, for: label), reason: reason))
        persistLabelScanResult(result, scanKind: "wasted")
        return result
    }

    @discardableResult
    func scanLatestLabelUsed() -> LabelScanResult {
        guard let label = latestPrepLabel else {
            return blockedLabelScanResult(action: .used, scanKind: "used", reason: "label_missing")
        }
        guard canScanLabel(label) else {
            return blockedLabelScanResult(action: .used, scanKind: "used", existingLabel: label, reason: "terminal_status")
        }
        let result = scanPrepLabel(label, action: .used)
        persistLabelScanResult(result, scanKind: "used")
        return result
    }

    @discardableResult
    func refreshLarderFIFO(nowDate: String = "2026-06-12", alertWithinDays: Int = 1) -> [LarderAlert] {
        larderAlerts = fifoLarder(larderItems, nowDate: nowDate, alertWithinDays: alertWithinDays)
        persistEvent(
            type: "larder.fifo_refreshed",
            payload: "{\"items\":\(larderAlerts.count),\"due\":\(larderAlerts.count(where: { $0.level != "ok" }))}"
        )
        return larderAlerts
    }

    @discardableResult
    func planLarderUse(requiredQty: Double? = nil, nowDate: String = "2026-06-12") -> LarderConsumptionPlan {
        let plan = planLarderConsumption(
            larderItems,
            requiredQty: requiredQty ?? nikiriQuantity.total,
            unit: nikiriQuantity.unit,
            nowDate: nowDate
        )
        larderConsumptionPlan = plan
        persistEvent(
            type: "larder.consumption_planned",
            payload: "{\"requested_qty\":\(numberString(plan.requestedQty)),\"planned_qty\":\(numberString(plan.plannedQty)),\"shortfall_qty\":\(numberString(plan.shortfallQty))}"
        )
        return plan
    }

    @discardableResult
    func applyPlannedLarderUse(requiredQty: Double? = nil, nowDate: String = "2026-06-12") -> LarderConsumptionPlan {
        let requestedQty = requiredQty ?? nikiriQuantity.total
        guard requestedQty.isFinite, requestedQty > 0 else {
            let blockedPlan = blockedLarderUsePlan(requestedQty: 0, summary: "FIFO使用不可 / 必要量を確認")
            persistEvent(
                type: "larder.use_blocked",
                payload: "{\"reason\":\"invalid_required_qty\",\"requested_qty\":\(numberString(max(0, requestedQty))),\"now_date\":\"\(nowDate)\"}"
            )
            return blockedPlan
        }
        let intentKey = larderUseIntentKey(requiredQty: requestedQty, nowDate: nowDate)
        guard !appliedLarderUseIntentKeys.contains(intentKey) else {
            let blockedPlan = blockedLarderUsePlan(requestedQty: requestedQty, summary: "FIFO使用済み / 再適用なし")
            persistEvent(
                type: "larder.use_blocked",
                payload: "{\"reason\":\"duplicate_intent\",\"requested_qty\":\(numberString(requestedQty)),\"now_date\":\"\(nowDate)\"}"
            )
            return blockedPlan
        }

        let plan = planLarderUse(requiredQty: requestedQty, nowDate: nowDate)
        for use in plan.uses {
            guard let index = larderItems.firstIndex(where: { $0.labelID == use.labelID }) else { continue }
            let nextQty = max(0, larderItems[index].qty - use.qty)
            larderItems[index].qty = nextQty
            larderItems[index].status = nextQty == 0 ? .used : .available
            upsertLarderItem(larderItems[index])
        }
        latestLarderUseSummary = "\(numberString(plan.plannedQty))\(plan.unit) をFIFO使用 / 不足 \(numberString(plan.shortfallQty))\(plan.unit)"
        refreshLarderFIFO(nowDate: nowDate)
        appliedLarderUseIntentKeys.insert(intentKey)
        persistLabelOpsState()
        persistEvent(
            type: "larder.used_for_prep",
            payload: "{\"requested_qty\":\(numberString(plan.requestedQty)),\"used_qty\":\(numberString(plan.plannedQty)),\"shortfall_qty\":\(numberString(plan.shortfallQty))}"
        )
        return plan
    }

    private func blockedLarderUsePlan(requestedQty: Double, summary: String) -> LarderConsumptionPlan {
        let blockedPlan = LarderConsumptionPlan(
            uses: [],
            requestedQty: requestedQty,
            plannedQty: 0,
            shortfallQty: 0,
            unit: nikiriQuantity.unit
        )
        larderConsumptionPlan = blockedPlan
        latestLarderUseSummary = summary
        return blockedPlan
    }

    func recordFridgeTemperature(
        valueC: Int = 3,
        storageUnitID: String? = nil,
        loggedAt: String = "2026-06-12T15:50:00Z"
    ) {
        let resolvedStorageUnitID = storageUnitID ?? storageColdID
        guard isValidFridgeTemperatureInput(
            valueC: valueC,
            storageUnitID: resolvedStorageUnitID,
            loggedAt: loggedAt
        ) else {
            persistEvent(
                type: "fridge.temperature_blocked",
                payload: "{\"storage_unit_id\":\"\(resolvedStorageUnitID)\",\"reason\":\"invalid_input\",\"value_c\":\(valueC),\"logged_at\":\"\(loggedAt)\"}"
            )
            return
        }
        let signature = fridgeTemperatureSignature(
            valueC: valueC,
            storageUnitID: resolvedStorageUnitID,
            loggedAt: loggedAt
        )
        guard !fridgeTemperatureRecordedSignatures.contains(signature) else {
            persistEvent(
                type: "fridge.temperature_skipped",
                payload: "{\"storage_unit_id\":\"\(resolvedStorageUnitID)\",\"reason\":\"duplicate_signature\",\"value_c\":\(valueC)}"
            )
            return
        }
        let tempID = "temp-\(resolvedStorageUnitID)-\(loggedAt)"
        fridgeTemperatureC = valueC
        fridgeTemperatureLoggedAt = loggedAt
        let values: [String: String?] = [
            "id": tempID,
            "tenant_id": tenantID,
            "storage_unit_id": resolvedStorageUnitID,
            "kind": "fridge",
            "value": String(valueC),
            "logged_at": loggedAt,
            "by_account_id": "local-ipad",
        ]
        try? database?.create(named: "temp_log", values: values)
        try? database?.update(named: "temp_log", id: tempID, tenantID: tenantID, values: values)
        fridgeTemperatureRecordedSignatures.insert(signature)
        persistLabelOpsState()
        persistEvent(
            type: "fridge.temperature_recorded",
            payload: "{\"storage_unit_id\":\"\(resolvedStorageUnitID)\",\"value_c\":\(valueC)}"
        )
    }

    @discardableResult
    func completeFridgeInspection(nowDate: String = "2026-06-13") -> Int {
        let completedAt = "\(nowDate)T10:10:00Z"
        if fridgeInspectionCompletedAt == completedAt {
            latestLarderUseSummary = "点検済み / 再実行なし"
            persistEvent(
                type: "fridge.inspection_skipped",
                payload: "{\"reason\":\"already_completed\",\"now_date\":\"\(nowDate)\"}"
            )
            return fridgeInspectionMissingCount
        }

        let alerts = refreshLarderFIFO(nowDate: nowDate, alertWithinDays: 1)
        let expiredLabelIDs = Set(alerts.filter { $0.level == "expired" }.map(\.labelID))
        var changedCount = 0

        for index in larderItems.indices where expiredLabelIDs.contains(larderItems[index].labelID) && larderItems[index].status == .available {
            let item = larderItems[index]
            larderItems[index].qty = 0
            larderItems[index].status = .expired
            upsertLarderItem(larderItems[index])
            persistLabelWasteRecord(
                CloseTaskRecord(
                    task: item.prepTaskID,
                    plannedQty: item.qty,
                    madeQty: item.qty,
                    leftoverQty: item.qty,
                    unit: item.unit,
                    wasteReason: .quality,
                    carryoverToNext: false
                ),
                labelID: item.labelID,
                recordedBy: "fridge-inspection"
            )
            changedCount += 1
        }

        fridgeInspectionMissingCount = changedCount
        fridgeInspectionCompletedAt = completedAt
        latestLarderUseSummary = "点検完了 / 差異 \(changedCount)件"
        persistLabelOpsState()
        persistEvent(
            type: "fridge.inspection_completed",
            payload: "{\"missing\":\(changedCount),\"now_date\":\"\(nowDate)\"}"
        )
        return changedCount
    }

    @discardableResult
    func recordCloseLoop(
        madeQty: Double = 240,
        leftoverQty: Double = 40,
        wasteReason: WasteReason = .overmade,
        carryoverToNext: Bool = true
    ) -> CloseLoopSummary {
        guard canCommitCloseLoop(madeQty: madeQty, leftoverQty: leftoverQty) else {
            closeLoopLastAction = "締め入力を確認"
            persistEvent(
                type: "close.record_blocked",
                payload: "{\"reason\":\"invalid_quantity\",\"made\":\(numberString(madeQty)),\"leftover\":\(numberString(leftoverQty))}"
            )
            return closeLoopSummary ?? Self.emptyCloseLoopSummary
        }
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
        closeLoopCommitCount += 1
        closeLoopLastAction = "単品 \(closeLoopCommitCount)件を記録"
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
        if closeLoopCommitCount > 1 {
            persistEvent(
                type: "close.revised",
                payload: "{\"service_day_id\":\"\(service.id)\",\"revision\":\(closeLoopCommitCount)}"
            )
        }
        persistCloseOpsState()
        return summary
    }

    func canCommitCloseLoop(madeQty: Double, leftoverQty: Double) -> Bool {
        madeQty >= 0 && leftoverQty >= 0 && leftoverQty <= madeQty
    }

    @discardableResult
    func recordCloseBatch(_ records: [CloseTaskRecord]) -> CloseLoopSummary {
        guard canCommitCloseBatch(records) else {
            closeGateLastAction = "締め表の数量を確認"
            persistEvent(
                type: "close.batch_blocked",
                payload: "{\"reason\":\"invalid_quantity\",\"records\":\(records.count)}"
            )
            return closeLoopSummary ?? Self.emptyCloseLoopSummary
        }
        let signature = closeBatchCommitSignature(records)
        guard signature != closeBatchSignature else {
            closeGateLastAction = "締め表は記録済み"
            persistEvent(
                type: "close.batch_skipped",
                payload: "{\"reason\":\"duplicate_signature\",\"records\":\(records.count)}"
            )
            return closeLoopSummary ?? Self.emptyCloseLoopSummary
        }
        let summary = closeLoop(
            records: records,
            nextDayPlan: [(task: "task-nikiri", base: nikiriQuantity.total, unit: nikiriQuantity.unit)]
        )
        closeLoopSummary = summary
        closeBatchSignature = signature
        latestLearningWasteRecords = learningWasteRecords(
            records: records,
            serviceDate: service.date,
            covers: service.omakaseCovers
        )
        for record in records {
            wasteSequence += 1
            persistCloseRecord(record)
        }
        for carryover in summary.carryovers {
            persistCarryover(carryover, sequence: wasteSequence)
        }
        closeGateLastAction = "締め表 \(summary.records.count)件を記録"
        persistCloseOpsState()
        persistEvent(
            type: "close.batch_completed",
            payload: "{\"records\":\(records.count),\"learning_samples\":\(latestLearningWasteRecords.count),\"carryovers\":\(summary.carryovers.count)}"
        )
        return summary
    }

    private func canCommitCloseBatch(_ records: [CloseTaskRecord]) -> Bool {
        !records.isEmpty && records.allSatisfy { canCommitCloseLoop(madeQty: $0.madeQty, leftoverQty: $0.leftoverQty) }
    }

    private func closeBatchCommitSignature(_ records: [CloseTaskRecord]) -> String {
        records
            .sorted { $0.task < $1.task }
            .map {
                [
                    $0.task,
                    numberString($0.plannedQty),
                    numberString($0.madeQty),
                    numberString($0.leftoverQty),
                    $0.unit,
                    $0.wasteReason.rawValue,
                    $0.carryoverToNext ? "carryover" : "waste",
                ].joined(separator: ":")
            }
            .joined(separator: "|")
    }

    @discardableResult
    func recordDefaultCloseGateBatch() -> CloseLoopSummary {
        recordCloseBatch(Self.defaultCloseGateRecords(nikiriBase: nikiriQuantity.total, unit: nikiriQuantity.unit))
    }

    func toggleCloseNextDayPrepReservation(_ id: String) {
        guard let index = closeNextDayPrepReservations.firstIndex(where: { $0.id == id }) else {
            persistEvent(
                type: "close.nextday_prep_toggle_blocked",
                payload: "{\"reservation_id\":\"\(id)\",\"reason\":\"missing\"}"
            )
            return
        }
        closeNextDayPrepReservations[index].isReserved.toggle()
        persistCloseOpsState()
        persistEvent(
            type: "close.nextday_prep_toggled",
            payload: "{"
                + "\"reservation_id\":\"\(id)\","
                + "\"reserved\":\(closeNextDayPrepReservations[index].isReserved)"
                + "}"
        )
    }

    @discardableResult
    func completeCloseGate(now: String = "2026-06-11T23:12:00Z") -> CloseLoopSummary {
        guard let summary = closeLoopSummary else {
            closeGateLastAction = "締め表を記録してから完了"
            persistEvent(type: "close.gate_blocked", payload: "{\"reason\":\"summary_missing\"}")
            return CloseLoopSummary(records: [], carryovers: [], nextDayAdjustments: [])
        }
        guard closeGateCompletedAt == nil else {
            closeGateLastAction = "締めゲート完了済み"
            persistEvent(
                type: "close.gate_skipped",
                payload: "{\"reason\":\"already_completed\",\"completed_at\":\"\(closeGateCompletedAt ?? "")\"}"
            )
            return summary
        }
        closeGateCompletedAt = now
        closeGateLastAction = "締めゲート完了"
        persistCloseOpsState()
        persistEvent(
            type: "close.gate_completed",
            payload: "{"
                + "\"service_day_id\":\"\(service.id)\","
                + "\"completed_at\":\"\(now)\","
                + "\"records\":\(summary.records.count),"
                + "\"reserved_nextday\":\(closeNextDayPrepReservations.count(where: { $0.isReserved }))"
                + "}"
        )
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
            persistEvent(
                type: "reservation.preview_increase_blocked",
                payload: "{\"reservation_id\":\"\(id)\",\"reason\":\"missing\",\"added_covers\":\(max(0, addedCovers))}"
            )
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
        reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
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
            persistEvent(
                type: "reservation.preview_cancel_blocked",
                payload: "{\"reservation_id\":\"\(id)\",\"reason\":\"missing\"}"
            )
            return unchanged
        }

        let cancelled = service.reservations.remove(at: index)
        recalculateCoversFromReservations()
        try? database?.softDelete(.reservation, id: cancelled.id, tenantID: tenantID)
        persistServiceCover()
        let diff = reservationDiff(previous: previous, current: reservationSnapshots())
        reservationDiffSummary = diff
        reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
        persistReservationDiff(diff, kind: "cancel")
        if reservationPlanDiff?.reduced.contains(where: \.carryoverCandidate) == true {
            persistEvent(
                type: "reservation.carryover_candidate",
                payload: "{\"reservation_id\":\"\(cancelled.id)\",\"cancelled_covers\":\(cancelled.covers)}"
            )
        }
        queueReservationTodayPrepImpact(diff, sourceLabel: "予約取消")
        return diff
    }

    @discardableResult
    func previewMixedReservationChange(cancelledID: String, addedReservation: ManualReservation) -> ReservationDiffSummary {
        let previous = reservationSnapshots()
        let previousCovers = service.omakaseCovers
        if let index = service.reservations.firstIndex(where: { $0.id == cancelledID }) {
            let cancelled = service.reservations.remove(at: index)
            try? database?.softDelete(.reservation, id: cancelled.id, tenantID: tenantID)
        }
        service.reservations.append(addedReservation)
        persistReservation(addedReservation)
        recalculateCoversFromReservations()
        persistServiceCover()

        let diff = reservationDiff(previous: previous, current: reservationSnapshots())
        reservationDiffSummary = diff
        reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
        persistReservationDiff(diff, kind: "mixed")
        if reservationPlanDiff?.reduced.contains(where: \.carryoverCandidate) == true {
            persistEvent(
                type: "reservation.carryover_candidate",
                payload: "{\"kind\":\"mixed\",\"cancelled_covers\":\(diff.cancelledCovers)}"
            )
        }
        queueReservationTodayPrepImpact(diff, sourceLabel: "予約差分")
        return diff
    }

    @discardableResult
    func syncReservationHubSources() -> ReservationDiffSummary {
        let diff = replayConnectorReservation(SourceReservationEvent(
            id: "source-tablecheck-suzuki-1800",
            provider: .tablecheck,
            externalID: "suzuki-1800",
            visitTime: "18:00",
            covers: 4,
            course: catalog.courseName,
            partyName: "鈴木 様",
            status: "confirmed"
        ))
        persistReservationHubState()
        return diff
    }

    func assignReservationHubCourse(_ reservationID: String, courseKey: String = "omakase") {
        guard service.reservations.contains(where: { $0.id == reservationID }) else {
            persistEvent(
                type: "reservation.course_assignment_blocked",
                payload: "{\"reservation_id\":\"\(reservationID)\",\"reason\":\"missing\",\"course_key\":\"\(courseKey)\"}"
            )
            return
        }
        if reservationHubAssignedCourses[reservationID] == courseKey {
            persistEvent(
                type: "reservation.course_assignment_skipped",
                payload: "{\"reservation_id\":\"\(reservationID)\",\"reason\":\"already_assigned\",\"course_key\":\"\(courseKey)\"}"
            )
            return
        }

        reservationHubAssignedCourses[reservationID] = courseKey
        persistReservationHubState()
        if let index = service.reservations.firstIndex(where: { $0.id == reservationID }) {
            service.reservations[index].note = "コース割当済み・\(reservationHubCourseDisplayName(courseKey))"
            persistReservation(service.reservations[index])
        }
        persistEvent(
            type: "reservation.course_assigned",
            payload: "{\"reservation_id\":\"\(reservationID)\",\"course_key\":\"\(courseKey)\"}"
        )
    }

    @discardableResult
    func mergeReservationHubDuplicate() -> ReservationDiffSummary {
        if reservationHubDuplicateDecision == "merged" {
            persistEvent(
                type: "reservation.duplicate_merge_skipped",
                payload: "{\"reservation_id\":\"reservation-tablecheck-suzuki-1800\",\"reason\":\"already_merged\"}"
            )
            return reservationDiffSummary ?? unchangedReservationDiff()
        }

        reservationHubDuplicateDecision = "merged"
        reservationHubAssignedCourses["reservation-tablecheck-suzuki-1800"] = nil
        let diff = previewMixedReservationChange(
            cancelledID: "reservation-tablecheck-suzuki-1800",
            addedReservation: ManualReservation(
                id: "reservation-direct-takahashi-1830",
                visitTime: "18:30",
                partyName: "高橋 様",
                note: "Direct・アレルギー：甲殻類（参考）",
                covers: 3
            )
        )
        persistReservationHubState()
        return diff
    }

    func keepReservationHubDuplicateSeparate() {
        if reservationHubDuplicateDecision == "kept_separate" {
            persistEvent(
                type: "reservation.duplicate_keep_skipped",
                payload: "{\"reservation_id\":\"reservation-tablecheck-suzuki-1800\",\"reason\":\"already_kept\"}"
            )
            return
        }

        reservationHubDuplicateDecision = "kept_separate"
        persistReservationHubState()
        persistEvent(
            type: "reservation.duplicate_kept",
            payload: "{\"reservation_id\":\"reservation-tablecheck-suzuki-1800\",\"decision\":\"kept_separate\"}"
        )
    }

    @discardableResult
    func applyReservationHubToPrep() -> PlanDiff {
        guard reservationHubCanApplyToPrep else {
            persistEvent(
                type: "reservation.apply_blocked",
                payload: "{"
                    + "\"unassigned_covers\":\(reservationHubUnassignedCovers),"
                    + "\"duplicate_review\":\(reservationHubNeedsDuplicateReview)"
                    + "}"
            )
            return reservationPlanDiff ?? PlanDiff()
        }
        let signature = reservationHubApplySignature()
        guard signature != reservationHubAppliedSignature else {
            persistEvent(
                type: "reservation.apply_skipped",
                payload: "{\"reason\":\"duplicate_signature\",\"service_day_id\":\"\(service.id)\",\"covers\":\(service.omakaseCovers)}"
            )
            return reservationPlanDiff ?? PlanDiff()
        }
        generateBoardFromService()
        if reservationPlanDiff == nil {
            reservationPlanDiff = planDiffForReservationDiff(
                reservationDiffSummary ?? reservationDiff(previous: reservationSnapshots(), current: reservationSnapshots()),
                previousCovers: service.omakaseCovers
            )
        }
        reservationHubApplyCount += 1
        reservationHubAppliedAt = "\(service.date)T17:12:00Z"
        reservationHubAppliedSignature = signature
        persistReservationHubState()
        persistEvent(
            type: "reservation.applied_to_prep",
            payload: "{\"service_day_id\":\"\(service.id)\",\"covers\":\(service.omakaseCovers)}"
        )
        queueReservationTodayPrepImpact(reservationDiffSummary, sourceLabel: "予約ハブ")
        return reservationPlanDiff ?? PlanDiff()
    }

    var reservationHubUnassignedCovers: Int {
        service.reservations
            .filter { reservationHubNeedsCourseAssignment($0) }
            .reduce(0) { $0 + $1.covers }
    }

    var reservationHubNeedsDuplicateReview: Bool {
        service.reservations.contains { $0.id == "reservation-tablecheck-suzuki-1800" }
            && reservationHubDuplicateDecision == nil
    }

    var reservationHubCanApplyToPrep: Bool {
        reservationHubUnassignedCovers == 0 && !reservationHubNeedsDuplicateReview
    }

    func reservationHubNeedsCourseAssignment(_ reservation: ManualReservation) -> Bool {
        reservation.id.contains("tablecheck") && reservationHubAssignedCourses[reservation.id] == nil
    }

    func reservationHubCourseDisplayName(_ courseKey: String) -> String {
        switch courseKey {
        case "omakase":
            catalog.courseName
        case "special":
            "特別おまかせ"
        default:
            catalog.courseName
        }
    }

    private func reservationHubApplySignature() -> String {
        let reservations = service.reservations
            .sorted { $0.id < $1.id }
            .map { "\($0.id):\($0.visitTime):\($0.covers)" }
            .joined(separator: "|")
        let assignments = reservationHubAssignedCourses
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }
            .joined(separator: "|")
        return [
            service.id,
            String(service.omakaseCovers),
            reservationHubDuplicateDecision ?? "unreviewed",
            reservations,
            assignments,
        ].joined(separator: "#")
    }

    private func serviceBoardSignature() -> String {
        [
            service.id,
            service.date,
            service.periodCode,
            service.openTime,
            String(service.omakaseCovers),
            String(service.otherCovers),
            reservationListSignature(),
            catalogTaskSignature(),
            completed.sorted().joined(separator: ","),
        ].joined(separator: "#")
    }

    private func catalogSaveSignature() -> String {
        [
            catalog.id,
            catalog.courseName,
            catalog.selectedTaskID,
            catalogTaskSignature(),
            service.id,
            service.openTime,
            String(service.omakaseCovers),
        ].joined(separator: "#")
    }

    private func catalogPreviewSignature() -> String {
        [
            catalogSaveSignature(),
            serviceBoardSignature(),
        ].joined(separator: "#")
    }

    private func simulationApplySignature() -> String {
        [
            serviceBoardSignature(),
            String(simulationPeriodDays),
            String(simulationAdjustmentCount),
            "task-nikiri",
            "coeff:12",
        ].joined(separator: "#")
    }

    private func simulationAdjustmentSignature() -> String {
        [
            service.id,
            String(simulationPeriodDays),
            simulationDateRange,
            simulation.items.map { "\($0.id):\(String(describing: $0.outcome))" }.joined(separator: ","),
        ].joined(separator: "#")
    }

    private func servicePeriodSignature(_ period: DailyServicePeriod) -> String {
        [
            period.id,
            period.label,
            period.openTime,
            service.id,
        ].joined(separator: "#")
    }

    private var currentServicePeriod: DailyServicePeriod? {
        service.periods.first { $0.id == service.selectedPeriodID }
    }

    private func refreshServicePeriodSelectionGuard() {
        guard let period = currentServicePeriod,
              service.openTime == period.openTime,
              service.period == period.label
        else {
            servicePeriodSelectedSignature = nil
            return
        }
        servicePeriodSelectedSignature = servicePeriodSignature(period)
    }

    private func etaInputSignature(now: String, remainingDurationsMin: [Int]) -> String {
        [
            service.id,
            service.openTime,
            now,
            remainingDurationsMin.map(String.init).joined(separator: ","),
        ].joined(separator: "#")
    }

    private func invalidETAInputReason(now: String, remainingDurationsMin: [Int]) -> String? {
        if !isValidOpenTime(now) {
            return "invalid_time"
        }
        if remainingDurationsMin.isEmpty {
            return "empty_remaining"
        }
        if remainingDurationsMin.contains(where: { $0 < 0 || $0 > 240 }) {
            return "invalid_duration"
        }
        let total = remainingDurationsMin.reduce(0) { partial, duration in
            partial + duration
        }
        if total > 480 {
            return "duration_overflow"
        }
        return nil
    }

    private func dayrailPlanSignature() -> String {
        [
            service.id,
            service.date,
            service.openTime,
            catalogTaskSignature(),
        ].joined(separator: "#")
    }

    private func subrecipeAggregateSignature() -> String {
        [
            service.id,
            String(service.omakaseCovers),
            String(service.otherCovers),
            catalogTaskSignature(),
            nikiriRollupStatus.rawValue,
        ].joined(separator: "#")
    }

    private func nikiriWasteSignature(madeQty: Double, leftoverQty: Double) -> String {
        [
            service.id,
            service.date,
            String(service.omakaseCovers),
            numberString(nikiriQuantity.total),
            numberString(madeQty),
            numberString(leftoverQty),
            "task-nikiri",
        ].joined(separator: "#")
    }

    private func nikiriCarryoverSignature(qty: Double) -> String {
        [
            service.id,
            service.date,
            numberString(qty),
            "task-nikiri",
            "ml",
        ].joined(separator: "#")
    }

    private func fridgeTemperatureSignature(valueC: Int, storageUnitID: String, loggedAt: String) -> String {
        [
            storageUnitID,
            String(valueC),
            loggedAt,
        ].joined(separator: "#")
    }

    private func nikiriLabelIssueSignature(_ label: PrepLabel) -> String {
        [
            label.id,
            label.taskInstanceID,
            numberString(label.madeQty),
            label.printedAt,
            label.storageUnitID ?? "",
        ].joined(separator: "#")
    }

    private func labelPrintTestSignature(labelID: String, printer: LabelPrinterDevice, now: String) -> String {
        [
            labelID,
            printer.id,
            printer.status,
            printer.paperSize,
            now,
        ].joined(separator: "#")
    }

    private func labelPDFExportSignature(labelID: String, path: String) -> String {
        [
            labelID,
            path,
            "PDF / A4",
        ].joined(separator: "#")
    }

    private func labelQROpenSignature(labelID: String) -> String {
        [
            labelID,
            "label_ops",
        ].joined(separator: "#")
    }

    private func labelOutputBlockedSignature(kind: String, labelID: String, now: String) -> String {
        [
            kind,
            labelID,
            labelPaperSize,
            now,
        ].joined(separator: "#")
    }

    private func skippedBlockedLabelPrintJob(kind: String, now: String) -> LabelPrintJob? {
        let requestedLabel = makeNikiriPrepLabel(madeQty: nil, printedAt: now, storageUnitID: nil)
        let signature = labelOutputBlockedSignature(kind: kind, labelID: requestedLabel.id, now: now)
        guard labelOutputBlockedSignatures.contains(signature), let latestLabelPrintJob else {
            return nil
        }
        let eventType = kind == "label_pdf" ? "label_pdf.blocked_skipped" : "label_print.blocked_skipped"
        persistEvent(
            type: eventType,
            payload: "{\"label_id\":\"\(requestedLabel.id)\",\"reason\":\"duplicate_missing_label\"}"
        )
        return latestLabelPrintJob
    }

    private func labelScanBlockedSignature(
        action: LabelScanAction,
        scanKind: String,
        labelID: String,
        status: String,
        reason: String
    ) -> String {
        [
            scanKind,
            labelID,
            status,
            reason,
            labelScanActionSignature(action),
        ].joined(separator: "#")
    }

    private func labelScanActionSignature(_ action: LabelScanAction) -> String {
        switch action {
        case let .remaining(qty):
            "remaining:\(numberString(qty))"
        case .used:
            "used"
        case let .wasted(qty, reason):
            "wasted:\(numberString(qty)):\(reason.rawValue)"
        }
    }

    private func todayPrepAssistApplySignature(_ proposal: TodayPrepAssistProposal) -> String {
        [
            proposal.id,
            todayPrepAssistRequestedAt,
            proposal.suggestedOperatorID ?? "",
            String(proposal.savesMinutes),
            String(todayPrepProgress.remainingMinutes),
        ].joined(separator: "#")
    }

    private func reservationListSignature() -> String {
        service.reservations
            .sorted { $0.id < $1.id }
            .map { "\($0.id):\($0.visitTime):\($0.covers):\($0.note)" }
            .joined(separator: "|")
    }

    private func catalogTaskSignature() -> String {
        allCatalogTasks
            .sorted { $0.id < $1.id }
            .map {
                [
                    $0.id,
                    $0.name,
                    numberString($0.coeffPerCover),
                    numberString($0.yieldPercent),
                    String($0.durationMin),
                    String($0.leadMinBeforeOpen),
                    $0.sectionName,
                    $0.instruction,
                ].joined(separator: ":")
            }
            .joined(separator: "|")
    }

    @discardableResult
    func summarizeMultistore(_ summaries: [StoreServiceSummary]) -> StoreServiceSummary {
        storeSummaries = summaries
        let summary = multistoreServiceSummary(summaries)
        multistoreSummary = summary
        persistDirectServiceOpsState()
        persistEvent(
            type: "multistore.summarized",
            payload: "{\"stores\":\(summaries.count),\"remaining_covers\":\(summary.remainingCovers),\"recommendation\":\"\(summary.recommendation)\"}"
        )
        return summary
    }
}

private extension BoardStore {
    static let defaultExportSummary = "CSV / JSON"

    static let focusStepIDs: Set<String> = ["sake", "tare", "rest"]

    static let emptyCloseLoopSummary = CloseLoopSummary(records: [], carryovers: [], nextDayAdjustments: [])

    static let defaultConnectorReviewEvents = [
        SourceReservationEvent(
            id: "source-tablecheck-suzuki-1800-review",
            provider: .tablecheck,
            externalID: "suzuki-1800",
            visitTime: "18:00",
            covers: 4,
            course: "本日のおまかせ・握り",
            partyName: "鈴木 様",
            status: "confirmed"
        ),
        SourceReservationEvent(
            id: "source-tablecheck-kimura-2030-review",
            provider: .tablecheck,
            externalID: "kimura-2030",
            visitTime: "20:30",
            covers: 2,
            course: "特別おまかせ",
            partyName: "木村 様",
            allergyNote: "貝類NG / 記念日 / 日本酒好き",
            vipRank: "gold"
        ),
    ]

    static let defaultCloseNextDayPrepReservations = [
        CloseNextDayPrepReservation(
            id: "nextday-tai-kombu",
            title: "真鯛の昆布締め",
            detail: "一晩・親方",
            timing: "今夜 着手",
            isReserved: true
        ),
        CloseNextDayPrepReservation(
            id: "nextday-akami-zuke",
            title: "赤身の漬け",
            detail: "半日・明朝でも可",
            timing: "明朝でも可",
            isReserved: false
        ),
        CloseNextDayPrepReservation(
            id: "nextday-dashi",
            title: "一番だしの仕込み準備",
            detail: "昆布を water out",
            timing: "今夜 着手",
            isReserved: true
        ),
    ]

    static func defaultCloseGateRecords(nikiriBase: Double, unit: String) -> [CloseTaskRecord] {
        [
            CloseTaskRecord(
                task: "task-nikiri",
                plannedQty: nikiriBase,
                madeQty: nikiriBase,
                leftoverQty: 65,
                unit: unit,
                wasteReason: .overmade,
                carryoverToNext: true
            ),
            CloseTaskRecord(
                task: "task-tai-kombu",
                plannedQty: 14,
                madeQty: 14,
                leftoverQty: 2,
                unit: "枚",
                wasteReason: .overmade,
                carryoverToNext: false
            ),
            CloseTaskRecord(
                task: "task-anago-tsume",
                plannedQty: 600,
                madeQty: 600,
                leftoverQty: 120,
                unit: "ml",
                wasteReason: .overmade,
                carryoverToNext: true
            ),
            CloseTaskRecord(
                task: "task-aemono",
                plannedQty: 24,
                madeQty: 24,
                leftoverQty: 3,
                unit: "食",
                wasteReason: .quality,
                carryoverToNext: false
            ),
        ]
    }

    static let defaultTodayPrepOperators = [
        TodayPrepOperator(id: "operator-oyakata", displayName: "親方", sectionName: "親方"),
        TodayPrepOperator(id: "operator-shari", displayName: "シャリ場", sectionName: "シャリ場"),
        TodayPrepOperator(id: "operator-garde", displayName: "ガルド", sectionName: "ガルド"),
    ]

    static let defaultLabelPrinters = [
        LabelPrinterDevice(
            id: "printer-brother-ql",
            name: "Brother QL-820NWB",
            detail: "62mm 連続ラベル ・ ネットワーク",
            connection: "network",
            paperSize: "62mm 連続",
            status: "connected",
            isDefault: true
        ),
        LabelPrinterDevice(
            id: "printer-star-mc",
            name: "スター精密 mC-Label3",
            detail: "Bluetooth ・ 予備",
            connection: "bluetooth",
            paperSize: "40 × 40mm",
            status: "offline",
            isDefault: false
        ),
        LabelPrinterDevice(
            id: "printer-pdf-a4",
            name: "PDF / A4",
            detail: "未接続時の汎用ラベル用紙",
            connection: "pdf",
            paperSize: "PDF / A4",
            status: "pdf",
            isDefault: false
        ),
    ]

    static let focusSteps = [
        TodayPrepStep(id: "sake", title: "酒・みりんを煮切る", durationMin: 10),
        TodayPrepStep(id: "tare", title: "たまり・濃口を合わせ ひと煮立ち", durationMin: 15),
        TodayPrepStep(id: "rest", title: "味見基準を確認し 冷暗所へ", durationMin: 15),
    ]

    static let todayPrepStepAssignments = [
        "sake": "operator-oyakata",
        "tare": "operator-oyakata",
        "rest": "operator-garde",
    ]

    static let todayPrepChecks = [
        TodayPrepCheck(
            id: "check-sake-aroma",
            stepID: "sake",
            title: "アルコール臭が丸い",
            detail: "湯気の角が取れている"
        ),
        TodayPrepCheck(
            id: "check-sake-volume",
            stepID: "sake",
            title: "量の減りすぎなし",
            detail: "煮詰めすぎず鍋肌が焦げていない"
        ),
        TodayPrepCheck(
            id: "check-tare-boil",
            stepID: "tare",
            title: "ひと煮立ちで火を落とす",
            detail: "沸いたらすぐ弱火にして香りを残す"
        ),
        TodayPrepCheck(
            id: "check-tare-clear",
            stepID: "tare",
            title: "濁りなし",
            detail: "表面の泡を取り、照りが残っている"
        ),
        TodayPrepCheck(
            id: "check-rest-taste",
            stepID: "rest",
            title: "味見基準OK",
            detail: "塩角と甘みが今日の基準に合う"
        ),
        TodayPrepCheck(
            id: "check-rest-label",
            stepID: "rest",
            title: "保管ラベル確認",
            detail: "品名・時刻・担当が読める"
        ),
    ]

    static let emptyTodayPrepProgress = TodayPrepProgress(
        steps: [],
        completedCount: 0,
        totalCount: 0,
        nextStepID: nil,
        nextStepTitle: nil,
        remainingMinutes: 0,
        eta: ETA(landing: "17:25", delayMin: 0, timeToOpenMin: 35, shortfallMin: 0, status: .onTrack)
    )

    private var focusTaskNodes: [TaskNode] {
        ["sake", "tare", "rest"].map { id in
            TaskNode(id: id, status: completed.contains(id) ? .done : .notStarted)
        }
    }

    static func todayPrepChecks(for stepID: String) -> [TodayPrepCheck] {
        todayPrepChecks.filter { $0.stepID == stepID }
    }

    static func boardTaskID(for sourceID: String) -> String {
        let aliases = [
            "rice": "shari",
            "kobachi": "sakizuke-kobachi",
        ]
        let prefixes = [
            "dish-sakizuke-",
            "dish-omakase-",
            "dish-wan-",
            "staff-shari-",
            "staff-chef-",
            "staff-garde-",
        ]
        for prefix in prefixes where sourceID.hasPrefix(prefix) {
            let rawID = String(sourceID.dropFirst(prefix.count))
            return aliases[rawID] ?? rawID
        }
        return aliases[sourceID] ?? sourceID
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

    private func catalogBoardPreviewText() -> String {
        let task = selectedCatalogTask
        let quantity = calcQty(task.engineTask, covers: service.omakaseCovers)
        let scheduled = schedule(
            task: task.engineTask,
            serviceDate: service.date,
            t0: service.openTime,
            closedDates: []
        )
        return "\(task.name) / \(Int(quantity.total))\(quantity.unit) / \(scheduled.start)着手"
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
        reservationImpactPlan(
            task: nikiriTaskWithRollupStatus,
            previousCovers: previousCovers,
            madeTotal: calcQty(nikiriTask, covers: previousCovers).total,
            diff: diff
        )
    }

    private var shouldQueueManualReservationImpact: Bool {
        serviceBoardGenerateCount > 0
            || completed.contains("tare")
            || completed.contains("rest")
            || completed.contains("nikiri")
            || !todayPrepStartedAt.isEmpty
            || !todayPrepActuals.isEmpty
            || latestPrepLabel != nil
    }

    private func recordManualReservationDiff(
        previous: [ReservationSnapshot],
        previousCovers: Int,
        kind: String,
        sourceLabel: String
    ) {
        let diff = reservationDiff(previous: previous, current: reservationSnapshots())
        reservationDiffSummary = diff
        reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
        persistReservationDiff(diff, kind: kind)
        guard shouldQueueManualReservationImpact else {
            return
        }
        queueReservationTodayPrepImpact(diff, sourceLabel: sourceLabel)
    }

    private func confirmedDirectCovers(excluding bookingID: String? = nil) -> Int {
        let directRows = (try? database?.rows(named: "direct_booking", tenantID: tenantID)) ?? []
        return directRows
            .filter { row in
                row.values["status"] == "confirmed" && row.id != bookingID
            }
            .reduce(0) { total, row in
                total + (Int(row.values["covers"] ?? "") ?? 0)
            }
    }

    private func isValidDirectBookingCovers(_ covers: Int) -> Bool {
        covers > 0
    }

    private func blockDirectBookingEvaluation(_ booking: DirectBooking, allottedCovers: Int) -> DirectBookingDecision {
        let blocked = DirectBookingDecision(
            status: .request,
            confirmedCovers: 0,
            waitlistCovers: 0,
            remainingAllotment: max(0, allottedCovers),
            reason: "invalid_covers"
        )
        latestDirectDecision = blocked
        persistDirectServiceOpsState()
        persistEvent(
            type: "direct_booking.evaluate_blocked",
            payload: "{\"booking_id\":\"\(booking.id)\",\"reason\":\"invalid_covers\",\"covers\":\(booking.covers)}"
        )
        return blocked
    }

    private func blockWaitlistPromotion(
        _ booking: DirectBooking,
        status: DirectBookingStatus,
        allottedCovers: Int,
        previousCovers: Int
    ) -> DirectWaitlistPromotion {
        let blocked = DirectWaitlistPromotion(
            id: "promotion-\(booking.id)",
            directBookingID: booking.id,
            status: status,
            promotedCovers: 0,
            remainingAllotment: max(0, allottedCovers - confirmedDirectCovers(excluding: booking.id)),
            reason: "status_\(status.rawValue)"
        )
        latestWaitlistPromotion = blocked
        persistDirectServiceOpsState()
        let diff = unchangedReservationDiff()
        reservationDiffSummary = diff
        reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
        persistEvent(
            type: "direct_waitlist.promotion_blocked",
            payload: "{\"booking_id\":\"\(booking.id)\",\"reason\":\"\(blocked.reason)\",\"remaining_allotment\":\(blocked.remainingAllotment)}"
        )
        return blocked
    }

    private func blockWaitlistPromotion(
        _ booking: DirectBooking,
        reason: String,
        allottedCovers: Int,
        previousCovers: Int
    ) -> DirectWaitlistPromotion {
        let blocked = DirectWaitlistPromotion(
            id: "promotion-\(booking.id)",
            directBookingID: booking.id,
            status: .request,
            promotedCovers: 0,
            remainingAllotment: max(0, allottedCovers - confirmedDirectCovers(excluding: booking.id)),
            reason: reason
        )
        latestWaitlistPromotion = blocked
        persistDirectServiceOpsState()
        let diff = unchangedReservationDiff()
        reservationDiffSummary = diff
        reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
        persistEvent(
            type: "direct_waitlist.promotion_blocked",
            payload: "{\"booking_id\":\"\(booking.id)\",\"reason\":\"\(reason)\",\"remaining_allotment\":\(blocked.remainingAllotment)}"
        )
        return blocked
    }

    private func persistPromotedWaitlistDirectBooking(
        _ booking: DirectBooking,
        promotion: DirectWaitlistPromotion,
        previous: [ReservationSnapshot],
        previousCovers: Int
    ) {
        let confirmed = DirectBooking(
            id: booking.id,
            visitTime: booking.visitTime,
            covers: booking.covers,
            course: booking.course,
            guestName: booking.guestName,
            guestNote: booking.guestNote,
            status: .confirmed,
            stripeCheckoutID: booking.stripeCheckoutID
        )
        latestDirectBooking = confirmed
        persistDirectBooking(confirmed)
        persistWaitlistStatus(bookingID: booking.id, status: "confirmed")
        persistDirectServiceOpsState()
        applyNormalizedReservation(normalizeDirectBooking(confirmed))
        persistServiceCover()
        let diff = reservationDiff(previous: previous, current: reservationSnapshots())
        reservationDiffSummary = diff
        reservationPlanDiff = planDiffForReservationDiff(diff, previousCovers: previousCovers)
        persistReservationDiff(diff, kind: "direct_waitlist")
        persistEvent(
            type: "direct_waitlist.promoted",
            payload: "{\"booking_id\":\"\(booking.id)\",\"covers\":\(promotion.promotedCovers),\"remaining_allotment\":\(promotion.remainingAllotment)}"
        )
        queueReservationTodayPrepImpact(diff, sourceLabel: "Direct待機")
    }

    private func directBookingStatus(_ bookingID: String) -> DirectBookingStatus? {
        currentDirectBooking(id: bookingID)?.status
    }

    private func currentDirectBooking(id bookingID: String) -> DirectBooking? {
        let directRows = (try? database?.rows(named: "direct_booking", tenantID: tenantID)) ?? []
        guard let row = directRows.first(where: { $0.id == bookingID }) else {
            return latestDirectBooking?.id == bookingID ? latestDirectBooking : nil
        }
        guard let statusValue = row.values["status"], let status = DirectBookingStatus(rawValue: statusValue) else {
            return latestDirectBooking?.id == bookingID ? latestDirectBooking : nil
        }
        return DirectBooking(
            id: row.id,
            visitTime: row.values["visit_time"] ?? service.openTime,
            covers: Int(row.values["covers"] ?? "") ?? 0,
            course: row.values["course_text"] ?? catalog.courseName,
            guestName: "Direct guest",
            guestNote: row.values["guest_note"] ?? nil,
            status: status,
            stripeCheckoutID: row.values["stripe_checkout_id"] ?? nil
        )
    }

    private func unchangedReservationDiff() -> ReservationDiffSummary {
        let snapshots = reservationSnapshots()
        return reservationDiff(previous: snapshots, current: snapshots)
    }

    private func syncNikiriRollup() {
        if nikiriRollupStatus == .done {
            completed.insert("nikiri")
            todayPrepCompletedBy["nikiri"] = todayPrepCompletedBy["rest"] ?? selectedTodayPrepOperator.displayName
            todayPrepCheckedAt["nikiri"] = todayPrepCheckedAt["rest"]
        } else {
            completed.remove("nikiri")
            todayPrepCompletedBy["nikiri"] = nil
            todayPrepCheckedAt["nikiri"] = nil
        }
    }

    private func refreshTodayPrepProgress(now: String = "17:25") {
        todayPrepProgress = Engine.todayPrepProgress(
            steps: Self.focusSteps,
            completedIDs: completed,
            now: now,
            t0: service.openTime
        )
    }

    private var selectedTodayPrepOperator: TodayPrepOperator {
        todayPrepOperators.first { $0.id == selectedTodayPrepOperatorID } ?? Self.defaultTodayPrepOperators[0]
    }

    private var selectedLabelPrinter: LabelPrinterDevice {
        labelPrinterDevices.first { $0.id == selectedLabelPrinterID } ?? Self.defaultLabelPrinters[0]
    }

    private func labelPDFPath(labelID: String) -> String {
        "/tmp/prepflow-\(labelID)-labels.pdf"
    }

    private func larderUseIntentKey(requiredQty: Double, nowDate: String) -> String {
        "task-nikiri|\(nowDate)|\(numberString(requiredQty))"
    }

    private func isOfflineFlushReplacement(existing: ServiceSyncEvent, replacement: ServiceSyncEvent) -> Bool {
        guard existing.offlineSequence != nil, replacement.offlineSequence == nil else {
            return false
        }
        var cleared = existing
        cleared.offlineSequence = nil
        return cleared == replacement
    }

    private func isValidServiceSyncEvent(_ event: ServiceSyncEvent) -> Bool {
        !event.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !event.occurredAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && event.covers >= 0
            && event.offlineSequence.map { $0 > 0 } ?? true
    }

    private func currentServiceSyncState(elapsedMinutes: Int, serviceMinutes: Int) -> ServiceSyncState {
        if let serviceSyncState {
            return serviceSyncState
        }
        return Engine.serviceSyncState(
            plannedCovers: service.omakaseCovers,
            events: serviceSyncEvents,
            elapsedMinutes: elapsedMinutes,
            serviceMinutes: serviceMinutes
        )
    }

    private func makeNikiriPrepLabel(
        madeQty: Double?,
        printedAt: String,
        storageUnitID: String?
    ) -> PrepLabel {
        issuePrepLabel(
            task: nikiriTask,
            taskInstanceID: "instance-task-nikiri",
            madeQty: madeQty ?? nikiriQuantity.total,
            printedAt: printedAt,
            storageUnitID: storageUnitID ?? storageColdID
        )
    }

    private func blockNikiriLabelIssueIfNeeded(_ label: PrepLabel, now: String) -> Bool {
        guard todayPrepProgress.isComplete else {
            handleTodayPrepAggregateBoardTap(sourceID: label.id, sourceKind: "label", now: now)
            todayPrepCompletionBlockReason = "ラベル発行不可: \(lineGateBlockDetail(lineGateStatus))"
            persistEvent(
                type: "label.issue_blocked",
                payload: "{\"label_id\":\"\(label.id)\",\"reason\":\"prep_incomplete\",\"next_step_id\":\"\(todayPrepProgress.nextStepID ?? "")\"}"
            )
            return true
        }
        let status = lineGateStatus
        guard status.canOpen else {
            lineGateLastAction = lineGateBlockDetail(status)
            todayPrepCompletionBlockReason = "ラベル発行不可: \(lineGateLastAction)"
            persistBlockedLabelIssue(label, status: status)
            return true
        }
        return false
    }

    private func persistBlockedLabelIssue(_ label: PrepLabel, status: LineGateStatus) {
        persistEvent(
            type: "label.issue_blocked",
            payload: "{"
                + "\"label_id\":\"\(label.id)\","
                + "\"reason\":\"line_gate\","
                + "\"remaining\":\(status.totalCount - status.completedCount),"
                + "\"impacts\":\(status.unresolvedImpactCount),"
                + "\"rechecks\":\(status.recheckCount),"
                + "\"label_reprint\":\(status.labelReprintRequired)"
                + "}"
        )
    }

    private func persistIssuedNikiriPrepLabel(_ label: PrepLabel, printedAt: String) {
        persistTaskInstances()
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
        nikiriLabelIssuedSignatures.insert(nikiriLabelIssueSignature(label))
        persistEvent(type: "label.printed", payload: "{\"label_id\":\"\(label.id)\",\"task_id\":\"\(label.prepTaskID)\",\"qty\":\(numberString(label.madeQty))}")
        latestLabelPrintJob = LabelPrintJob(
            labelID: label.id,
            destination: selectedLabelPrinter.status == "connected" ? selectedLabelPrinter.name : "PDF / A4",
            paperSize: selectedLabelPrinter.status == "connected" ? selectedLabelPrinter.paperSize : "PDF / A4",
            outputPath: selectedLabelPrinter.status == "connected" ? nil : labelPDFPath(labelID: label.id),
            status: selectedLabelPrinter.status == "connected" ? "queued" : "pdf_ready",
            createdAt: printedAt
        )
        latestLabelPDFPath = latestLabelPrintJob?.outputPath
        persistLabelOpsState()
    }

    private func existingNikiriLabelIssueBlockOrSkip(for requestedLabel: PrepLabel) -> PrepLabel? {
        guard let existingLabel = latestPrepLabel, existingLabel.id == requestedLabel.id else {
            return nil
        }

        if existingLabel.status != .active {
            persistEvent(
                type: "label.issue_blocked",
                payload: "{\"label_id\":\"\(existingLabel.id)\",\"reason\":\"existing_label_status\",\"status\":\"\(existingLabel.status.rawValue)\"}"
            )
            return existingLabel
        }

        let signature = nikiriLabelIssueSignature(requestedLabel)
        guard nikiriLabelIssuedSignatures.contains(signature) else {
            return nil
        }

        latestLabelPrintJob = LabelPrintJob(
            labelID: existingLabel.id,
            destination: selectedLabelPrinter.status == "connected" ? selectedLabelPrinter.name : "PDF / A4",
            paperSize: selectedLabelPrinter.status == "connected" ? selectedLabelPrinter.paperSize : "PDF / A4",
            outputPath: selectedLabelPrinter.status == "connected" ? nil : labelPDFPath(labelID: existingLabel.id),
            status: selectedLabelPrinter.status == "connected" ? "queued" : "pdf_ready",
            createdAt: existingLabel.printedAt
        )
        latestLabelPDFPath = latestLabelPrintJob?.outputPath
        persistEvent(
            type: "label.issue_skipped",
            payload: "{\"label_id\":\"\(existingLabel.id)\",\"reason\":\"duplicate_signature\",\"qty\":\(numberString(existingLabel.madeQty))}"
        )
        return existingLabel
    }

    private func completeTodayPrepChecks(for stepID: String) {
        for check in Self.todayPrepChecks(for: stepID) {
            todayPrepCompletedCheckIDs.insert(check.id)
        }
        for check in todayPrepDynamicChecks where check.stepID == stepID {
            todayPrepCompletedCheckIDs.insert(check.id)
        }
    }

    private func clearTodayPrepChecks(for stepID: String) {
        todayPrepCompletedCheckIDs = todayPrepCompletedCheckIDs.filter { checkID in
            todayPrepCheckStepID(checkID) != stepID
        }
    }

    private func clearTodayPrepOperationalState(for stepID: String) {
        clearTodayPrepChecks(for: stepID)
        todayPrepStartedAt[stepID] = nil
        todayPrepCheckedAt[stepID] = nil
        todayPrepActuals[stepID] = nil
        todayPrepManualActualMinutes[stepID] = nil
        if let hold = todayPrepActiveHold, hold.stepID == stepID {
            todayPrepActiveHold = nil
        }
        todayPrepHoldHistory.removeAll { $0.stepID == stepID }
    }

    private func upsertTodayPrepDynamicCheck(_ check: TodayPrepCheck) {
        if let index = todayPrepDynamicChecks.firstIndex(where: { $0.id == check.id }) {
            todayPrepDynamicChecks[index] = check
        } else {
            todayPrepDynamicChecks.append(check)
        }
    }

    private func todayPrepCheckStepID(_ checkID: String) -> String? {
        todayPrepCheck(checkID)?.stepID
    }

    private func todayPrepCheck(_ checkID: String) -> TodayPrepCheck? {
        if let check = Self.todayPrepChecks.first(where: { $0.id == checkID }) {
            return check
        }
        return todayPrepDynamicChecks.first { $0.id == checkID }
    }

    private func recordTodayPrepCompletion(_ id: String, checkedAt: String) {
        let completion = Engine.todayPrepCompletion(
            taskID: id,
            completedBy: selectedTodayPrepOperator.displayName,
            checkedAt: checkedAt,
            previousCompletedIDs: completed
        )
        completed = Set(completion.completedIDs)
        todayPrepCompletedBy[id] = completion.completedBy
        todayPrepCheckedAt[id] = completion.checkedAt
        if let step = Self.focusSteps.first(where: { $0.id == id }), let startedAt = todayPrepStartedAt[id] {
            let measured = Engine.todayPrepActual(
                taskID: id,
                plannedMinutes: step.durationMin,
                startedAt: startedAt,
                checkedAt: checkedAt
            )
            if let manualActual = todayPrepManualActualMinutes[id] {
                todayPrepActuals[id] = Engine.todayPrepActualOverride(
                    taskID: id,
                    plannedMinutes: step.durationMin,
                    actualMinutes: manualActual,
                    startedAt: startedAt,
                    checkedAt: checkedAt
                )
            } else {
                todayPrepActuals[id] = measured
            }
        }
    }

    private func guidanceBody(for stepID: String?) -> String {
        switch stepID {
        case "sake":
            "鍋を中火にかけ、酒とみりんの香りが丸くなるまで煮切ります。"
        case "tare":
            "たまりと濃口を合わせ、沸いたらすぐ火を落として香りを残します。"
        case "rest":
            "味見基準を確認し、粗熱が抜けたら冷暗所へ移します。"
        default:
            "煮切りは完了です。ライン点検へ進めます。"
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

    private func persistLabelModeSeed() {
        let storageValues: [String: String?] = [
            "id": storageColdID,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "name": "冷蔵2",
            "kind": "fridge",
            "temp_min": "0",
            "temp_max": "4",
            "qr_token": "prepflow://storage/\(storageColdID)",
        ]
        try? database?.create(named: "storage_unit", values: storageValues)
        try? database?.update(named: "storage_unit", id: storageColdID, tenantID: tenantID, values: storageValues)
        for printer in labelPrinterDevices {
            persistPrinterSeedIfNeeded(printer)
        }
    }

    private func persistSetting(id: String, key: String, value: String) {
        let values: [String: String?] = [
            "id": id,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "key": key,
            "value": value,
        ]
        try? database?.create(.settings, values: values)
        try? database?.update(.settings, id: id, tenantID: tenantID, values: values)
    }

    private func persistSelectedCatalogTask() {
        persistSetting(
            id: "setting-catalog-selected-task",
            key: "catalog.selected_task_id",
            value: catalog.selectedTaskID
        )
    }

    private func persistCatalogBoardState() {
        guard let value = catalogBoardStateValue() else {
            persistEvent(type: "catalog.state_persist_blocked", payload: "{\"reason\":\"json_encoding\"}")
            return
        }
        persistSetting(id: "setting-catalog-board-state", key: "catalog.board_state", value: value)
    }

    private func catalogBoardStateValue() -> String? {
        jsonString([
            "save_count": catalogSaveCount,
            "last_saved_at": catalogLastSavedAt ?? "",
            "board_preview_summary": catalogBoardPreviewSummary ?? "",
            "saved_signature": catalogSavedSignature ?? "",
            "previewed_signature": catalogPreviewedSignature ?? "",
        ])
    }

    private func restoreCatalogBoardState() {
        guard let object = settingsJSONObject(id: "setting-catalog-board-state") else {
            return
        }
        catalogSaveCount = settingInt(object, "save_count", defaultValue: catalogSaveCount)
        catalogLastSavedAt = nonEmptySettingString(object["last_saved_at"])
        catalogBoardPreviewSummary = nonEmptySettingString(object["board_preview_summary"])
        catalogSavedSignature = nonEmptySettingString(object["saved_signature"])
        catalogPreviewedSignature = nonEmptySettingString(object["previewed_signature"])
    }

    private func persistSimulationState() {
        guard let value = simulationStateValue() else {
            persistEvent(type: "simulation.state_persist_blocked", payload: "{\"reason\":\"json_encoding\"}")
            return
        }
        persistSetting(id: "setting-simulation-state", key: "simulation.state", value: value)
    }

    private func persistBoardGenerationState() {
        guard let value = boardGenerationStateValue() else {
            persistEvent(type: "board.state_persist_blocked", payload: "{\"reason\":\"json_encoding\"}")
            return
        }
        persistSetting(id: "setting-board-generated-state", key: "board.generated_state", value: value)
    }

    private func simulationStateValue() -> String? {
        let items = simulation.items.map { item in
            [
                "id": item.id,
                "recommended": numberString(item.recommended),
                "delta_label": item.deltaLabel,
            ]
        }
        return jsonString([
            "period_days": simulationPeriodDays,
            "date_range": simulationDateRange,
            "adjustment_count": simulationAdjustmentCount,
            "last_adjustment_summary": simulationLastAdjustmentSummary ?? "",
            "applied_count": simulationAppliedCount,
            "applied_at": simulationAppliedAt ?? "",
            "board_impact_summary": simulationBoardImpactSummary ?? "",
            "loss_saving_yen": simulation.lossSavingYen,
            "hit_rate_percent": simulation.hitRatePercent,
            "stockout_risks": simulation.stockoutRisks,
            "items": items,
        ])
    }

    private func boardGenerationStateValue() -> String? {
        jsonString([
            "generate_count": serviceBoardGenerateCount,
            "generated_at": serviceBoardGeneratedAt ?? "",
            "preview_summary": serviceBoardPreviewSummary ?? "",
            "signature": serviceBoardGeneratedSignature ?? "",
        ])
    }

    private func restoreSimulationState() {
        guard let object = settingsJSONObject(id: "setting-simulation-state") else {
            return
        }
        simulationPeriodDays = settingInt(object, "period_days", defaultValue: simulationPeriodDays)
        simulationDateRange = object["date_range"] as? String ?? simulationDateRange
        simulationAdjustmentCount = settingInt(object, "adjustment_count", defaultValue: simulationAdjustmentCount)
        simulationLastAdjustmentSummary = nonEmptySettingString(object["last_adjustment_summary"])
        simulationAppliedCount = settingInt(object, "applied_count", defaultValue: simulationAppliedCount)
        simulationAppliedAt = nonEmptySettingString(object["applied_at"])
        simulationBoardImpactSummary = nonEmptySettingString(object["board_impact_summary"])
        simulation.lossSavingYen = settingInt(object, "loss_saving_yen", defaultValue: simulation.lossSavingYen)
        simulation.hitRatePercent = settingInt(object, "hit_rate_percent", defaultValue: simulation.hitRatePercent)
        simulation.stockoutRisks = settingInt(object, "stockout_risks", defaultValue: simulation.stockoutRisks)
        restoreSimulationItems(object["items"] as? [[String: String]] ?? [])
        simulationAdjustedSignature = simulationAdjustmentCount > 0 ? simulationAdjustmentSignature() : nil
        simulationAppliedSignature = simulationAppliedCount > 0 ? simulationApplySignature() : nil
    }

    private func restoreBoardGenerationState() {
        guard let object = settingsJSONObject(id: "setting-board-generated-state") else {
            return
        }
        serviceBoardGenerateCount = settingInt(object, "generate_count", defaultValue: serviceBoardGenerateCount)
        serviceBoardGeneratedAt = nonEmptySettingString(object["generated_at"])
        serviceBoardPreviewSummary = nonEmptySettingString(object["preview_summary"])
        let savedSignature = nonEmptySettingString(object["signature"])
        serviceBoardGeneratedSignature = savedSignature ?? (serviceBoardGenerateCount > 0 ? serviceBoardSignature() : nil)
    }

    private func persistETAState(now: String, remainingDurationsMin: [Int], signature: String) {
        guard let etaOverride,
              let value = jsonString([
                  "now": now,
                  "remaining_durations_min": remainingDurationsMin,
                  "landing": etaOverride.landing,
                  "delay_min": etaOverride.delayMin,
                  "time_to_open_min": etaOverride.timeToOpenMin,
                  "shortfall_min": etaOverride.shortfallMin,
                  "status": etaStatusValue(etaOverride.status),
                  "signature": signature,
              ])
        else {
            persistEvent(type: "eta.state_persist_blocked", payload: "{\"reason\":\"json_encoding\"}")
            return
        }
        persistSetting(id: "setting-eta-last", key: "eta.last", value: value)
    }

    private func restoreDailyOpsState() {
        restoreETAState()
        restoreDayrailItems()
        restoreSubrecipeAggregate()
    }

    private func restoreETAState() {
        guard let object = settingsJSONObject(id: "setting-eta-last"),
              let now = nonEmptySettingString(object["now"]),
              let landing = nonEmptySettingString(object["landing"]),
              isValidOpenTime(now),
              isValidOpenTime(landing)
        else {
            return
        }

        let remainingDurations = object["remaining_durations_min"] as? [Int] ?? []
        if !remainingDurations.isEmpty {
            etaOverride = etaProjection(now: now, t0: service.openTime, remainingDurationsMin: remainingDurations)
            etaRecordedSignature = nonEmptySettingString(object["signature"])
                ?? etaInputSignature(now: now, remainingDurationsMin: remainingDurations)
            return
        }

        etaOverride = restoredETAFromLegacySettings(object, now: now, landing: landing)
        etaRecordedSignature = nonEmptySettingString(object["signature"])
    }

    private func restoredETAFromLegacySettings(_ object: [String: Any], now: String, landing: String) -> ETA {
        let nowMinutes = hhmmMinutes(now) ?? 0
        let openMinutes = hhmmMinutes(service.openTime) ?? nowMinutes
        let landingMinutes = hhmmMinutes(landing) ?? nowMinutes
        let delayMin = settingInt(object, "delay_min", defaultValue: landingMinutes - openMinutes)
        let shortfallMin = settingInt(object, "shortfall_min", defaultValue: max(0, delayMin))
        return ETA(
            landing: landing,
            delayMin: delayMin,
            timeToOpenMin: settingInt(object, "time_to_open_min", defaultValue: openMinutes - nowMinutes),
            shortfallMin: shortfallMin,
            status: etaStatus(from: nonEmptySettingString(object["status"]), delayMin: delayMin)
        )
    }

    private func restoreDayrailItems() {
        guard let rows = try? database?.rows(named: "dayrail_item", tenantID: tenantID), !rows.isEmpty else {
            return
        }
        dayrailItems = rows
            .filter { $0.values["service_day_id"] == service.id }
            .compactMap(restoreDayrailItem)
            .sorted { $0.sort < $1.sort }
        if !dayrailItems.isEmpty {
            dayrailPlannedSignature = dayrailPlanSignature()
        }
    }

    private func restoreDayrailItem(_ row: DataRow) -> DayrailItem? {
        guard let kindValue = row.values["kind"],
              let kind = DayrailKind(rawValue: kindValue),
              let refID = row.values["ref_id"],
              let title = row.values["title"],
              let prepOffset = Int(row.values["prep_day_offset"] ?? ""),
              let start = row.values["start_at"],
              let finish = row.values["finish_at"],
              let status = taskStatusFromDB(row.values["status"]),
              let sort = Int(row.values["sort"] ?? "")
        else {
            return nil
        }
        return DayrailItem(
            id: row.id,
            kind: kind,
            refID: refID,
            title: title,
            prepDayOffset: prepOffset,
            start: start,
            finish: finish,
            status: status,
            sort: sort
        )
    }

    private func restoreSubrecipeAggregate() {
        guard let row = try? database?.rows(named: "subrecipe_aggregate", tenantID: tenantID)
            .first(where: { $0.values["service_day_id"] == service.id && $0.values["prep_task_id"] == nikiriTask.id }),
            let totalCovers = Int(row.values["total_covers"] ?? ""),
            let totalQty = Double(row.values["total_qty"] ?? ""),
            let unit = row.values["unit"]
        else {
            return
        }
        let sources = row.values["sources"]?.split(separator: ",").map(String.init) ?? []
        let rawQty = restoredSubrecipeRawQty(sources: sources, fallback: totalQty)
        sharedPrepAggregate = AggregatedQuantity(
            task: row.values["prep_task_id"] ?? nikiriTask.id,
            totalCovers: totalCovers,
            quantity: Quantity(raw: rawQty, total: totalQty, unit: unit),
            sources: sources
        )
        subrecipeAggregatedSignature = subrecipeAggregateSignature()
    }

    private func restoredSubrecipeRawQty(sources: [String], fallback: Double) -> Double {
        let references = sources.compactMap { source -> (course: String, covers: Int)? in
            let parts = source.split(separator: ":")
            guard let course = parts.first,
                  let coversValue = parts.last,
                  let covers = Int(coversValue)
            else {
                return nil
            }
            return (String(course), covers)
        }
        guard !references.isEmpty else {
            return fallback
        }
        return aggregateSubrecipes(nikiriTask, references: references).quantity.raw
    }

    private func persistCloseOpsState() {
        guard let value = closeOpsStateValue() else {
            persistEvent(type: "close.state_persist_blocked", payload: "{\"reason\":\"json_encoding\"}")
            return
        }
        persistSetting(id: "setting-close-ops-state", key: "close.ops_state", value: value)
    }

    private func closeOpsStateValue() -> String? {
        jsonString([
            "summary": closeLoopSummaryValue(),
            "commit_count": closeLoopCommitCount,
            "last_action": closeLoopLastAction,
            "gate_completed_at": closeGateCompletedAt ?? "",
            "gate_last_action": closeGateLastAction,
            "batch_signature": closeBatchSignature ?? "",
            "next_day_reservations": closeNextDayPrepReservations.map { reservation in
                ["id": reservation.id, "is_reserved": reservation.isReserved ? "1" : "0"]
            },
        ])
    }

    private func closeLoopSummaryValue() -> [String: Any] {
        guard let summary = closeLoopSummary else {
            return [:]
        }
        return [
            "records": summary.records.map(closeRecordValue),
            "carryovers": summary.carryovers.map(carryoverValue),
            "next_day_adjustments": summary.nextDayAdjustments.map(nextDayAdjustmentValue),
        ]
    }

    private func restoreCloseOpsState() {
        guard let object = settingsJSONObject(id: "setting-close-ops-state") else {
            return
        }
        closeLoopCommitCount = settingInt(object, "commit_count", defaultValue: closeLoopCommitCount)
        closeLoopLastAction = nonEmptySettingString(object["last_action"]) ?? closeLoopLastAction
        closeGateCompletedAt = nonEmptySettingString(object["gate_completed_at"])
        closeGateLastAction = nonEmptySettingString(object["gate_last_action"]) ?? closeGateLastAction
        closeBatchSignature = nonEmptySettingString(object["batch_signature"])
        restoreCloseNextDayReservations(object["next_day_reservations"] as? [[String: String]] ?? [])
        restoreCloseLoopSummary(object["summary"] as? [String: Any])
    }

    private func restoreCloseLoopSummary(_ object: [String: Any]?) {
        guard let object else {
            return
        }
        let records = restoreCloseRecords(object["records"] as? [[String: String]] ?? [])
        let carryovers = restoreCarryovers(object["carryovers"] as? [[String: String]] ?? [])
        let adjustments = restoreNextDayAdjustments(object["next_day_adjustments"] as? [[String: String]] ?? [])
        guard !records.isEmpty || !carryovers.isEmpty || !adjustments.isEmpty else {
            return
        }
        closeLoopSummary = CloseLoopSummary(records: records, carryovers: carryovers, nextDayAdjustments: adjustments)
        latestLearningWasteRecords = learningWasteRecords(
            records: records,
            serviceDate: service.date,
            covers: service.omakaseCovers
        )
    }

    private func restoreCloseNextDayReservations(_ values: [[String: String]]) {
        let reservedByID = Dictionary(uniqueKeysWithValues: values.compactMap { value in
            value["id"].map { ($0, value["is_reserved"] == "1") }
        })
        closeNextDayPrepReservations = closeNextDayPrepReservations.map { reservation in
            var restored = reservation
            restored.isReserved = reservedByID[reservation.id] ?? reservation.isReserved
            return restored
        }
    }

    private func persistReservationHubState() {
        guard let value = reservationHubStateValue() else {
            persistEvent(type: "reservation.state_persist_blocked", payload: "{\"reason\":\"json_encoding\"}")
            return
        }
        persistSetting(id: "setting-reservation-hub-state", key: "reservation_hub.state", value: value)
    }

    private func reservationHubStateValue() -> String? {
        jsonString([
            "duplicate_decision": reservationHubDuplicateDecision ?? "",
            "assigned_courses": reservationHubAssignedCourses
                .sorted { $0.key < $1.key }
                .map { ["reservation_id": $0.key, "course_key": $0.value] },
            "apply_count": reservationHubApplyCount,
            "applied_at": reservationHubAppliedAt ?? "",
            "applied_signature": reservationHubAppliedSignature ?? "",
            "diff_added_covers": reservationDiffSummary?.addedCovers ?? 0,
            "diff_cancelled_covers": reservationDiffSummary?.cancelledCovers ?? 0,
            "diff_changed_ids": reservationDiffSummary?.changedReservationIDs ?? [],
        ])
    }

    private func restoreReservationHubState() {
        guard let object = settingsJSONObject(id: "setting-reservation-hub-state") else {
            return
        }
        reservationHubDuplicateDecision = nonEmptySettingString(object["duplicate_decision"])
        reservationHubApplyCount = settingInt(object, "apply_count", defaultValue: reservationHubApplyCount)
        reservationHubAppliedAt = nonEmptySettingString(object["applied_at"])
        reservationHubAppliedSignature = nonEmptySettingString(object["applied_signature"])
        restoreReservationHubAssignments(object["assigned_courses"] as? [[String: String]] ?? [])
        restoreReservationHubDiff(object)
    }

    private func restoreReservationHubAssignments(_ values: [[String: String]]) {
        reservationHubAssignedCourses = values.reduce(into: [:]) { partial, value in
            guard let reservationID = value["reservation_id"],
                  let courseKey = value["course_key"],
                  service.reservations.contains(where: { $0.id == reservationID })
            else {
                return
            }
            partial[reservationID] = courseKey
        }
    }

    private func restoreReservationHubDiff(_ object: [String: Any]) {
        let addedCovers = settingInt(object, "diff_added_covers", defaultValue: 0)
        let cancelledCovers = settingInt(object, "diff_cancelled_covers", defaultValue: 0)
        let changedIDs = object["diff_changed_ids"] as? [String] ?? []
        guard addedCovers > 0 || cancelledCovers > 0 || !changedIDs.isEmpty else {
            return
        }
        let diff = ReservationDiffSummary(
            addedCovers: addedCovers,
            cancelledCovers: cancelledCovers,
            changedReservationIDs: changedIDs
        )
        reservationDiffSummary = diff
        reservationPlanDiff = planDiffForReservationDiff(
            diff,
            previousCovers: max(0, service.omakaseCovers - addedCovers + cancelledCovers)
        )
    }

    private func restoreConnectorReviewState() {
        guard let rows = try? database?.rows(named: "source_event", tenantID: tenantID), !rows.isEmpty else {
            return
        }
        connectorPendingEvents = [:]
        connectorDiffReviewItems = []
        connectorReplayCount = 0

        for row in rows.sorted(by: catalogRowSort) {
            guard let event = restoreSourceReservationEvent(row),
                  isValidConnectorReservationEvent(event)
            else {
                continue
            }
            let normalized = normalizeReservationEvent(event)
            let reviewState = restoreSourceEventReviewState(row)
            if reviewState == "pending" {
                connectorPendingEvents[event.id] = event
            }
            if isTerminalConnectorReviewState(reviewState), reviewState != "rejected" {
                latestConnectorReservation = normalized
                connectorReplayCount += 1
            }
            upsertConnectorReviewItem(
                reviewItem(
                    for: event,
                    normalized: normalized,
                    state: connectorReviewDisplayState(reviewState)
                )
            )
        }

        guard !connectorDiffReviewItems.isEmpty else {
            return
        }
        connectorLastSyncSummary = "TableCheck 復元 \(connectorDiffReviewItems.count)件・承認待ち \(connectorPendingEvents.count)件"
    }

    private func restoreSourceReservationEvent(_ row: DataRow) -> SourceReservationEvent? {
        guard let source = row.values["source"],
              let provider = ConnectorProvider(rawValue: source),
              let payload = row.values["payload"],
              let object = serviceSyncPayloadObject(payload)
        else {
            return nil
        }
        let externalID = nonEmptySettingString(object["external_id"]) ?? row.values["external_id"] ?? row.id
        let reservationID = nonEmptySettingString(object["reservation_id"])
        let existingReservation = reservationID.flatMap { id in
            service.reservations.first { $0.id == id }
        }
        return SourceReservationEvent(
            id: row.id,
            provider: provider,
            externalID: externalID,
            visitTime: nonEmptySettingString(object["visit_time"]) ?? existingReservation?.visitTime ?? service.openTime,
            covers: serviceSyncPayloadInt(object, key: "covers") ?? existingReservation?.covers ?? 0,
            course: nonEmptySettingString(object["course"]) ?? catalog.courseName,
            partyName: nonEmptySettingString(object["party_name"]) ?? existingReservation?.partyName ?? "外部予約 \(externalID)",
            status: nonEmptySettingString(object["status"]) ?? "confirmed",
            allergyNote: nonEmptySettingString(object["allergy_note"]),
            vipRank: nonEmptySettingString(object["vip_rank"])
        )
    }

    private func restoreSourceEventReviewState(_ row: DataRow) -> String {
        guard let payload = row.values["payload"],
              let object = serviceSyncPayloadObject(payload)
        else {
            return sourceEventHasProcessedAt(row) ? "processed" : "pending"
        }
        return nonEmptySettingString(object["review_state"])
            ?? (sourceEventHasProcessedAt(row) ? "processed" : "pending")
    }

    private func sourceEventHasProcessedAt(_ row: DataRow) -> Bool {
        guard let processedAt = row.values["processed_at"] else {
            return false
        }
        let trimmed = processedAt.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "NULL"
    }

    private func persistLabelOpsState() {
        guard let value = labelOpsStateValue() else {
            persistEvent(type: "label.state_persist_blocked", payload: "{\"reason\":\"json_encoding\"}")
            return
        }
        persistSetting(id: "setting-label-ops-state", key: "label.ops_state", value: value)
    }

    private func labelOpsStateValue() -> String? {
        jsonString([
            "latest_label_id": latestPrepLabel?.id ?? "",
            "label_scan_last_action": labelScanLastAction,
            "latest_label_print_job": latestLabelPrintJobValue(),
            "latest_label_pdf_path": latestLabelPDFPath ?? "",
            "latest_qr_return_route": latestQRReturnRoute,
            "latest_larder_use_summary": latestLarderUseSummary,
            "fridge_temperature_c": fridgeTemperatureC,
            "fridge_temperature_logged_at": fridgeTemperatureLoggedAt ?? "",
            "fridge_inspection_completed_at": fridgeInspectionCompletedAt ?? "",
            "fridge_inspection_missing_count": fridgeInspectionMissingCount,
            "applied_larder_use_keys": Array(appliedLarderUseIntentKeys).sorted(),
        ])
    }

    private func latestLabelPrintJobValue() -> [String: String] {
        guard let job = latestLabelPrintJob else {
            return [:]
        }
        return [
            "label_id": job.labelID,
            "destination": job.destination,
            "paper_size": job.paperSize,
            "output_path": job.outputPath ?? "",
            "status": job.status,
            "created_at": job.createdAt,
        ]
    }

    private func restoreLabelOpsState() {
        restoreLarderItems()
        restoreLatestPrepLabel()
        restoreLatestFridgeTemperature()
        restoreLabelOpsSettings(settingsJSONObject(id: "setting-label-ops-state"))
    }

    private func restoreLabelOpsSettings(_ object: [String: Any]?) {
        guard let object else {
            return
        }
        labelScanLastAction = nonEmptySettingString(object["label_scan_last_action"]) ?? labelScanLastAction
        latestLabelPDFPath = nonEmptySettingString(object["latest_label_pdf_path"])
        latestQRReturnRoute = nonEmptySettingString(object["latest_qr_return_route"]) ?? latestQRReturnRoute
        latestLarderUseSummary = nonEmptySettingString(object["latest_larder_use_summary"]) ?? latestLarderUseSummary
        fridgeTemperatureC = settingInt(object, "fridge_temperature_c", defaultValue: fridgeTemperatureC)
        fridgeTemperatureLoggedAt = nonEmptySettingString(object["fridge_temperature_logged_at"]) ?? fridgeTemperatureLoggedAt
        fridgeInspectionCompletedAt = nonEmptySettingString(object["fridge_inspection_completed_at"])
        fridgeInspectionMissingCount = settingInt(object, "fridge_inspection_missing_count", defaultValue: fridgeInspectionMissingCount)
        appliedLarderUseIntentKeys = Set(object["applied_larder_use_keys"] as? [String] ?? [])
        restoreLatestLabelPrintJob(object["latest_label_print_job"] as? [String: String])
    }

    private func restoreLarderItems() {
        guard let rows = try? database?.rows(named: "larder_item", tenantID: tenantID) else {
            return
        }
        larderItems = rows.compactMap { row in
            guard let labelID = row.values["label_id"],
                  let prepTaskID = row.values["prep_task_id"],
                  let unit = row.values["unit"],
                  let statusValue = row.values["status"],
                  let status = LarderStatus(rawValue: statusValue)
            else {
                return nil
            }
            return PrepLarderItem(
                id: row.id,
                labelID: labelID,
                prepTaskID: prepTaskID,
                qty: catalogDouble(row, "qty", defaultValue: 0),
                unit: unit,
                expireAt: row.values["expire_at"] ?? "",
                status: status
            )
        }
    }

    private func restoreLatestPrepLabel() {
        guard let labelRows = try? database?.rows(named: "label", tenantID: tenantID),
              let labelRow = labelRows.sorted(by: catalogRowSort).last,
              let label = restorePrepLabel(labelRow)
        else {
            return
        }
        latestPrepLabel = label
        nikiriLabelIssuedSignatures.insert(nikiriLabelIssueSignature(label))
    }

    private func restorePrepLabel(_ row: DataRow) -> PrepLabel? {
        guard let statusValue = row.values["status"],
              let status = PrepLabelStatus(rawValue: statusValue),
              let taskInstanceID = row.values["task_instance_id"]
        else {
            return nil
        }
        return PrepLabel(
            id: row.id,
            taskInstanceID: taskInstanceID,
            prepTaskID: restorePrepTaskID(taskInstanceID: taskInstanceID),
            madeQty: catalogDouble(row, "made_qty", defaultValue: 0),
            unit: restoreLabelUnit(labelID: row.id),
            printedAt: row.values["printed_at"] ?? "",
            expireAt: row.values["expire_at"] ?? "",
            qrToken: row.values["qr_token"] ?? "",
            status: status,
            remainingQty: row.values["remaining_qty"].flatMap(Double.init),
            storageUnitID: row.values["storage_unit_id"]
        )
    }

    private func restorePrepTaskID(taskInstanceID: String) -> String {
        let rows = (try? database?.rows(.taskInstance, tenantID: tenantID)) ?? []
        return rows.first { $0.id == taskInstanceID }?.values["prep_task_id"] ?? "task-nikiri"
    }

    private func restoreLabelUnit(labelID: String) -> String {
        larderItems.first { $0.labelID == labelID }?.unit ?? nikiriQuantity.unit
    }

    private func restoreLatestLabelPrintJob(_ values: [String: String]?) {
        guard let values,
              let labelID = values["label_id"],
              !labelID.isEmpty
        else {
            return
        }
        latestLabelPrintJob = LabelPrintJob(
            labelID: labelID,
            destination: values["destination"] ?? "",
            paperSize: values["paper_size"] ?? "",
            outputPath: nonEmptySettingString(values["output_path"]),
            status: values["status"] ?? "",
            createdAt: values["created_at"] ?? ""
        )
    }

    private func restoreLatestFridgeTemperature() {
        guard let rows = try? database?.rows(named: "temp_log", tenantID: tenantID),
              let row = rows
              .filter({ $0.values["kind"] == "fridge" })
              .sorted(by: catalogRowSort)
              .last
        else {
            return
        }
        fridgeTemperatureC = catalogInt(row, "value", defaultValue: fridgeTemperatureC)
        fridgeTemperatureLoggedAt = row.values["logged_at"]
        guard let storageUnitID = row.values["storage_unit_id"],
              let loggedAt = row.values["logged_at"]
        else {
            return
        }
        fridgeTemperatureRecordedSignatures.insert(fridgeTemperatureSignature(
            valueC: fridgeTemperatureC,
            storageUnitID: storageUnitID,
            loggedAt: loggedAt
        ))
    }

    private func persistGuestOpsState() {
        guard let value = guestOpsStateValue() else {
            persistEvent(type: "guest_ops.state_persist_blocked", payload: "{\"reason\":\"json_encoding\"}")
            return
        }
        persistSetting(id: "setting-guest-ops-state", key: "guest_ops.state", value: value)
    }

    private func guestOpsStateValue() -> String? {
        jsonString([
            "special_prep_last_action": specialPrepLastAction,
            "guest_message_last_action": guestMessageLastAction,
            "guest_reply_recheck_last_action": guestReplyRecheckLastAction,
            "guest_reply_requires_label_reprint": guestReplyRequiresLabelReprint ? "1" : "0",
            "allergen_label_print_count": allergenLabelPrintCount,
            "allergen_label_printed_at": allergenLabelPrintedAt ?? "",
            "completed_special_prep_ids": Array(specialPrepCompletedIDs).sorted(),
            "skipped_special_prep_ids": Array(specialPrepSkippedIDs).sorted(),
        ])
    }

    private func restoreGuestOpsState() {
        restoreSpecialPrepTasks()
        restoreAllergenLabels()
        restoreGuestMessages()
        restoreGuestOpsSettings(settingsJSONObject(id: "setting-guest-ops-state"))
        guestReplyRecheckCount = activeGuestReplyRecheckCount
        refreshPassState()
    }

    private func restoreGuestOpsSettings(_ object: [String: Any]?) {
        guard let object else {
            return
        }
        specialPrepLastAction = nonEmptySettingString(object["special_prep_last_action"]) ?? specialPrepLastAction
        guestMessageLastAction = nonEmptySettingString(object["guest_message_last_action"]) ?? guestMessageLastAction
        guestReplyRecheckLastAction = nonEmptySettingString(object["guest_reply_recheck_last_action"]) ?? guestReplyRecheckLastAction
        guestReplyRequiresLabelReprint = (object["guest_reply_requires_label_reprint"] as? String) == "1"
        allergenLabelPrintCount = settingInt(object, "allergen_label_print_count", defaultValue: allergenLabelPrintCount)
        allergenLabelPrintedAt = nonEmptySettingString(object["allergen_label_printed_at"])
        specialPrepCompletedIDs.formUnion(object["completed_special_prep_ids"] as? [String] ?? [])
        specialPrepSkippedIDs.formUnion(object["skipped_special_prep_ids"] as? [String] ?? [])
    }

    private func restoreSpecialPrepTasks() {
        guard let rows = try? database?.rows(named: "special_prep", tenantID: tenantID), !rows.isEmpty else {
            return
        }
        specialPrepTasks = []
        for row in rows where row.values["service_day_id"] == service.id {
            guard let task = restoreSpecialPrepTask(row) else {
                continue
            }
            if row.values["status"] == "done" {
                specialPrepCompletedIDs.insert(task.id)
            } else if isDeletedDataRow(row) {
                specialPrepSkippedIDs.insert(task.id)
            } else {
                specialPrepTasks.append(task)
            }
        }
    }

    private func restoreSpecialPrepTask(_ row: DataRow) -> SpecialPrepTask? {
        guard let reservationID = row.values["reservation_id"],
              let title = row.values["title"],
              let note = row.values["note"]
        else {
            return nil
        }
        return SpecialPrepTask(id: row.id, reservationID: reservationID, title: title, note: note)
    }

    private func restoreAllergenLabels() {
        guard let rows = try? database?.rows(named: "allergen_label", tenantID: tenantID), !rows.isEmpty else {
            return
        }
        allergenLabels = rows.compactMap { row in
            guard row.values["service_day_id"] == service.id,
                  let reservationID = row.values["reservation_id"],
                  let seatRef = row.values["seat_ref"],
                  let displayText = row.values["display_text"]
            else {
                return nil
            }
            return AllergenLabel(
                id: row.id,
                reservationID: reservationID,
                seatRef: seatRef,
                displayText: displayText,
                language: row.values["language"] ?? "ja"
            )
        }
    }

    private func restoreGuestMessages() {
        guard let rows = try? database?.rows(named: "guest_message", tenantID: tenantID), !rows.isEmpty else {
            return
        }
        guestMessages = rows.compactMap { row in
            guard row.values["service_day_id"] == service.id,
                  let reservationID = row.values["reservation_id"],
                  let language = row.values["language"],
                  let body = row.values["body"],
                  let status = row.values["status"]
            else {
                return nil
            }
            return GuestMessage(
                id: row.id,
                reservationID: reservationID,
                language: language,
                body: body,
                status: status
            )
        }
    }

    private func isDeletedDataRow(_ row: DataRow) -> Bool {
        guard let deletedAt = row.values["deleted_at"] else {
            return false
        }
        return !deletedAt.isEmpty && deletedAt != "NULL"
    }

    private func persistDirectServiceOpsState() {
        guard let value = directServiceOpsStateValue() else {
            persistEvent(type: "direct_service.state_persist_blocked", payload: "{\"reason\":\"json_encoding\"}")
            return
        }
        persistSetting(id: "setting-direct-service-ops-state", key: "direct_service.ops_state", value: value)
    }

    private func directServiceOpsStateValue() -> String? {
        jsonString([
            "latest_direct_booking_id": latestDirectBooking?.id ?? "",
            "latest_direct_decision_reason": latestDirectDecision?.reason ?? "",
            "latest_waitlist_promotion_id": latestWaitlistPromotion?.id ?? "",
            "latest_waitlist_promotion_reason": latestWaitlistPromotion?.reason ?? "",
            "latest_noshow_booking_id": latestNoShowSettlement?.bookingID ?? "",
            "service_pass_last_action": servicePassLastAction,
            "multistore_summary": multistoreSummaryValue(),
        ])
    }

    private func multistoreSummaryValue() -> [String: String] {
        guard let summary = multistoreSummary else {
            return [:]
        }
        return [
            "id": summary.id,
            "restaurant_name": summary.restaurantName,
            "service_date": summary.serviceDate,
            "remaining_covers": String(summary.remainingCovers),
            "recommendation": summary.recommendation,
        ]
    }

    private func restoreDirectServiceOpsState() {
        restoreLatestDirectBooking()
        restoreServicePassSeatFlags()
        restoreServiceSyncEvents()
        restoreDirectServiceOpsSettings(settingsJSONObject(id: "setting-direct-service-ops-state"))
    }

    private func restoreDirectServiceOpsSettings(_ object: [String: Any]?) {
        guard let object else {
            return
        }
        servicePassLastAction = nonEmptySettingString(object["service_pass_last_action"]) ?? servicePassLastAction
        restoreLatestDirectBooking(id: nonEmptySettingString(object["latest_direct_booking_id"]))
        restoreMultistoreSummary(object["multistore_summary"] as? [String: String])
    }

    private func restoreMultistoreSummary(_ values: [String: String]?) {
        guard let values,
              let id = values["id"],
              !id.isEmpty
        else {
            return
        }
        multistoreSummary = StoreServiceSummary(
            id: id,
            restaurantName: values["restaurant_name"] ?? "全店舗",
            serviceDate: values["service_date"] ?? service.date,
            remainingCovers: Int(values["remaining_covers"] ?? "") ?? 0,
            recommendation: values["recommendation"] ?? "keep"
        )
    }

    private func restoreLatestDirectBooking(id: String? = nil) {
        guard let rows = try? database?.rows(named: "direct_booking", tenantID: tenantID), !rows.isEmpty else {
            return
        }
        let matching = rows.filter { row in
            guard row.values["service_day_id"] == service.id else { return false }
            return id.map { row.id == $0 } ?? true
        }
        guard let row = matching.sorted(by: catalogRowSort).last,
              let booking = restoreDirectBooking(row)
        else {
            return
        }
        latestDirectBooking = booking
        restoreDirectDerivedState(booking)
    }

    private func restoreDirectBooking(_ row: DataRow) -> DirectBooking? {
        guard let statusValue = row.values["status"],
              let status = DirectBookingStatus(rawValue: statusValue),
              let visitTime = row.values["visit_time"],
              isValidOpenTime(visitTime),
              let coversValue = row.values["covers"],
              let covers = Int(coversValue),
              covers >= 0
        else {
            return nil
        }
        return DirectBooking(
            id: row.id,
            visitTime: visitTime,
            covers: covers,
            course: normalizedDBText(row.values["course_text"], fallback: catalog.courseName),
            guestName: normalizedDBText(row.values["guest_name"], fallback: "Direct guest"),
            guestNote: row.values["guest_note"] ?? nil,
            status: status,
            stripeCheckoutID: row.values["stripe_checkout_id"] ?? nil
        )
    }

    private func restoreDirectDerivedState(_ booking: DirectBooking) {
        latestDirectDecision = DirectBookingDecision(
            status: booking.status,
            confirmedCovers: booking.status == .confirmed ? booking.covers : 0,
            waitlistCovers: booking.status == .request ? booking.covers : 0,
            remainingAllotment: 0,
            reason: booking.status == .request ? "waitlist_registered" : "status_\(booking.status.rawValue)"
        )
        let waitlistRows = (try? database?.rows(named: "waitlist_entry", tenantID: tenantID)) ?? []
        if booking.status == .confirmed {
            guard let waitlist = waitlistRows.first(where: { $0.values["direct_booking_id"] == booking.id && $0.values["status"] == "confirmed" }) else {
                return
            }
            latestWaitlistPromotion = DirectWaitlistPromotion(
                id: "promotion-\(booking.id)",
                directBookingID: booking.id,
                status: .confirmed,
                promotedCovers: Int(waitlist.values["covers"] ?? "") ?? booking.covers,
                remainingAllotment: 0,
                reason: "restored"
            )
        }
        if booking.status == .noshow {
            latestNoShowSettlement = DirectNoShowSettlement(
                id: "noshow-\(booking.id)",
                bookingID: booking.id,
                status: .noshow,
                forfeitsDeposit: true,
                prepImpactCovers: 0
            )
        }
    }

    private func restoreServicePassSeatFlags() {
        guard let rows = try? database?.rows(named: "pass_seat_flag", tenantID: tenantID), !rows.isEmpty else {
            return
        }
        passSeatFlags = rows.compactMap { row in
            guard let reservationID = row.values["reservation_id"],
                  let seatRef = row.values["seat_ref"],
                  let kindValue = row.values["kind"],
                  let kind = GuestSignalKind(rawValue: kindValue),
                  let displayText = row.values["display_text"]
            else {
                return nil
            }
            return PassSeatFlag(
                id: row.id,
                reservationID: reservationID,
                seatRef: seatRef,
                kind: kind,
                displayText: displayText
            )
        }
    }

    private func restoreServiceSyncEvents() {
        guard let rows = try? database?.rows(named: "service_event", tenantID: tenantID), !rows.isEmpty else {
            return
        }
        serviceSyncEvents = rows
            .filter { $0.values["service_day_id"] == service.id }
            .compactMap(restoreServiceSyncEvent)
            .sorted { $0.occurredAt < $1.occurredAt }
        guard !serviceSyncEvents.isEmpty else {
            return
        }
        let state = Engine.serviceSyncState(
            plannedCovers: service.omakaseCovers,
            events: serviceSyncEvents,
            elapsedMinutes: 75,
            serviceMinutes: 120
        )
        serviceSyncState = state
        servicePacingProposal = state.pacing
        refreshPassState()
        refreshStoreSummary(state)
        if servicePassLastAction.isEmpty {
            let pending = servicePassPendingOfflineCount
            servicePassLastAction = pending > 0 ? "未送信 \(pending)件あり" : "サービス同期復元済み"
        }
    }

    private func restoreServiceSyncEvent(_ row: DataRow) -> ServiceSyncEvent? {
        guard let kindValue = row.values["type"],
              let kind = ServiceEventKind(rawValue: kindValue),
              let sourceValue = row.values["source"],
              let source = ServiceEventSource(rawValue: sourceValue),
              let occurredAt = row.values["occurred_at"],
              !occurredAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let payload = row.values["payload"],
              let payloadObject = serviceSyncPayloadObject(payload),
              let covers = serviceSyncPayloadInt(payloadObject, key: "covers"),
              covers >= 0
        else {
            return nil
        }
        let reservationID = nonEmptySettingString(payloadObject["reservation_id"])
        let offlineSequence = serviceSyncPayloadInt(payloadObject, key: "offline_sequence")
        return ServiceSyncEvent(
            id: row.id,
            source: source,
            kind: kind,
            covers: covers,
            reservationID: reservationID,
            occurredAt: occurredAt,
            offlineSequence: offlineSequence
        )
    }

    private func serviceSyncPayloadObject(_ payload: String) -> [String: Any]? {
        guard let data = payload.data(using: .utf8) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private func serviceSyncPayloadInt(_ object: [String: Any], key: String) -> Int? {
        if let value = object[key] as? Int {
            return value > 0 || key == "covers" ? value : nil
        }
        if let value = object[key] as? String, !value.isEmpty {
            return Int(value)
        }
        return nil
    }

    private func restoreSimulationItems(_ itemValues: [[String: String]]) {
        let valuesByID = Dictionary(uniqueKeysWithValues: itemValues.compactMap { values in
            values["id"].map { ($0, values) }
        })
        simulation.items = simulation.items.map { item in
            guard let values = valuesByID[item.id] else {
                return item
            }
            var restored = item
            restored.recommended = Double(values["recommended"] ?? "") ?? item.recommended
            restored.deltaLabel = values["delta_label"] ?? item.deltaLabel
            return restored
        }
    }

    private func restoreSettingsState() {
        let settingsRows = (try? database?.rows(.settings, tenantID: tenantID)) ?? []
        if let lockValue = settingsRows.first(where: { $0.id == "setting-lock" })?.values["value"] {
            settingsLocked = lockValue != "unlocked"
        }
        if let labelModeValue = settingsRows.first(where: { $0.id == "setting-label-mode" })?.values["value"] {
            labelModeEnabled = labelModeValue != "disabled"
        }
        if let exportSummary = settingsRows.first(where: { $0.id == "setting-data-export-last" })?.values["value"], !exportSummary.isEmpty {
            latestExportSummary = exportSummary
        }
        restoreLabelPrinterState()
    }

    private func restoreLabelPrinterState() {
        let printerRows = (try? database?.rows(named: "printer", tenantID: tenantID)) ?? []
        guard !printerRows.isEmpty else {
            return
        }

        var restoredDefaultID: String?
        for index in labelPrinterDevices.indices {
            guard let row = printerRows.first(where: { $0.id == labelPrinterDevices[index].id }) else {
                continue
            }
            labelPrinterDevices[index].name = normalizedDBText(row.values["name"], fallback: labelPrinterDevices[index].name)
            labelPrinterDevices[index].connection = normalizedDBText(row.values["connection"], fallback: labelPrinterDevices[index].connection)
            labelPrinterDevices[index].paperSize = normalizedDBText(row.values["paper_size"], fallback: labelPrinterDevices[index].paperSize)
            labelPrinterDevices[index].status = normalizedDBText(row.values["status"], fallback: labelPrinterDevices[index].status)
            labelPrinterDevices[index].isDefault = row.values["is_default"] == "1"
            if labelPrinterDevices[index].isDefault {
                restoredDefaultID = labelPrinterDevices[index].id
            }
        }
        if let restoredDefaultID {
            selectedLabelPrinterID = restoredDefaultID
            labelPaperSize = labelPrinterDevices.first { $0.id == restoredDefaultID }?.paperSize ?? labelPaperSize
        }
    }

    private func persistPrinterSeedIfNeeded(_ printer: LabelPrinterDevice) {
        let existingPrinter = try? database?.rows(named: "printer", tenantID: tenantID)
            .contains { $0.id == printer.id }
        guard existingPrinter != true else {
            return
        }
        persistPrinter(printer)
    }

    private func persistPrinter(_ printer: LabelPrinterDevice) {
        let values: [String: String?] = [
            "id": printer.id,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "name": printer.name,
            "connection": printer.connection,
            "paper_size": printer.paperSize,
            "status": printer.status,
            "is_default": printer.isDefault ? "1" : "0",
            "last_tested_at": nil,
        ]
        try? database?.create(named: "printer", values: values)
        try? database?.update(named: "printer", id: printer.id, tenantID: tenantID, values: values)
    }

    private func persistPrinterTest(printerID: String, testedAt: String) {
        guard let printer = labelPrinterDevices.first(where: { $0.id == printerID }) else { return }
        let values: [String: String?] = [
            "id": printer.id,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "name": printer.name,
            "connection": printer.connection,
            "paper_size": printer.paperSize,
            "status": printer.status,
            "is_default": printer.isDefault ? "1" : "0",
            "last_tested_at": testedAt,
        ]
        try? database?.update(named: "printer", id: printer.id, tenantID: tenantID, values: values)
    }

    private func persistServiceSeed() {
        try? database?.create(.serviceDay, values: [
            "id": service.id,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "date": service.date,
            "service_period": service.periodCode,
            "open_time": service.openTime,
            "note": "P0 manual covers",
        ])
        persistServiceCover()
        persistServiceOtherCovers()
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

    private func persistServiceOtherCovers() {
        let values: [String: String?] = [
            "id": "setting-service-other-covers",
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "key": "service.other_covers",
            "value": String(service.otherCovers),
        ]
        try? database?.create(.settings, values: values)
        try? database?.update(.settings, id: "setting-service-other-covers", tenantID: tenantID, values: values)
    }

    private func restoreServiceState() {
        restoreServiceDay()
        restoreServiceCovers()
        restoreReservations()
        recalculateCoversFromReservationsIfNeeded()
    }

    private func restoreServiceDay() {
        guard let row = try? database?.rows(.serviceDay, tenantID: tenantID)
            .first(where: { $0.id == service.id })
        else {
            return
        }

        if let openTime = row.values["open_time"], isValidOpenTime(openTime) {
            service.openTime = openTime
        }
        let restoredPeriod = row.values["service_period"].flatMap { periodCode in
            service.periods.first { $0.servicePeriod == periodCode }
        }
        if let period = restoredPeriod {
            service.period = period.label
            service.selectedPeriodID = period.id
        } else if let period = service.periods.first(where: { $0.openTime == service.openTime }) {
            service.period = period.label
            service.selectedPeriodID = period.id
        }
        refreshServicePeriodSelectionGuard()
    }

    private func restoreServiceCovers() {
        let coverRow = try? database?.rows(.serviceCover, tenantID: tenantID)
            .first { $0.id == serviceCoverID }
        if let coversValue = coverRow?.values["covers"], let covers = Int(coversValue) {
            service.omakaseCovers = resolvedServiceCovers(covers)
        }

        let otherCoversValue = try? database?.rows(.settings, tenantID: tenantID)
            .first(where: { $0.id == "setting-service-other-covers" })?
            .values["value"]
        if let otherCoversValue, let otherCovers = Int(otherCoversValue) {
            service.otherCovers = resolvedServiceCovers(otherCovers)
        }
    }

    private func restoreReservations() {
        guard let rows = try? database?.rows(.reservation, tenantID: tenantID), !rows.isEmpty else {
            return
        }

        let restored = rows.compactMap { row -> ManualReservation? in
            guard row.values["service_day_id"] == service.id,
                  let visitTime = row.values["visit_time"],
                  isValidOpenTime(visitTime),
                  let coversValue = row.values["covers"],
                  let covers = Int(coversValue)
            else {
                return nil
            }
            let partyName = normalizedDBText(row.values["party_name"], fallback: "予約 \(row.id)")
            let note = normalizedDBText(row.values["note"], fallback: "メモ：—")
            return ManualReservation(
                id: row.id,
                visitTime: visitTime,
                partyName: partyName,
                note: resolvedReservationNote(note),
                covers: resolvedReservationCovers(covers)
            )
        }
        guard !restored.isEmpty else {
            return
        }
        service.reservations = restored.sorted {
            if $0.visitTime == $1.visitTime {
                return $0.id < $1.id
            }
            return $0.visitTime < $1.visitTime
        }
    }

    private func recalculateCoversFromReservationsIfNeeded() {
        let reservationCovers = service.reservations.reduce(0) { $0 + $1.covers }
        guard service.omakaseCovers == 0, reservationCovers > 0 else {
            return
        }
        service.omakaseCovers = resolvedServiceCovers(reservationCovers)
    }

    private func normalizedDBText(_ value: String?, fallback: String) -> String {
        guard let value, value != "NULL" else {
            return fallback
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func resolvedServiceCovers(_ requestedCovers: Int) -> Int {
        min(max(0, requestedCovers), maximumServiceCovers)
    }

    private func resolvedReservationCovers(_ requestedCovers: Int) -> Int {
        min(max(1, requestedCovers), maximumReservationCovers)
    }

    private func resolvedReservationNote(_ requestedNote: String) -> String {
        String(requestedNote.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maximumReservationNoteLength))
    }

    private func persistClampedServiceCoversIfNeeded(course: String, requestedCovers: Int, resolvedCovers: Int) {
        guard requestedCovers != resolvedCovers else {
            return
        }
        persistEvent(
            type: "service_cover.update_clamped",
            payload: "{\"course\":\"\(course)\",\"requested_covers\":\(requestedCovers),\"resolved_covers\":\(resolvedCovers)}"
        )
    }

    private func persistClampedReservationCoversIfNeeded(
        reservationID: String,
        requestedCovers: Int,
        resolvedCovers: Int
    ) {
        guard requestedCovers != resolvedCovers else {
            return
        }
        persistEvent(
            type: "reservation.update_clamped",
            payload: "{\"reservation_id\":\"\(reservationID)\",\"requested_covers\":\(requestedCovers),\"resolved_covers\":\(resolvedCovers)}"
        )
    }

    private func persistNormalizedReservationNoteIfNeeded(
        reservationID: String,
        requestedNote: String?,
        resolvedNote: String?
    ) {
        guard let requestedNote, let resolvedNote, requestedNote != resolvedNote else {
            return
        }
        persistEvent(
            type: "reservation.note_normalized",
            payload: "{\"reservation_id\":\"\(reservationID)\",\"max_length\":\(maximumReservationNoteLength)}"
        )
    }

    private func invalidCatalogTaskUpdateReason(
        coeffPerCover: Double?,
        yieldPercent: Double?,
        durationMin: Int?,
        leadMinBeforeOpen: Int?
    ) -> String? {
        if let coeffPerCover, !coeffPerCover.isFinite || coeffPerCover < 0 {
            return "invalid_coeff_per_cover"
        }
        if let yieldPercent, !yieldPercent.isFinite || yieldPercent <= 0 || yieldPercent > 100 {
            return "invalid_yield_percent"
        }
        if let durationMin, durationMin < 0 {
            return "invalid_duration_min"
        }
        if let leadMinBeforeOpen, leadMinBeforeOpen < 0 {
            return "invalid_lead_min"
        }
        return nil
    }

    private func invalidCatalogTaskTextUpdateReason(name: String?, sectionName: String?) -> String? {
        if let name, name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "invalid_name"
        }
        if let sectionName, sectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "invalid_section"
        }
        return nil
    }

    private func isValidOpenTime(_ openTime: String) -> Bool {
        let parts = openTime.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2,
              parts.allSatisfy({ $0.count == 2 }),
              let hour = Int(parts[0]),
              let minute = Int(parts[1])
        else {
            return false
        }
        return (0 ... 23).contains(hour) && (0 ... 59).contains(minute)
    }

    private func isHHMM(_ lhs: String, before rhs: String) -> Bool {
        guard let lhsMinutes = hhmmMinutes(lhs), let rhsMinutes = hhmmMinutes(rhs) else {
            return false
        }
        return lhsMinutes < rhsMinutes
    }

    private func hhmmMinutes(_ value: String) -> Int? {
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1])
        else {
            return nil
        }
        return hour * 60 + minute
    }

    private func isValidWasteRecord(madeQty: Double, leftoverQty: Double) -> Bool {
        madeQty.isFinite
            && leftoverQty.isFinite
            && madeQty > 0
            && leftoverQty >= 0
            && leftoverQty <= madeQty
    }

    private func isValidPositiveQuantity(_ qty: Double) -> Bool {
        qty.isFinite && qty > 0
    }

    private func isValidFridgeTemperatureInput(
        valueC: Int,
        storageUnitID: String,
        loggedAt: String
    ) -> Bool {
        (-40 ... 60).contains(valueC)
            && !storageUnitID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !loggedAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func isValidTodayPrepActualDelta(_ delta: Int) -> Bool {
        (-240 ... 240).contains(delta) && delta != 0
    }

    private func jsonNumberOrNull(_ value: Double) -> String {
        value.isFinite ? numberString(value) : "null"
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
            "note": resolvedReservationNote(reservation.note),
            "structured": "1",
        ])
    }

    private func upsertConnectorReviewItem(_ item: ConnectorDiffReviewItem) {
        if let index = connectorDiffReviewItems.firstIndex(where: { $0.id == item.id }) {
            connectorDiffReviewItems[index] = item
        } else {
            connectorDiffReviewItems.append(item)
        }
        connectorDiffReviewItems.sort { lhs, rhs in
            if lhs.state == rhs.state {
                return lhs.visitTime < rhs.visitTime
            }
            return lhs.state == "未処理"
        }
    }

    private func markConnectorReviewItem(_ id: String, state: String) {
        guard let index = connectorDiffReviewItems.firstIndex(where: { $0.id == id }) else {
            return
        }
        connectorDiffReviewItems[index].state = state
        connectorDiffReviewItems.sort { lhs, rhs in
            if lhs.state == rhs.state {
                return lhs.visitTime < rhs.visitTime
            }
            return lhs.state == "未処理"
        }
    }

    private func connectorSourceEventReviewState(_ id: String) -> String? {
        let rows = (try? database?.rows(named: "source_event", tenantID: tenantID)) ?? []
        guard let payload = rows.first(where: { $0.id == id })?.values["payload"] else {
            return nil
        }
        for state in ["accepted", "rejected", "processed", "pending"] where payload.contains("\"review_state\":\"\(state)\"") {
            return state
        }
        return nil
    }

    private func isTerminalConnectorReviewState(_ state: String) -> Bool {
        ["accepted", "rejected", "processed"].contains(state)
    }

    private func connectorReviewDisplayState(_ state: String) -> String {
        switch state {
        case "accepted":
            "承認済み"
        case "rejected":
            "却下"
        case "processed":
            "処理済み"
        default:
            "未処理"
        }
    }

    private func upsertSpecialPrepTasks(_ tasks: [SpecialPrepTask]) {
        for task in tasks {
            if let index = specialPrepTasks.firstIndex(where: { $0.id == task.id }) {
                specialPrepTasks[index] = task
            } else {
                specialPrepTasks.append(task)
            }
        }
    }

    private func upsertAllergenLabels(_ labels: [AllergenLabel]) {
        for label in labels {
            if let index = allergenLabels.firstIndex(where: { $0.id == label.id }) {
                allergenLabels[index] = label
            } else {
                allergenLabels.append(label)
            }
        }
    }

    private func upsertGuestMessage(_ message: GuestMessage) {
        if let index = guestMessages.firstIndex(where: { $0.id == message.id }) {
            guestMessages[index] = message
        } else {
            guestMessages.append(message)
        }
    }

    private func upsertPassSeatFlags(_ flags: [PassSeatFlag]) {
        for flag in flags {
            if let index = passSeatFlags.firstIndex(where: { $0.id == flag.id }) {
                passSeatFlags[index] = flag
            } else {
                passSeatFlags.append(flag)
            }
        }
    }

    private func createGuestReplyRecheck(reservationID: String, note: String) {
        let seatRef = seatRef(forReservationID: reservationID)
        let taskID = guestReplyRecheckTaskID(reservationID: reservationID)
        let task = SpecialPrepTask(
            id: taskID,
            reservationID: reservationID,
            title: "返信変更の再確認",
            note: "\(seatRef) \(note) / 仕込み・席札を再確認"
        )
        let flag = PassSeatFlag(
            id: "pass-flag-recheck-\(reservationID)",
            reservationID: reservationID,
            seatRef: seatRef,
            kind: .special,
            displayText: "\(seatRef) 返信変更あり: \(note)"
        )

        upsertSpecialPrepTasks([task])
        upsertPassSeatFlags([flag])
        persistSpecialPrep(task)
        persistPassSeatFlag(flag)
        guestReplyRecheckCount = activeGuestReplyRecheckCount
        guestReplyRequiresLabelReprint = hasAllergenLabel(forReservationID: reservationID)
        specialPrepLastAction = "返信変更を厨房で再確認"
        guestReplyRecheckLastAction = guestReplyRequiresLabelReprint ? "\(seatRef) 仕込み・席札再確認" : "\(seatRef) 仕込み再確認"
        refreshPassState()
        persistGuestOpsState()
        persistEvent(
            type: "guest_reply.recheck_requested",
            payload: "{\"reservation_id\":\"\(reservationID)\",\"seat_ref\":\"\(seatRef)\",\"label_reprint\":\(guestReplyRequiresLabelReprint),\"note\":\"\(note)\"}"
        )
    }

    private func hasAllergenLabel(forReservationID reservationID: String) -> Bool {
        allergenLabels.contains { $0.reservationID == reservationID }
    }

    private func guestReplyRecheckTaskID(reservationID: String) -> String {
        "special-prep-recheck-\(reservationID)"
    }

    private func guestReplyImpactID(reservationID: String) -> String {
        "impact-reply-\(reservationID)"
    }

    private func hasOpenGuestReplyChange(for reservationID: String) -> Bool {
        let recheckTaskID = guestReplyRecheckTaskID(reservationID: reservationID)
        let impactID = guestReplyImpactID(reservationID: reservationID)
        return specialPrepTasks.contains { $0.id == recheckTaskID }
            || todayPrepImpactItems.contains { $0.id == impactID }
            || todayPrepDynamicChecks.contains { $0.id == "check-\(impactID)" && !todayPrepCompletedCheckIDs.contains($0.id) }
    }

    private var activeGuestReplyRecheckCount: Int {
        specialPrepTasks.count { $0.id.hasPrefix("special-prep-recheck-") }
    }

    private func seatRef(forReservationID reservationID: String) -> String {
        if let flag = passSeatFlags.first(where: { $0.reservationID == reservationID }) {
            return flag.seatRef
        }
        if reservationID.contains("kimura") {
            return "卓5"
        }
        if reservationID.contains("suzuki") {
            return "卓3"
        }
        return "卓3"
    }

    private func reviewItem(
        for event: SourceReservationEvent,
        normalized: NormalizedReservation,
        state: String
    ) -> ConnectorDiffReviewItem {
        ConnectorDiffReviewItem(
            id: event.id,
            sourceLabel: event.provider.rawValue == "tablecheck" ? "TableCheck 構造化" : event.provider.rawValue,
            partyName: normalized.partyName,
            visitTime: normalized.visitTime,
            covers: normalized.covers,
            course: normalized.course,
            status: normalized.status,
            prepNote: normalized.prepNote ?? "コース・人数を構造化で取得",
            diffLabel: connectorDiffLabel(for: normalized),
            state: state
        )
    }

    private func connectorDiffLabel(for reservation: NormalizedReservation) -> String {
        if reservation.status == "cancelled" {
            let cancelled = service.reservations.first(where: { $0.id == reservation.id })?.covers ?? reservation.covers
            return "-\(cancelled)名"
        }

        guard let current = service.reservations.first(where: { $0.id == reservation.id }) else {
            return "+\(reservation.covers)名"
        }

        let delta = reservation.covers - current.covers
        if delta > 0 {
            return "+\(delta)名"
        }
        if delta < 0 {
            return "\(delta)名"
        }
        return "内容変更"
    }

    private func connectorSeatRef(for event: SourceReservationEvent) -> String {
        if event.externalID.contains("kimura") {
            return "卓5"
        }
        if event.externalID.contains("suzuki") {
            return "卓3"
        }
        return "卓3"
    }

    private func isValidConnectorReservationEvent(_ event: SourceReservationEvent) -> Bool {
        let requiredText = [event.id, event.externalID, event.visitTime, event.course, event.partyName]
        let hasRequiredText = requiredText.allSatisfy {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return hasRequiredText && (event.status == "cancelled" || event.covers > 0)
    }

    private func persistBlockedConnectorReservationEvent(_ event: SourceReservationEvent, reason: String) {
        persistEvent(
            type: "connector.reservation_blocked",
            payload: "{"
                + "\"source_event_id\":\"\(event.id)\","
                + "\"external_id\":\"\(event.externalID)\","
                + "\"reason\":\"\(reason)\","
                + "\"covers\":\(event.covers),"
                + "\"status\":\"\(event.status)\""
                + "}"
        )
    }

    private func applyNormalizedReservation(_ reservation: NormalizedReservation) {
        if reservation.status == "cancelled" || reservation.status == "noshow" {
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

    private func persistSourceReservationEvent(
        _ event: SourceReservationEvent,
        normalized: NormalizedReservation,
        processedAt: String? = "2026-06-17T09:00:01Z",
        reviewState: String = "processed",
        occurredAt: String = "2026-06-17T09:00:00Z"
    ) {
        let values: [String: String?] = [
            "id": event.id,
            "tenant_id": tenantID,
            "connector_account_id": connectorID(for: event.provider),
            "source": event.provider.rawValue,
            "external_id": event.externalID,
            "type": "reservation.\(event.status == "cancelled" ? "cancelled" : "upserted")",
            "payload": sourceReservationPayload(event, normalized: normalized, reviewState: reviewState),
            "occurred_at": occurredAt,
            "processed_at": processedAt,
        ]
        try? database?.create(named: "source_event", values: values)
        try? database?.update(named: "source_event", id: event.id, tenantID: tenantID, values: values)
    }

    private func sourceReservationPayload(
        _ event: SourceReservationEvent,
        normalized: NormalizedReservation,
        reviewState: String
    ) -> String {
        jsonString([
            "external_id": event.externalID,
            "reservation_id": normalized.id,
            "visit_time": event.visitTime,
            "covers": event.covers,
            "course": event.course,
            "party_name": event.partyName,
            "status": event.status,
            "allergy_note": event.allergyNote ?? "",
            "vip_rank": event.vipRank ?? "",
            "review_state": reviewState,
        ]) ?? "{}"
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

    private func persistWaitlistStatus(bookingID: String, status: String) {
        try? database?.update(named: "waitlist_entry", id: "waitlist-\(bookingID)", tenantID: tenantID, values: [
            "status": status,
        ])
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
        labelScanLastAction = "\(scanKind) / \(result.label.status.rawValue)"
        persistLabelOpsState()
    }

    private func canScanLabel(_ label: PrepLabel) -> Bool {
        label.status == .active || label.status == .remaining
    }

    private func isValidPositiveLabelScanQty(_ qty: Double) -> Bool {
        qty.isFinite && qty > 0
    }

    private func cappedLabelScanQty(_ qty: Double, for label: PrepLabel) -> Double {
        max(0, min(qty, label.remainingQty ?? label.madeQty))
    }

    private func blockedLabelScanResult(
        action: LabelScanAction,
        scanKind: String,
        existingLabel: PrepLabel? = nil,
        reason: String
    ) -> LabelScanResult {
        if let existingLabel {
            labelScanLastAction = "QR記録不可: \(existingLabel.status.rawValue)"
            let signature = labelScanBlockedSignature(
                action: action,
                scanKind: scanKind,
                labelID: existingLabel.id,
                status: existingLabel.status.rawValue,
                reason: reason
            )
            if labelScanBlockedSignatures.contains(signature) {
                persistEvent(
                    type: "label.scan_blocked_skipped",
                    payload: "{\"label_id\":\"\(existingLabel.id)\",\"kind\":\"\(scanKind)\",\"reason\":\"duplicate_block\"}"
                )
                return LabelScanResult(label: existingLabel, larderItem: nil, wasteRecord: nil)
            }
            labelScanBlockedSignatures.insert(signature)
            persistEvent(
                type: "label.scan_blocked",
                payload: "{\"label_id\":\"\(existingLabel.id)\",\"kind\":\"\(scanKind)\",\"reason\":\"\(reason)\",\"status\":\"\(existingLabel.status.rawValue)\"}"
            )
            return LabelScanResult(label: existingLabel, larderItem: nil, wasteRecord: nil)
        }

        let requestedLabel = makeNikiriPrepLabel(madeQty: nil, printedAt: "2026-06-11T16:20:00Z", storageUnitID: nil)
        let preview = scanPrepLabel(requestedLabel, action: action)
        labelScanLastAction = "QR記録不可: ラベル未発行"
        let signature = labelScanBlockedSignature(
            action: action,
            scanKind: scanKind,
            labelID: requestedLabel.id,
            status: "missing",
            reason: reason
        )
        if labelScanBlockedSignatures.contains(signature) {
            persistEvent(
                type: "label.scan_blocked_skipped",
                payload: "{\"label_id\":\"\(requestedLabel.id)\",\"kind\":\"\(scanKind)\",\"reason\":\"duplicate_block\"}"
            )
            return LabelScanResult(label: preview.label, larderItem: nil, wasteRecord: nil)
        }
        labelScanBlockedSignatures.insert(signature)
        persistEvent(
            type: "label.scan_blocked",
            payload: "{\"label_id\":\"\(requestedLabel.id)\",\"kind\":\"\(scanKind)\",\"reason\":\"\(reason)\"}"
        )
        return LabelScanResult(label: preview.label, larderItem: nil, wasteRecord: nil)
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

    private func persistLabelWasteRecord(_ record: CloseTaskRecord, labelID: String, recordedBy: String = "label-qr") {
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
            "recorded_by": recordedBy,
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
            "id": sectionShariID,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "name": "シャリ場",
            "sort": "1",
        ])
        try? database?.create(.section, values: [
            "id": sectionGardeID,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "name": "ガルド",
            "sort": "2",
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

    private func restoreCatalogState() {
        guard let courseRows = try? database?.rows(.courseTemplate, tenantID: tenantID),
              let dishRows = try? database?.rows(.dish, tenantID: tenantID),
              let componentRows = try? database?.rows(.component, tenantID: tenantID),
              let taskRows = try? database?.rows(.prepTask, tenantID: tenantID)
        else {
            return
        }
        guard let courseRow = courseRows.first(where: { $0.id == catalog.id }) ?? courseRows.first else {
            return
        }

        let restoredDishes = restoredCatalogDishes(
            courseID: courseRow.id,
            dishRows: dishRows,
            componentRows: componentRows,
            taskRows: taskRows
        )

        guard !restoredDishes.isEmpty else {
            return
        }

        let restoredTaskIDs = Set(restoredDishes.flatMap { dish in
            dish.components.flatMap { component in
                component.tasks.map(\.id)
            }
        })
        let selectedTaskID = restoredSelectedCatalogTaskID(availableTaskIDs: restoredTaskIDs)
        catalog = CatalogTemplate(
            id: courseRow.id,
            courseName: courseRow.values["name"] ?? catalog.courseName,
            dishes: restoredDishes,
            selectedTaskID: selectedTaskID
        )
        catalogSequence = max(catalogSequence, restoredCustomCatalogSequence(in: restoredDishes))
    }

    private func restoredCatalogDishes(
        courseID: String,
        dishRows: [DataRow],
        componentRows: [DataRow],
        taskRows: [DataRow]
    ) -> [CatalogDish] {
        let componentRowsByDishID = Dictionary(grouping: componentRows) { row in
            row.values["dish_id"] ?? ""
        }
        return dishRows
            .filter { $0.values["course_template_id"] == courseID }
            .sorted(by: catalogRowSort)
            .map { dishRow in
                CatalogDish(
                    id: dishRow.id,
                    name: dishRow.values["name"] ?? "料理",
                    components: restoredCatalogComponents(
                        dishID: dishRow.id,
                        componentRowsByDishID: componentRowsByDishID,
                        taskRows: taskRows
                    ),
                    sort: catalogInt(dishRow, "sort", defaultValue: 0)
                )
            }
    }

    private func restoredCatalogComponents(
        dishID: String,
        componentRowsByDishID: [String: [DataRow]],
        taskRows: [DataRow]
    ) -> [CatalogComponent] {
        let taskRowsByComponentID = Dictionary(grouping: taskRows) { row in
            row.values["component_id"] ?? ""
        }
        return (componentRowsByDishID[dishID] ?? [])
            .sorted(by: catalogRowSort)
            .map { componentRow in
                CatalogComponent(
                    id: componentRow.id,
                    name: componentRow.values["name"] ?? "構成要素",
                    tasks: (taskRowsByComponentID[componentRow.id] ?? [])
                        .sorted(by: catalogRowSort)
                        .map(restoredCatalogTask),
                    sort: catalogInt(componentRow, "sort", defaultValue: 0)
                )
            }
    }

    private func restoredCatalogTask(_ taskRow: DataRow) -> CatalogPrepTask {
        let sectionRows = (try? database?.rows(.section, tenantID: tenantID)) ?? []
        let sectionNamesByID = Dictionary(uniqueKeysWithValues: sectionRows.map { row in
            (row.id, row.values["name"] ?? "親方")
        })
        return CatalogPrepTask(
            id: taskRow.id,
            name: taskRow.values["name"] ?? "仕込み",
            scaleMode: catalogScaleMode(from: taskRow.values["scale_mode"]),
            coeffPerCover: catalogDouble(taskRow, "coeff_per_cover", defaultValue: 1),
            yieldPercent: catalogDouble(taskRow, "yield", defaultValue: 1) * 100,
            roundStep: catalogDouble(taskRow, "round_step", defaultValue: 10),
            unit: taskRow.values["unit"] ?? "個",
            durationMin: catalogInt(taskRow, "duration_min", defaultValue: 40),
            leadMinBeforeOpen: catalogInt(taskRow, "lead_min_before_open", defaultValue: 180),
            shelfLifeDays: catalogInt(taskRow, "shelf_life_days", defaultValue: 1),
            sectionName: sectionNamesByID[taskRow.values["section_id"] ?? ""] ?? "親方",
            instruction: taskRow.values["instruction"] ?? "",
            sort: catalogInt(taskRow, "sort", defaultValue: 0)
        )
    }

    private func restoredSelectedCatalogTaskID(availableTaskIDs: Set<String>) -> String {
        let settingsRows = (try? database?.rows(.settings, tenantID: tenantID)) ?? []
        let savedTaskID = settingsRows.first { $0.id == "setting-catalog-selected-task" }?.values["value"]
        if let savedTaskID, availableTaskIDs.contains(savedTaskID) {
            return savedTaskID
        }
        if availableTaskIDs.contains(catalog.selectedTaskID) {
            return catalog.selectedTaskID
        }
        return savedTaskID ?? catalog.selectedTaskID
    }

    private func restoredCustomCatalogSequence(in dishes: [CatalogDish]) -> Int {
        let dishIDs = dishes.map(\.id)
        let componentIDs = dishes.flatMap { dish in dish.components.map(\.id) }
        let taskIDs = dishes.flatMap { dish in dish.components.flatMap { component in component.tasks.map(\.id) } }
        return (dishIDs + componentIDs + taskIDs)
            .map { customCatalogSequence(from: $0) }
            .max() ?? 0
    }

    private func customCatalogSequence(from id: String) -> Int {
        guard id.contains("-custom-"),
              let suffix = id.split(separator: "-").last,
              let value = Int(suffix)
        else {
            return 0
        }
        return value
    }

    private func catalogRowSort(_ lhs: DataRow, _ rhs: DataRow) -> Bool {
        let lhsSort = catalogInt(lhs, "sort", defaultValue: 0)
        let rhsSort = catalogInt(rhs, "sort", defaultValue: 0)
        if lhsSort == rhsSort {
            return lhs.id < rhs.id
        }
        return lhsSort < rhsSort
    }

    private func catalogScaleMode(from value: String?) -> ScaleMode {
        switch value {
        case "per_portion", "perPortion":
            .perPortion
        case "fixed_batch", "fixedBatch":
            .fixedBatch
        default:
            .perCover
        }
    }

    private func scaleModeStorageValue(_ scaleMode: ScaleMode) -> String {
        switch scaleMode {
        case .perCover:
            "per_cover"
        case .perPortion:
            "per_portion"
        case .fixedBatch:
            "fixed_batch"
        }
    }

    private func catalogDouble(_ row: DataRow, _ key: String, defaultValue: Double) -> Double {
        guard let value = row.values[key],
              let number = Double(value)
        else {
            return defaultValue
        }
        return number
    }

    private func catalogInt(_ row: DataRow, _ key: String, defaultValue: Int) -> Int {
        guard let value = row.values[key],
              let number = Int(value)
        else {
            return defaultValue
        }
        return number
    }

    private func jsonString(_ object: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func settingsJSONObject(id: String) -> [String: Any]? {
        guard let value = try? database?.rows(.settings, tenantID: tenantID)
            .first(where: { $0.id == id })?
            .values["value"],
            let data = value.data(using: .utf8)
        else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private func settingInt(_ object: [String: Any], _ key: String, defaultValue: Int) -> Int {
        if let value = object[key] as? Int {
            return value
        }
        if let value = object[key] as? String {
            return Int(value) ?? defaultValue
        }
        return defaultValue
    }

    private func settingDouble(_ values: [String: String], _ key: String, defaultValue: Double) -> Double {
        guard let value = values[key],
              let number = Double(value)
        else {
            return defaultValue
        }
        return number
    }

    private func nonEmptySettingString(_ value: Any?) -> String? {
        guard let string = value as? String,
              !string.isEmpty
        else {
            return nil
        }
        return string
    }

    private func closeRecordValue(_ record: CloseTaskRecord) -> [String: String] {
        [
            "task": record.task,
            "planned_qty": numberString(record.plannedQty),
            "made_qty": numberString(record.madeQty),
            "leftover_qty": numberString(record.leftoverQty),
            "unit": record.unit,
            "waste_reason": record.wasteReason.rawValue,
            "carryover_to_next": record.carryoverToNext ? "1" : "0",
        ]
    }

    private func carryoverValue(_ carryover: CarryoverItem) -> [String: String] {
        [
            "task": carryover.task,
            "qty": numberString(carryover.qty),
            "unit": carryover.unit,
        ]
    }

    private func nextDayAdjustmentValue(_ adjustment: NextDayAdjustment) -> [String: String] {
        [
            "task": adjustment.task,
            "base": numberString(adjustment.base),
            "adjusted": numberString(adjustment.adjusted),
            "unit": adjustment.unit,
        ]
    }

    private func restoreCloseRecords(_ values: [[String: String]]) -> [CloseTaskRecord] {
        values.compactMap { value in
            guard let task = value["task"],
                  let unit = value["unit"],
                  let reasonValue = value["waste_reason"],
                  let wasteReason = WasteReason(rawValue: reasonValue)
            else {
                return nil
            }
            return CloseTaskRecord(
                task: task,
                plannedQty: settingDouble(value, "planned_qty", defaultValue: 0),
                madeQty: settingDouble(value, "made_qty", defaultValue: 0),
                leftoverQty: settingDouble(value, "leftover_qty", defaultValue: 0),
                unit: unit,
                wasteReason: wasteReason,
                carryoverToNext: value["carryover_to_next"] == "1"
            )
        }
    }

    private func restoreCarryovers(_ values: [[String: String]]) -> [CarryoverItem] {
        values.compactMap { value in
            guard let task = value["task"],
                  let unit = value["unit"]
            else {
                return nil
            }
            return CarryoverItem(task: task, qty: settingDouble(value, "qty", defaultValue: 0), unit: unit)
        }
    }

    private func restoreNextDayAdjustments(_ values: [[String: String]]) -> [NextDayAdjustment] {
        values.compactMap { value in
            guard let task = value["task"],
                  let unit = value["unit"]
            else {
                return nil
            }
            return NextDayAdjustment(
                task: task,
                base: settingDouble(value, "base", defaultValue: 0),
                adjusted: settingDouble(value, "adjusted", defaultValue: 0),
                unit: unit
            )
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
            "instruction": task.instruction,
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

    private func persistTodayPrepAssignments() {
        let value = todayPrepStepOperatorOverrides
            .filter { assignment in
                Self.focusStepIDs.contains(assignment.key)
                    && todayPrepOperators.contains { $0.id == assignment.value }
            }
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ";")

        let values: [String: String?] = [
            "id": "setting-today-prep-assignments",
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "key": "today_prep.assignments",
            "value": value,
        ]
        try? database?.create(.settings, values: values)
        try? database?.update(.settings, id: "setting-today-prep-assignments", tenantID: tenantID, values: values)
    }

    private func restoreTodayPrepAssignments() {
        guard let value = try? database?.rows(.settings, tenantID: tenantID)
            .first(where: { $0.id == "setting-today-prep-assignments" })?
            .values["value"]
        else {
            return
        }

        let restored = value.split(separator: ";").reduce(into: [String: String]()) { partial, pair in
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { return }
            let stepID = String(parts[0])
            let operatorID = String(parts[1])
            guard Self.focusStepIDs.contains(stepID),
                  todayPrepOperators.contains(where: { $0.id == operatorID })
            else {
                return
            }
            partial[stepID] = operatorID
        }

        todayPrepStepOperatorOverrides = restored
    }

    private func persistTodayPrepOperationalState() {
        guard let value = todayPrepOperationalStateValue() else {
            persistEvent(
                type: "today_prep.state_persist_blocked",
                payload: "{\"reason\":\"json_encoding\"}"
            )
            return
        }
        persistSetting(id: "setting-today-prep-state", key: "today_prep.state", value: value)
    }

    private func todayPrepOperationalStateValue() -> String? {
        jsonString([
            "completed_focus_ids": completed.intersection(Self.focusStepIDs).sorted(),
            "selected_operator_id": selectedTodayPrepOperatorID,
            "started_at": todayPrepStartedAt.filter { Self.focusStepIDs.contains($0.key) },
            "checked_at": todayPrepCheckedAt.filter { Self.focusStepIDs.contains($0.key) },
            "completed_by": todayPrepCompletedBy.filter { Self.focusStepIDs.contains($0.key) },
            "manual_actual_minutes": todayPrepManualActualMinutes.filter { Self.focusStepIDs.contains($0.key) },
            "completed_check_ids": todayPrepCompletedCheckIDs.sorted(),
            "assist_requested_at": todayPrepAssistRequestedAt,
            "assist_proposal": todayPrepAssistProposal.map(todayPrepAssistProposalValue) ?? [:],
            "assist_applied_summary": todayPrepAssistAppliedSummary ?? "",
            "assist_eta_after_apply": todayPrepAssistETAAfterApply.map(todayPrepETAValue) ?? [:],
            "assist_applied_signature": todayPrepAssistAppliedSignature ?? "",
            "dynamic_checks": todayPrepDynamicCheckValues(),
            "impact_items": todayPrepImpactItems.map(todayPrepImpactValue),
            "applied_impact_ids": Array(todayPrepAppliedImpactIDs).sorted(),
            "impact_last_action": todayPrepImpactLastAction,
            "impact_applied_count": todayPrepImpactAppliedCount,
            "line_gate_last_action": lineGateLastAction,
            "line_gate_completed": completed.contains("line-check") ? "1" : "0",
            "completion_block_reason": todayPrepCompletionBlockReason,
            "last_undo": lastTodayPrepUndo.map(todayPrepUndoValue) ?? [:],
            "holds": todayPrepHoldValues(),
            "active_hold_id": todayPrepActiveHold?.id ?? "",
        ])
    }

    private func todayPrepUndoValue(_ undo: TodayPrepUndo) -> [String: Any] {
        [
            "id": undo.id,
            "action": undo.action,
            "previous_completed_ids": undo.previousCompletedIDs,
            "next_completed_ids": undo.nextCompletedIDs,
            "message": undo.message,
        ]
    }

    private func todayPrepAssistProposalValue(_ proposal: TodayPrepAssistProposal) -> [String: String] {
        [
            "id": proposal.id,
            "title": proposal.title,
            "detail": proposal.detail,
            "action_label": proposal.actionLabel,
            "suggested_operator_id": proposal.suggestedOperatorID ?? "",
            "suggested_operator_name": proposal.suggestedOperatorName ?? "",
            "saves_minutes": String(proposal.savesMinutes),
            "shortfall_minutes": String(proposal.shortfallMinutes),
        ]
    }

    private func todayPrepETAValue(_ eta: ETA) -> [String: String] {
        [
            "landing": eta.landing,
            "delay_min": String(eta.delayMin),
            "time_to_open_min": String(eta.timeToOpenMin),
            "shortfall_min": String(eta.shortfallMin),
            "status": eta.status.rawValue,
        ]
    }

    private func todayPrepDynamicCheckValues() -> [[String: String]] {
        todayPrepDynamicChecks.map { check in
            [
                "id": check.id,
                "step_id": check.stepID,
                "title": check.title,
                "detail": check.detail,
            ]
        }
    }

    private func todayPrepHoldValues() -> [[String: String]] {
        todayPrepHoldHistory
            .filter { Self.focusStepIDs.contains($0.stepID) }
            .map { hold in
                [
                    "id": hold.id,
                    "step_id": hold.stepID,
                    "reason": hold.reason,
                    "paused_at": hold.pausedAt,
                    "resumed_at": hold.resumedAt ?? "",
                ]
            }
    }

    private func restoreTodayPrepOperationalState() {
        guard let value = try? database?.rows(.settings, tenantID: tenantID)
            .first(where: { $0.id == "setting-today-prep-state" })?
            .values["value"],
            let data = value.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return
        }

        if let completedIDs = object["completed_focus_ids"] as? [String] {
            completed.subtract(Self.focusStepIDs)
            completed.formUnion(completedIDs.filter(Self.focusStepIDs.contains))
        }
        restoreLineGateCompletionState(object)
        let selectedOperatorID = nonEmptySettingString(object["selected_operator_id"])
        if let operatorID = selectedOperatorID, todayPrepOperators.contains(where: { $0.id == operatorID }) {
            selectedTodayPrepOperatorID = operatorID
        }
        if let checks = object["dynamic_checks"] as? [[String: String]] {
            todayPrepDynamicChecks = checks.compactMap { values in
                guard let id = values["id"],
                      let stepID = values["step_id"],
                      let title = values["title"],
                      let detail = values["detail"],
                      Self.focusStepIDs.contains(stepID)
                else {
                    return nil
                }
                return TodayPrepCheck(id: id, stepID: stepID, title: title, detail: detail)
            }
        }
        restoreTodayPrepImpacts(object)
        todayPrepStartedAt = restoreTodayPrepTimeMap(object["started_at"])
        todayPrepCheckedAt = restoreTodayPrepTimeMap(object["checked_at"])
        todayPrepCompletedBy = restoreTodayPrepStringMap(object["completed_by"])
        todayPrepManualActualMinutes = restoreTodayPrepIntMap(object["manual_actual_minutes"])
        if let checkIDs = object["completed_check_ids"] as? [String] {
            todayPrepCompletedCheckIDs = Set(checkIDs.filter { todayPrepCheck($0) != nil })
        }
        if let holdValues = object["holds"] as? [[String: String]] {
            todayPrepHoldHistory = holdValues.compactMap(restoreTodayPrepHold)
        }
        if let activeHoldID = object["active_hold_id"] as? String, !activeHoldID.isEmpty {
            todayPrepActiveHold = todayPrepHoldHistory.first { $0.id == activeHoldID && $0.resumedAt == nil }
        }
        restoreTodayPrepAssistState(object)
        restoreTodayPrepUndoState(object)
        restoreTodayPrepActuals()
    }

    private func restoreLineGateCompletionState(_ object: [String: Any]) {
        if object["line_gate_completed"] as? String == "1" {
            completed.insert("line-check")
        } else {
            completed.remove("line-check")
        }
    }

    private func restoreTodayPrepUndoState(_ object: [String: Any]) {
        guard let values = object["last_undo"] as? [String: Any],
              let id = nonEmptySettingString(values["id"]),
              let action = nonEmptySettingString(values["action"]),
              let previous = values["previous_completed_ids"] as? [String],
              let next = values["next_completed_ids"] as? [String],
              !previous.isEmpty || !next.isEmpty
        else {
            lastTodayPrepUndo = nil
            return
        }
        lastTodayPrepUndo = TodayPrepUndo(
            id: id,
            action: action,
            previousCompletedIDs: previous,
            nextCompletedIDs: next,
            message: nonEmptySettingString(values["message"]) ?? "\(action) を取り消せます"
        )
    }

    private func restoreTodayPrepAssistState(_ object: [String: Any]) {
        todayPrepAssistRequestedAt = nonEmptySettingString(object["assist_requested_at"]) ?? todayPrepAssistRequestedAt
        if let proposal = restoreTodayPrepAssistProposal(object["assist_proposal"] as? [String: String]) {
            todayPrepAssistProposal = proposal
        }
        todayPrepAssistAppliedSummary = nonEmptySettingString(object["assist_applied_summary"])
        todayPrepAssistETAAfterApply = restoreTodayPrepETA(object["assist_eta_after_apply"] as? [String: String])
        todayPrepAssistAppliedSignature = nonEmptySettingString(object["assist_applied_signature"])
    }

    private func restoreTodayPrepAssistProposal(_ values: [String: String]?) -> TodayPrepAssistProposal? {
        guard let values,
              let id = values["id"],
              let title = values["title"],
              let detail = values["detail"],
              let actionLabel = values["action_label"],
              let savesMinutes = Int(values["saves_minutes"] ?? ""),
              let shortfallMinutes = Int(values["shortfall_minutes"] ?? ""),
              !id.isEmpty
        else {
            return nil
        }
        return TodayPrepAssistProposal(
            id: id,
            title: title,
            detail: detail,
            actionLabel: actionLabel,
            suggestedOperatorID: nonEmptySettingString(values["suggested_operator_id"]),
            suggestedOperatorName: nonEmptySettingString(values["suggested_operator_name"]),
            savesMinutes: savesMinutes,
            shortfallMinutes: shortfallMinutes
        )
    }

    private func restoreTodayPrepETA(_ values: [String: String]?) -> ETA? {
        guard let values,
              let landing = values["landing"],
              isValidOpenTime(landing),
              let delayMin = Int(values["delay_min"] ?? ""),
              let timeToOpenMin = Int(values["time_to_open_min"] ?? ""),
              let shortfallMin = Int(values["shortfall_min"] ?? "")
        else {
            return nil
        }
        return ETA(
            landing: landing,
            delayMin: delayMin,
            timeToOpenMin: timeToOpenMin,
            shortfallMin: shortfallMin,
            status: etaStatus(from: values["status"], delayMin: delayMin)
        )
    }

    private func todayPrepImpactValue(_ item: TodayPrepImpactItem) -> [String: String] {
        [
            "id": item.id,
            "title": item.title,
            "detail": item.detail,
            "source_label": item.sourceLabel,
            "action_label": item.actionLabel,
            "target_step_id": item.targetStepID,
            "check_title": item.checkTitle,
            "check_detail": item.checkDetail,
            "is_urgent": item.isUrgent ? "1" : "0",
        ]
    }

    private func restoreTodayPrepImpacts(_ object: [String: Any]) {
        todayPrepImpactItems = (object["impact_items"] as? [[String: String]] ?? [])
            .compactMap(restoreTodayPrepImpact)
        todayPrepAppliedImpactIDs = Set(object["applied_impact_ids"] as? [String] ?? [])
        todayPrepImpactLastAction = nonEmptySettingString(object["impact_last_action"]) ?? todayPrepImpactLastAction
        todayPrepImpactAppliedCount = settingInt(object, "impact_applied_count", defaultValue: todayPrepImpactAppliedCount)
        lineGateLastAction = nonEmptySettingString(object["line_gate_last_action"]) ?? lineGateLastAction
        todayPrepCompletionBlockReason = nonEmptySettingString(object["completion_block_reason"]) ?? todayPrepCompletionBlockReason
    }

    private func restoreTodayPrepImpact(_ values: [String: String]) -> TodayPrepImpactItem? {
        guard let id = values["id"],
              let title = values["title"],
              let detail = values["detail"],
              let sourceLabel = values["source_label"],
              let actionLabel = values["action_label"],
              let targetStepID = values["target_step_id"],
              let checkTitle = values["check_title"],
              let checkDetail = values["check_detail"],
              Self.focusStepIDs.contains(targetStepID)
        else {
            return nil
        }
        return TodayPrepImpactItem(
            id: id,
            title: title,
            detail: detail,
            sourceLabel: sourceLabel,
            actionLabel: actionLabel,
            targetStepID: targetStepID,
            checkTitle: checkTitle,
            checkDetail: checkDetail,
            isUrgent: values["is_urgent"] == "1"
        )
    }

    private func restoreTodayPrepTimeMap(_ value: Any?) -> [String: String] {
        restoreTodayPrepStringMap(value).filter { isValidOpenTime($0.value) }
    }

    private func restoreTodayPrepStringMap(_ value: Any?) -> [String: String] {
        guard let values = value as? [String: String] else {
            return [:]
        }
        return values.filter { Self.focusStepIDs.contains($0.key) }
    }

    private func restoreTodayPrepIntMap(_ value: Any?) -> [String: Int] {
        guard let values = value as? [String: Int] else {
            return [:]
        }
        return values.filter { Self.focusStepIDs.contains($0.key) && $0.value >= 0 }
    }

    private func restoreTodayPrepHold(_ values: [String: String]) -> TodayPrepHold? {
        guard let stepID = values["step_id"],
              let reason = values["reason"],
              let pausedAt = values["paused_at"],
              Self.focusStepIDs.contains(stepID),
              !reason.isEmpty,
              isValidOpenTime(pausedAt)
        else {
            return nil
        }
        let hold = Engine.todayPrepHold(stepID: stepID, reason: reason, pausedAt: pausedAt)
        guard let resumedAt = values["resumed_at"], !resumedAt.isEmpty else {
            return hold
        }
        guard isValidOpenTime(resumedAt), !isHHMM(resumedAt, before: pausedAt) else {
            return hold
        }
        return Engine.todayPrepResume(hold, resumedAt: resumedAt)
    }

    private func restoreTodayPrepActuals() {
        todayPrepActuals = [:]
        for stepID in completed.intersection(Self.focusStepIDs) {
            guard let step = Self.focusSteps.first(where: { $0.id == stepID }),
                  let startedAt = todayPrepStartedAt[stepID],
                  let checkedAt = todayPrepCheckedAt[stepID],
                  !isHHMM(checkedAt, before: startedAt)
            else {
                continue
            }
            if let manualActual = todayPrepManualActualMinutes[stepID] {
                todayPrepActuals[stepID] = Engine.todayPrepActualOverride(
                    taskID: stepID,
                    plannedMinutes: step.durationMin,
                    actualMinutes: manualActual,
                    startedAt: startedAt,
                    checkedAt: checkedAt
                )
            } else {
                todayPrepActuals[stepID] = Engine.todayPrepActual(
                    taskID: stepID,
                    plannedMinutes: step.durationMin,
                    startedAt: startedAt,
                    checkedAt: checkedAt
                )
            }
        }
    }

    private func persistTaskInstances() {
        for dish in catalog.dishes {
            for component in dish.components {
                for task in component.tasks {
                    let quantity = calcQty(task.engineTask, covers: service.omakaseCovers)
                    let scheduled = schedule(task: task.engineTask, serviceDate: service.date, t0: service.openTime, closedDates: [])
                    let id = "instance-\(task.id)"
                    let completedID = task.id.replacingOccurrences(of: "task-", with: "")
                    let isDone = completed.contains(completedID)
                    let status = isDone ? "done" : "not_started"
                    let checkedAt = todayPrepCheckedAt[completedID] ?? todayPrepCheckedAt["rest"]
                    let values: [String: String?] = [
                        "id": id,
                        "tenant_id": tenantID,
                        "service_day_id": service.id,
                        "prep_task_id": task.id,
                        "status": status,
                        "assignee_section_id": todayPrepAssigneeSectionID(for: completedID, fallbackSectionName: task.sectionName),
                        "completed_by": isDone ? todayPrepCompletedBy[completedID] : nil,
                        "checked_at": isDone ? checkedAt : nil,
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
            "scale_mode": scaleModeStorageValue(task.scaleMode),
            "coeff_per_cover": numberString(task.coeffPerCover),
            "yield": numberString(task.yieldPercent / 100),
            "round_step": numberString(task.roundStep),
            "unit": task.unit,
            "duration_min": String(task.durationMin),
            "lead_min_before_open": String(task.leadMinBeforeOpen),
            "shelf_life_days": String(task.shelfLifeDays),
            "section_id": sectionID(for: task.sectionName),
            "instruction": task.instruction,
            "sort": String(task.sort),
        ]
    }

    private func numberString(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 3)))
    }

    private func sectionID(for sectionName: String) -> String {
        switch sectionName {
        case "ガルド":
            sectionGardeID
        case "シャリ場":
            sectionShariID
        default:
            sectionOwnerID
        }
    }

    private func todayPrepAssigneeSectionID(for stepID: String, fallbackSectionName: String) -> String {
        guard Self.focusStepIDs.contains(stepID),
              let operatorID = currentTodayPrepStepAssignments[stepID]
        else {
            return sectionID(for: fallbackSectionName)
        }

        let sectionName = todayPrepOperators.first { $0.id == operatorID }?.sectionName ?? fallbackSectionName
        return sectionID(for: sectionName)
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

    private func taskStatusFromDB(_ value: String?) -> TaskStatus? {
        switch value {
        case "not_started", "notStarted":
            .notStarted
        case "in_progress", "inProgress":
            .inProgress
        case "done":
            .done
        default:
            nil
        }
    }

    private func etaStatusValue(_ status: ETAStatus) -> String {
        status.rawValue
    }

    private func etaStatus(from value: String?, delayMin: Int) -> ETAStatus {
        if let value, let status = ETAStatus(rawValue: value) {
            return status
        }
        if delayMin <= 0 {
            return .onTrack
        }
        return .atRisk
    }

    private func queueReservationTodayPrepImpact(_ diff: ReservationDiffSummary?, sourceLabel: String) {
        queueReservationIncreaseTodayPrepImpact(diff, sourceLabel: sourceLabel)
        queueReservationReductionTodayPrepImpact(diff, sourceLabel: sourceLabel)
    }

    private func queueReservationIncreaseTodayPrepImpact(_ diff: ReservationDiffSummary?, sourceLabel: String) {
        guard let diff, diff.addedCovers > 0 else {
            return
        }
        let addedQty = Int(reservationPlanDiff?.added.first?.qty ?? Double(diff.addedCovers * 14))
        upsertTodayPrepImpact(TodayPrepImpactItem(
            id: "impact-reservation-\(impactIDSource(sourceLabel))",
            title: "予約増 +\(diff.addedCovers)名",
            detail: "煮切り \(addedQty)ml 追加見込み。たまり工程で量を再確認。",
            sourceLabel: sourceLabel,
            actionLabel: "手順へ追加",
            targetStepID: todayPrepProgress.nextStepID ?? "tare",
            checkTitle: "追加 \(diff.addedCovers)名分の量を確認",
            checkDetail: "煮切り追加 \(addedQty)ml と皿数を合わせる",
            isUrgent: true
        ))
    }

    private func queueReservationReductionTodayPrepImpact(_ diff: ReservationDiffSummary?, sourceLabel: String) {
        guard
            let diff,
            diff.cancelledCovers > 0,
            let reduced = reservationPlanDiff?.reduced.first(where: \.carryoverCandidate)
        else {
            return
        }
        upsertTodayPrepImpact(TodayPrepImpactItem(
            id: "impact-reservation-reduced-\(impactIDSource(sourceLabel))",
            title: "予約減 -\(diff.cancelledCovers)名",
            detail: "推奨量 \(Int(reduced.newTotal))ml へ減。作り過ぎ分の保管・持越し・ラベルを確認。",
            sourceLabel: sourceLabel,
            actionLabel: "持越し確認",
            targetStepID: "rest",
            checkTitle: "予約減の持越し量を確認",
            checkDetail: "取消 \(diff.cancelledCovers)名、推奨 \(Int(reduced.newTotal))ml。保管・ラベル・廃棄なしを確認",
            isUrgent: true
        ))
    }

    private func queueGuestReplyTodayPrepImpact(reservationID: String, note: String) {
        upsertTodayPrepImpact(TodayPrepImpactItem(
            id: guestReplyImpactID(reservationID: reservationID),
            title: "返信変更あり",
            detail: "\(note)。味見後に席札・アレルギー表記を再確認。",
            sourceLabel: "ゲスト返信",
            actionLabel: "再確認を追加",
            targetStepID: "rest",
            checkTitle: "返信変更の席札を確認",
            checkDetail: "アレルギー参考・確認文・席札の表記を揃える",
            isUrgent: true
        ))
    }

    private func queueServiceSyncTodayPrepImpact(_ state: ServiceSyncState) {
        guard state.remainingCovers <= max(1, service.omakaseCovers / 2) else {
            return
        }
        upsertTodayPrepImpact(TodayPrepImpactItem(
            id: "impact-service-remaining",
            title: "残数 \(state.remainingCovers)食",
            detail: "POS/KDS残数が更新。追加仕込みを止め、保管・持越し判断へ寄せる。",
            sourceLabel: "残数同期",
            actionLabel: "残数確認を追加",
            targetStepID: todayPrepProgress.nextStepID ?? "rest",
            checkTitle: "残数に合わせて追加仕込みを止める",
            checkDetail: "残数 \(state.remainingCovers)食、提供済 \(state.servedCovers)食で保管量を確認",
            isUrgent: false
        ))
    }

    private func upsertTodayPrepImpact(_ item: TodayPrepImpactItem) {
        if let index = todayPrepImpactItems.firstIndex(where: { $0.id == item.id }) {
            todayPrepImpactItems[index] = item
        } else {
            todayPrepImpactItems.append(item)
        }
        todayPrepImpactLastAction = "\(item.sourceLabel): \(item.title)"
        persistTodayPrepOperationalState()
        persistEvent(
            type: "today_prep.impact_queued",
            payload: "{\"impact_id\":\"\(item.id)\",\"source\":\"\(item.sourceLabel)\",\"step_id\":\"\(item.targetStepID)\"}"
        )
    }

    private func lineGateBlockDetail(_ status: LineGateStatus) -> String {
        if status.unresolvedImpactCount > 0 {
            return "外部変化 \(status.unresolvedImpactCount)件を手順へ追加"
        }
        if status.recheckCount > 0 {
            return "返信変更の再確認 \(status.recheckCount)件"
        }
        if status.labelReprintRequired {
            return "席札再印刷待ち"
        }
        let remaining = max(0, status.totalCount - status.completedCount)
        return "残り \(remaining)工程"
    }

    private func stepTitle(for stepID: String) -> String {
        Self.focusSteps.first { $0.id == stepID }?.title ?? "次工程"
    }

    private func impactIDSource(_ source: String) -> String {
        source
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
    }
}

private extension ServiceDaySettings {
    var periodCode: String {
        periods.first(where: { $0.id == selectedPeriodID })?.servicePeriod ?? "dinner"
    }
}
