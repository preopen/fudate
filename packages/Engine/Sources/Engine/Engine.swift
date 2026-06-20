public func calcQty(_ task: PrepTask, covers: Int) -> Quantity {
    precondition(task.yield > 0, "yield must be greater than zero")

    switch task.scaleMode {
    case .perCover:
        let raw = Double(covers) * (task.coeffPerCover ?? 0) / task.yield
        let total = task.roundStep.map { roundNearest(raw, $0) } ?? raw
        return Quantity(raw: raw, total: total, unit: task.unit)
    case .perPortion:
        let total = Double(covers) * (task.coeffPerPortion ?? 0)
        return Quantity(raw: total, total: total, unit: task.unit)
    case .fixedBatch:
        let batches = ceilBatch(covers, task.coversPerBatch ?? 1)
        let total = Double(batches) * (task.batchSize ?? 0)
        return Quantity(raw: total, total: total, batches: batches, unit: task.unit)
    }
}

public func aggregateSubrecipes(_ subrecipe: PrepTask, references: [(course: String, covers: Int)]) -> AggregatedQuantity {
    let totalCovers = references.reduce(0) { $0 + $1.covers }
    let quantity = calcQty(subrecipe, covers: totalCovers)
    let sources = references.map { "\($0.course):\($0.covers)" }
    return AggregatedQuantity(task: subrecipe.id, totalCovers: totalCovers, quantity: quantity, sources: sources)
}

public func diffPlan(task: PrepTask, currentCovers: Int?, madeTotal: Double?, change: PlanChange) -> PlanDiff {
    switch change {
    case let .reservationAdded(deltaCovers, _):
        let qty = Double(deltaCovers) * (task.coeffPerCover ?? 0) / task.yield
        return PlanDiff(added: [AddItem(task: task.id, qty: qty, reason: .reservationIncrease)])
    case let .reservationCancelled(deltaCovers, _):
        let baseCovers = currentCovers ?? 0
        let newCovers = max(0, baseCovers + deltaCovers)
        let rawDelta = Double(deltaCovers) * (task.coeffPerCover ?? 0) / task.yield
        let newTotal = calcQty(task, covers: newCovers).total
        let reduced = ReduceItem(
            task: task.id,
            rawDelta: rawDelta,
            newCovers: newCovers,
            newTotal: newTotal,
            carryoverCandidate: task.status == .done
        )
        return PlanDiff(reduced: [reduced])
    case let .parDepleted(remainingQty, thresholdPct):
        let total = madeTotal ?? task.batchSize ?? 0
        let belowThreshold = total > 0 && remainingQty / total < thresholdPct
        let added = belowThreshold ? [AddItem(task: task.id, reason: .parDepleted, belowThreshold: true)] : []
        return PlanDiff(added: added)
    }
}

public func reservationImpactPlan(
    task: PrepTask,
    previousCovers: Int,
    madeTotal: Double?,
    diff: ReservationDiffSummary
) -> PlanDiff {
    var added: [AddItem] = []
    var reduced: [ReduceItem] = []

    if diff.addedCovers > 0 {
        let increase = diffPlan(
            task: task,
            currentCovers: previousCovers,
            madeTotal: madeTotal,
            change: .reservationAdded(deltaCovers: diff.addedCovers, course: "")
        )
        added.append(contentsOf: increase.added)
    }

    if diff.cancelledCovers > 0 {
        let cancellation = diffPlan(
            task: task,
            currentCovers: previousCovers,
            madeTotal: madeTotal,
            change: .reservationCancelled(deltaCovers: -diff.cancelledCovers, course: "")
        )
        reduced.append(contentsOf: cancellation.reduced)
    }

    return PlanDiff(added: added, reduced: reduced)
}

