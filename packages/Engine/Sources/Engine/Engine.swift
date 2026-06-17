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