public func schedule(task: PrepTask, serviceDate: String, t0: String, closedDates: Set<String>) -> Scheduled {
    let t0Minutes = minutes(fromHHMM: t0)
    var absoluteStart = t0Minutes - task.leadMinBeforeOpen
    var prepDayOffset = floorDiv(absoluteStart, 1440)
    var startMinutes = mod(absoluteStart, 1440)
    var prepDate = addDays(to: serviceDate, days: prepDayOffset)
    var skipped: [String] = []

    while closedDates.contains(prepDate) {
        skipped.append(prepDate)
        prepDayOffset -= 1
        prepDate = addDays(to: serviceDate, days: prepDayOffset)
        absoluteStart -= 1440
        startMinutes = mod(absoluteStart, 1440)
    }

    let finishMinutes = startMinutes + task.durationMin
    return Scheduled(
        taskId: task.id,
        prepDayOffset: prepDayOffset,
        prepDate: skipped.isEmpty ? nil : prepDate,
        start: hhmm(fromMinutes: startMinutes),
        finish: hhmm(fromMinutes: finishMinutes),
        skipped: skipped
    )
}

public func planDayrail(
    prepTasks: [PrepTask],
    serviceDate: String,
    t0: String,
    closedDates: Set<String>,
    operations: [DayrailOperation] = []
) -> [DayrailItem] {
    let prepItems = prepTasks.map {
        dayrailItem(task: $0, serviceDate: serviceDate, t0: t0, closedDates: closedDates)
    }
    let operationItems = operations.map {
        dayrailItem(operation: $0, t0: t0)
    }
    return sortedDayrailItems(prepItems + operationItems)
}

private func dayrailItem(task: PrepTask, serviceDate: String, t0: String, closedDates: Set<String>) -> DayrailItem {
    let scheduled = schedule(task: task, serviceDate: serviceDate, t0: t0, closedDates: closedDates)
    return DayrailItem(
        id: "dayrail-\(task.id)",
        kind: .prep,
        refID: task.id,
        title: task.id,
        prepDayOffset: scheduled.prepDayOffset,
        start: scheduled.start,
        finish: scheduled.finish,
        status: task.status ?? .notStarted,
        sort: 0
    )
}

private func dayrailItem(operation: DayrailOperation, t0: String) -> DayrailItem {
    let absoluteStart = minutes(fromHHMM: t0) + operation.startOffsetMin
    let start = mod(absoluteStart, 1440)
    return DayrailItem(
        id: "dayrail-\(operation.id)",
        kind: operation.kind,
        refID: operation.id,
        title: operation.title,
        prepDayOffset: floorDiv(absoluteStart, 1440),
        start: hhmm(fromMinutes: start),
        finish: hhmm(fromMinutes: start + operation.durationMin),
        status: operation.status,
        sort: 0
    )
}

private func sortedDayrailItems(_ items: [DayrailItem]) -> [DayrailItem] {
    items.sorted {
        if $0.prepDayOffset != $1.prepDayOffset {
            return $0.prepDayOffset < $1.prepDayOffset
        }
        if minutes(fromHHMM: $0.start) != minutes(fromHHMM: $1.start) {
            return minutes(fromHHMM: $0.start) < minutes(fromHHMM: $1.start)
        }
        return $0.id < $1.id
    }
    .enumerated()
    .map { offset, item in
        DayrailItem(
            id: item.id,
            kind: item.kind,
            refID: item.refID,
            title: item.title,
            prepDayOffset: item.prepDayOffset,
            start: item.start,
            finish: item.finish,
            status: item.status,
            sort: offset
        )
    }
}

public func rollup(_ node: TaskNode) -> TaskNode {
    guard !node.children.isEmpty else {
        return TaskNode(id: node.id, status: node.status ?? .notStarted)
    }

    let rolledChildren = node.children.map(rollup)
    let statuses = rolledChildren.map { $0.status ?? .notStarted }
    let nextStatus: TaskStatus = if statuses.allSatisfy({ $0 == .done }) {
        .done
    } else if statuses.allSatisfy({ $0 == .notStarted }) {
        .notStarted
    } else {
        .inProgress
    }
    return TaskNode(id: node.id, status: nextStatus, children: rolledChildren)
}

public func etaProjection(now: String, t0: String, remainingDurationsMin: [Int], bufferMin: Int = 0) -> ETA {
    let nowMin = minutes(fromHHMM: now)
    let t0Min = minutes(fromHHMM: t0)
    let landingMin = nowMin + remainingDurationsMin.reduce(0, +)
    let delayMin = landingMin - t0Min
    let status: ETAStatus = if delayMin <= 0 {
        .onTrack
    } else if delayMin <= bufferMin {
        .tight
    } else {
        .atRisk
    }

    return ETA(
        landing: hhmm(fromMinutes: landingMin),
        delayMin: delayMin,
        timeToOpenMin: t0Min - nowMin,
        shortfallMin: max(0, delayMin),
        status: status
    )
}

public func selfCorrect(taskId: String, currentCoeffPerCover: Double, history: [WasteRecord], lookback: Int) -> CoeffSuggestion {
    let samples = history
        .filter { !$0.exclude && $0.covers > 0 }
        .prefix(lookback)
        .map { ($0.made - $0.leftover) / Double($0.covers) }
    let average = samples.isEmpty ? currentCoeffPerCover : samples.reduce(0, +) / Double(samples.count)
    let suggested = (average * 10).rounded() / 10
    return CoeffSuggestion(taskId: taskId, current: currentCoeffPerCover, suggested: suggested, samplesUsed: samples.count)
}

public func applyCarryover(
    plan: [(task: String, base: Double, unit: String)],
    leftovers: [(task: String, qty: Double, expired: Bool)]
) -> [(task: String, adjusted: Double, unit: String)] {
    plan.map { item in
        let carryover = leftovers
            .filter { $0.task == item.task && !$0.expired }
            .reduce(0) { $0 + $1.qty }
        return (task: item.task, adjusted: max(0, item.base - carryover), unit: item.unit)
    }
}

public func closeLoop(records: [CloseTaskRecord], nextDayPlan: [(task: String, base: Double, unit: String)]) -> CloseLoopSummary {
    let carryovers = records
        .filter { $0.carryoverToNext && $0.leftoverQty > 0 }
        .map { CarryoverItem(task: $0.task, qty: $0.leftoverQty, unit: $0.unit) }
    let adjusted = applyCarryover(
        plan: nextDayPlan,
        leftovers: carryovers.map { (task: $0.task, qty: $0.qty, expired: false) }
    )
    let adjustments = zip(nextDayPlan, adjusted).map { base, adjusted in
        NextDayAdjustment(task: base.task, base: base.base, adjusted: adjusted.adjusted, unit: adjusted.unit)
    }
    return CloseLoopSummary(records: records, carryovers: carryovers, nextDayAdjustments: adjustments)
}

public func learningWasteRecords(records: [CloseTaskRecord], serviceDate: String, covers: Int) -> [WasteRecord] {
    records.map {
        WasteRecord(
            serviceDate: serviceDate,
            covers: covers,
            made: $0.madeQty,
            leftover: $0.leftoverQty,
            exclude: $0.wasteReason != .overmade
        )
    }
}

public func issuePrepLabel(
    task: PrepTask,
    taskInstanceID: String,
    madeQty: Double,
    printedAt: String,
    storageUnitID: String? = nil
) -> PrepLabel {
    let shelfLifeDays = max(task.shelfLifeDays ?? 1, 0)
    let madeDate = String(printedAt.prefix(10))
    let expireDate = addDays(to: madeDate, days: shelfLifeDays)
    return PrepLabel(
        id: "label-\(taskInstanceID)",
        taskInstanceID: taskInstanceID,
        prepTaskID: task.id,
        madeQty: madeQty,
        unit: task.unit,
        printedAt: printedAt,
        expireAt: "\(expireDate)T23:59:00Z",
        qrToken: "prepflow://label/\(taskInstanceID)",
        storageUnitID: storageUnitID
    )
}

public func scanPrepLabel(_ label: PrepLabel, action: LabelScanAction) -> LabelScanResult {
    switch action {
    case let .remaining(qty):
        let remainingQty = max(0, min(qty, label.madeQty))
        let updatedLabel = updatedPrepLabel(label, status: .remaining, remainingQty: remainingQty)
        let larderItem = PrepLarderItem(
            id: "larder-\(label.id)",
            labelID: label.id,
            prepTaskID: label.prepTaskID,
            qty: remainingQty,
            unit: label.unit,
            expireAt: label.expireAt,
            status: remainingQty > 0 ? .available : .used
        )
        return LabelScanResult(label: updatedLabel, larderItem: larderItem, wasteRecord: nil)
    case .used:
        let updatedLabel = updatedPrepLabel(label, status: .used, remainingQty: 0)
        let larderItem = PrepLarderItem(
            id: "larder-\(label.id)",
            labelID: label.id,
            prepTaskID: label.prepTaskID,
            qty: 0,
            unit: label.unit,
            expireAt: label.expireAt,
            status: .used
        )
        return LabelScanResult(label: updatedLabel, larderItem: larderItem, wasteRecord: nil)
    case let .wasted(qty, reason):
        let wastedQty = max(0, min(qty, label.madeQty))
        let updatedLabel = updatedPrepLabel(label, status: .wasted, remainingQty: 0)
        let larderItem = PrepLarderItem(
            id: "larder-\(label.id)",
            labelID: label.id,
            prepTaskID: label.prepTaskID,
            qty: 0,
            unit: label.unit,
            expireAt: label.expireAt,
            status: .wasted
        )
        let waste = CloseTaskRecord(
            task: label.prepTaskID,
            plannedQty: label.madeQty,
            madeQty: label.madeQty,
            leftoverQty: wastedQty,
            unit: label.unit,
            wasteReason: reason,
            carryoverToNext: false
        )
        return LabelScanResult(label: updatedLabel, larderItem: larderItem, wasteRecord: waste)
    }
}

private func updatedPrepLabel(_ label: PrepLabel, status: PrepLabelStatus, remainingQty: Double?) -> PrepLabel {
    PrepLabel(
        id: label.id,
        taskInstanceID: label.taskInstanceID,
        prepTaskID: label.prepTaskID,
        madeQty: label.madeQty,
        unit: label.unit,
        printedAt: label.printedAt,
        expireAt: label.expireAt,
        qrToken: label.qrToken,
        status: status,
        remainingQty: remainingQty,
        storageUnitID: label.storageUnitID
    )
}

public func reservationDiff(previous: [ReservationSnapshot], current: [ReservationSnapshot]) -> ReservationDiffSummary {
    let previousByID = Dictionary(uniqueKeysWithValues: previous.map { ($0.id, $0) })
    let currentByID = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
    var addedCovers = 0
    var cancelledCovers = 0
    var changedReservationIDs: [String] = []

    for reservation in current where previousByID[reservation.id] == nil && reservation.status != "cancelled" {
        addedCovers += reservation.covers
        changedReservationIDs.append(reservation.id)
    }

    for reservation in previous where currentByID[reservation.id] == nil {
        cancelledCovers += reservation.covers
        changedReservationIDs.append(reservation.id)
    }

    for reservation in current {
        guard let old = previousByID[reservation.id], old != reservation else {
            continue
        }
        let delta = reservation.covers - old.covers
        if reservation.status == "cancelled", old.status != "cancelled" {
            cancelledCovers += old.covers
        } else if delta > 0 {
            addedCovers += delta
        } else if delta < 0 {
            cancelledCovers += abs(delta)
        }
        changedReservationIDs.append(reservation.id)
    }

    return ReservationDiffSummary(
        addedCovers: addedCovers,
        cancelledCovers: cancelledCovers,
        changedReservationIDs: Array(Set(changedReservationIDs)).sorted()
    )
}

public func normalizeReservationEvent(_ event: SourceReservationEvent) -> NormalizedReservation {
    let prepNotes = [event.allergyNote, event.vipRank.map { "VIP:\($0)" }]
        .compactMap(\.self)
        .filter { !$0.isEmpty }
        .joined(separator: " / ")
    return NormalizedReservation(
        id: "reservation-\(event.provider.rawValue)-\(event.externalID)",
        source: event.provider.rawValue,
        externalID: event.externalID,
        visitTime: event.visitTime,
        covers: max(0, event.covers),
        course: event.course,
        partyName: event.partyName,
        status: event.status,
        prepNote: prepNotes.isEmpty ? nil : prepNotes
    )
}

public func reservationSnapshot(_ reservation: NormalizedReservation) -> ReservationSnapshot? {
    guard reservation.status != "cancelled" else {
        return nil
    }
    return ReservationSnapshot(id: reservation.id, covers: reservation.covers, course: reservation.course, status: reservation.status)
}

public func startDirectBookingCheckout(_ booking: DirectBooking, depositRequired: Bool) -> DirectBookingCheckout {
    DirectBookingCheckout(
        id: "checkout-\(booking.id)",
        bookingID: booking.id,
        checkoutID: depositRequired ? "stripe-\(booking.id)" : nil,
        status: .request,
        depositRequired: depositRequired
    )
}

public func normalizeDirectBooking(_ booking: DirectBooking) -> NormalizedReservation {
    NormalizedReservation(
        id: "reservation-direct-\(booking.id)",
        source: "direct",
        externalID: booking.id,
        visitTime: booking.visitTime,
        covers: max(0, booking.covers),
        course: booking.course,
        partyName: booking.guestName,
        status: booking.status.rawValue,
        prepNote: booking.guestNote?.isEmpty == false ? booking.guestNote : nil
    )
}

public func evaluateDirectBooking(_ booking: DirectBooking, allotment: DirectAllotment) -> DirectBookingDecision {
    let requested = max(0, booking.covers)
    let remaining = max(0, allotment.allottedCovers - allotment.bookedCovers)
    if requested <= remaining {
        return DirectBookingDecision(
            status: .confirmed,
            confirmedCovers: requested,
            waitlistCovers: 0,
            remainingAllotment: remaining - requested,
            reason: "available"
        )
    }
    return DirectBookingDecision(
        status: .request,
        confirmedCovers: 0,
        waitlistCovers: requested,
        remainingAllotment: remaining,
        reason: "waitlist"
    )
}

public func promoteDirectWaitlist(_ booking: DirectBooking, allotment: DirectAllotment) -> DirectWaitlistPromotion {
    let requested = max(0, booking.covers)
    let remaining = max(0, allotment.allottedCovers - allotment.bookedCovers)
    guard requested > 0 else {
        return DirectWaitlistPromotion(
            id: "promotion-\(booking.id)",
            directBookingID: booking.id,
            status: .request,
            promotedCovers: 0,
            remainingAllotment: remaining,
            reason: "empty_request"
        )
    }
    guard requested <= remaining else {
        return DirectWaitlistPromotion(
            id: "promotion-\(booking.id)",
            directBookingID: booking.id,
            status: .request,
            promotedCovers: 0,
            remainingAllotment: remaining,
            reason: "insufficient_allotment"
        )
    }
    return DirectWaitlistPromotion(
        id: "promotion-\(booking.id)",
        directBookingID: booking.id,
        status: .confirmed,
        promotedCovers: requested,
        remainingAllotment: remaining - requested,
        reason: "promoted"
    )
}

public func recordDirectNoShow(_ booking: DirectBooking, forfeitsDeposit: Bool) -> DirectNoShowSettlement {
    DirectNoShowSettlement(
        id: "noshow-\(booking.id)",
        bookingID: booking.id,
        status: .noshow,
        forfeitsDeposit: forfeitsDeposit,
        prepImpactCovers: max(0, booking.covers)
    )
}

public func fifoLarder(_ items: [PrepLarderItem], nowDate: String, alertWithinDays: Int = 1) -> [LarderAlert] {
    items
        .filter { $0.status == .available && $0.qty > 0 }
        .sorted {
            if $0.expireAt != $1.expireAt {
                return $0.expireAt < $1.expireAt
            }
            return $0.id < $1.id
        }
        .map { item in
            let level = larderAlertLevel(expireAt: item.expireAt, nowDate: nowDate, alertWithinDays: alertWithinDays)
            return LarderAlert(
                id: "larder-alert-\(item.id)",
                labelID: item.labelID,
                prepTaskID: item.prepTaskID,
                qty: item.qty,
                unit: item.unit,
                expireAt: item.expireAt,
                level: level
            )
        }
}

public func planLarderConsumption(_ items: [PrepLarderItem], requiredQty: Double, unit: String, nowDate: String) -> LarderConsumptionPlan {
    var remaining = max(0, requiredQty)
    var uses: [LarderUse] = []

    for item in consumableLarderItems(items, nowDate: nowDate) where remaining > 0 {
        let used = min(item.qty, remaining)
        uses.append(LarderUse(
            id: "larder-use-\(item.id)",
            labelID: item.labelID,
            prepTaskID: item.prepTaskID,
            qty: used,
            unit: item.unit,
            expireAt: item.expireAt
        ))
        remaining -= used
    }

    return LarderConsumptionPlan(
        uses: uses,
        requestedQty: max(0, requiredQty),
        plannedQty: max(0, requiredQty) - remaining,
        shortfallQty: remaining,
        unit: unit
    )
}

public func guestSignals(from reservation: NormalizedReservation) -> [GuestSignal] {
    let note = reservation.prepNote ?? ""
    var signals: [GuestSignal] = []
    if containsCaseInsensitive(note, "NG") || containsCaseInsensitive(note, "allergy") {
        signals.append(GuestSignal(id: "signal-allergy-\(reservation.id)", reservationID: reservation.id, kind: .allergy, text: note))
    }
    if containsCaseInsensitive(note, "VIP") {
        signals.append(GuestSignal(id: "signal-vip-\(reservation.id)", reservationID: reservation.id, kind: .vip, text: note))
    }
    if containsCaseInsensitive(note, "記念日") || containsCaseInsensitive(note, "special") {
        signals.append(GuestSignal(id: "signal-special-\(reservation.id)", reservationID: reservation.id, kind: .special, text: note))
    }
    return signals
}

public func specialPrepTasks(from signals: [GuestSignal]) -> [SpecialPrepTask] {
    signals.filter { $0.kind == .vip || $0.kind == .special }.map {
        SpecialPrepTask(
            id: "special-prep-\($0.id)",
            reservationID: $0.reservationID,
            title: $0.kind == .vip ? "VIP対応" : "特別仕込み",
            note: $0.text
        )
    }
}

public func allergenLabels(from signals: [GuestSignal], seatRef: String, language: String = "ja") -> [AllergenLabel] {
    signals.filter { $0.kind == .allergy }.map {
        let prefix = language == "en" ? "Allergy note" : "アレルギー参考"
        return AllergenLabel(
            id: "allergen-label-\($0.id)-\(seatRef)",
            reservationID: $0.reservationID,
            seatRef: seatRef,
            displayText: "\(seatRef) \(prefix): \($0.text)",
            language: language
        )
    }
}

public func guestConfirmationMessage(_ reservation: NormalizedReservation, language: String = "ja") -> GuestMessage {
    let body = if language == "en" {
        "We have your reservation at \(reservation.visitTime) for \(reservation.covers). Please tell us if any notes changed."
    } else {
        "\(reservation.visitTime) \(reservation.covers)名様で承っています。変更があればお知らせください。"
    }
    return GuestMessage(
        id: "guest-message-\(reservation.id)-\(language)",
        reservationID: reservation.id,
        language: language,
        body: body
    )
}

public func serviceSyncState(
    plannedCovers: Int,
    events: [ServiceSyncEvent],
    elapsedMinutes: Int,
    serviceMinutes: Int
) -> ServiceSyncState {
    var firedCovers = 0
    var heldCovers = 0
    var servedCovers = 0
    var syncedRemainingCovers: Int?

    for event in events {
        let covers = max(0, event.covers)
        switch event.kind {
        case .fire:
            firedCovers += covers
        case .hold:
            heldCovers += covers
        case .served:
            servedCovers += covers
        case .remainingSync:
            syncedRemainingCovers = covers
        }
    }

    servedCovers = min(max(0, servedCovers), plannedCovers)
    let remainingCovers = syncedRemainingCovers ?? max(0, plannedCovers - servedCovers)
    let pacing = pacingProposal(
        plannedCovers: plannedCovers,
        actualServed: servedCovers,
        elapsedMinutes: elapsedMinutes,
        serviceMinutes: serviceMinutes
    )

    return ServiceSyncState(
        firedCovers: firedCovers,
        heldCovers: heldCovers,
        servedCovers: servedCovers,
        remainingCovers: max(0, remainingCovers),
        pendingOfflineEvents: events.count(where: { $0.offlineSequence != nil }),
        pacing: pacing
    )
}

public func replayServiceEvents(
    plannedCovers: Int,
    events: [ServiceSyncEvent],
    elapsedMinutes: Int,
    serviceMinutes: Int
) -> ServiceReplaySummary {
    var seen: Set<String> = []
    var accepted: [ServiceSyncEvent] = []
    var duplicates: [String] = []

    for event in events {
        if seen.contains(event.id) {
            duplicates.append(event.id)
        } else {
            seen.insert(event.id)
            accepted.append(event)
        }
    }

    return ServiceReplaySummary(
        state: serviceSyncState(
            plannedCovers: plannedCovers,
            events: accepted,
            elapsedMinutes: elapsedMinutes,
            serviceMinutes: serviceMinutes
        ),
        acceptedEventIDs: accepted.map(\.id),
        ignoredDuplicateEventIDs: duplicates
    )
}

public func servicePassState(syncState: ServiceSyncState, seatFlags: [PassSeatFlag]) -> ServicePassState {
    ServicePassState(
        firedCovers: syncState.firedCovers,
        heldCovers: syncState.heldCovers,
        seatFlags: seatFlags.sorted { $0.id < $1.id },
        recommendation: syncState.pacing.recommendation
    )
}

public func storeServiceSummary(
    restaurantID: String,
    restaurantName: String,
    serviceDate: String,
    syncState: ServiceSyncState
) -> StoreServiceSummary {
    StoreServiceSummary(
        id: "store-summary-\(restaurantID)-\(serviceDate)",
        restaurantName: restaurantName,
        serviceDate: serviceDate,
        remainingCovers: syncState.remainingCovers,
        recommendation: syncState.pacing.recommendation
    )
}

public func multistoreServiceSummary(_ summaries: [StoreServiceSummary]) -> StoreServiceSummary {
    let remaining = summaries.reduce(0) { $0 + $1.remainingCovers }
    let recommendation = if summaries.contains(where: { $0.recommendation == "fire" }) {
        "fire"
    } else if summaries.contains(where: { $0.recommendation == "hold" }) {
        "hold"
    } else {
        "keep"
    }
    return StoreServiceSummary(
        id: "store-summary-all",
        restaurantName: "全店舗",
        serviceDate: summaries.map(\.serviceDate).sorted().first ?? "",
        remainingCovers: remaining,
        recommendation: recommendation
    )
}

public func pacingProposal(plannedCovers: Int, actualServed: Int, elapsedMinutes: Int, serviceMinutes: Int) -> PacingProposal {
    precondition(serviceMinutes > 0, "serviceMinutes must be greater than zero")
    let progress = min(max(Double(elapsedMinutes) / Double(serviceMinutes), 0), 1)
    let expectedServed = Int((Double(plannedCovers) * progress).rounded())
    let delta = actualServed - expectedServed
    let recommendation = if delta >= 3 {
        "hold"
    } else if delta <= -3 {
        "fire"
    } else {
        "keep"
    }
    return PacingProposal(expectedServed: expectedServed, actualServed: actualServed, delta: delta, recommendation: recommendation)
}

public func roundNearest(_ x: Double, _ step: Double) -> Double {
    precondition(step > 0, "round step must be greater than zero")
    return (x / step).rounded() * step
}

public func ceilBatch(_ covers: Int, _ per: Int) -> Int {
    precondition(per > 0, "covers per batch must be greater than zero")
    return Int((Double(covers) / Double(per)).rounded(.up))
}

func minutes(fromHHMM value: String) -> Int {
    let parts = value.split(separator: ":").map { Int($0) ?? 0 }
    return (parts.first ?? 0) * 60 + (parts.dropFirst().first ?? 0)
}

func hhmm(fromMinutes value: Int) -> String {
    let normalized = mod(value, 1440)
    let hours = normalized / 60
    let minutes = normalized % 60
    return "\(padded2(hours)):\(padded2(minutes))"
}

func padded2(_ value: Int) -> String {
    value < 10 ? "0\(value)" : "\(value)"
}

func floorDiv(_ lhs: Int, _ rhs: Int) -> Int {
    var quotient = lhs / rhs
    let remainder = lhs % rhs
    if remainder != 0, (remainder > 0) != (rhs > 0) {
        quotient -= 1
    }
    return quotient
}

func mod(_ lhs: Int, _ rhs: Int) -> Int {
    let value = lhs % rhs
    return value >= 0 ? value : value + rhs
}

func containsCaseInsensitive(_ value: String, _ token: String) -> Bool {
    value.lowercased().contains(token.lowercased())
}

func larderAlertLevel(expireAt: String, nowDate: String, alertWithinDays: Int) -> String {
    let expireDate = String(expireAt.prefix(10))
    if expireDate < nowDate {
        return "expired"
    }
    let warningDate = addDays(to: nowDate, days: max(0, alertWithinDays))
    if expireDate <= warningDate {
        return "due"
    }
    return "ok"
}

func consumableLarderItems(_ items: [PrepLarderItem], nowDate: String) -> [PrepLarderItem] {
    items
        .filter {
            $0.status == .available &&
                $0.qty > 0 &&
                String($0.expireAt.prefix(10)) >= nowDate
        }
        .sorted {
            if $0.expireAt != $1.expireAt {
                return $0.expireAt < $1.expireAt
            }
            return $0.id < $1.id
        }
}

func addDays(to isoDate: String, days: Int) -> String {
    let parts = isoDate.split(separator: "-").map { Int($0) ?? 0 }
    let year = parts[0]
    let month = parts[1]
    let day = parts[2]
    let serial = daysFromCivil(year: year, month: month, day: day) + days
    let result = civilFromDays(serial)
    return "\(padded4(result.year))-\(padded2(result.month))-\(padded2(result.day))"
}

func padded4(_ value: Int) -> String {
    if value < 10 { return "000\(value)" }
    if value < 100 { return "00\(value)" }
    if value < 1000 { return "0\(value)" }
    return "\(value)"
}

func daysFromCivil(year: Int, month: Int, day: Int) -> Int {
    var y = year
    let m = month
    y -= m <= 2 ? 1 : 0
    let era = floorDiv(y, 400)
    let yoe = y - era * 400
    let mp = m + (m > 2 ? -3 : 9)
    let doy = (153 * mp + 2) / 5 + day - 1
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
    return era * 146_097 + doe - 719_468
}

func civilFromDays(_ days: Int) -> (year: Int, month: Int, day: Int) {
    let z = days + 719_468
    let era = floorDiv(z, 146_097)
    let doe = z - era * 146_097
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365
    var year = yoe + era * 400
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
    let mp = (5 * doy + 2) / 153
    let day = doy - (153 * mp + 2) / 5 + 1
    let month = mp + (mp < 10 ? 3 : -9)
    year += month <= 2 ? 1 : 0
    return (year, month, day)
}
