public enum ScaleMode: String, Codable, Sendable {
    case perCover
    case perPortion
    case fixedBatch

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "per_cover", "perCover":
            self = .perCover
        case "per_portion", "perPortion":
            self = .perPortion
        case "fixed_batch", "fixedBatch":
            self = .fixedBatch
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown scale mode \(rawValue)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .perCover:
            try container.encode("per_cover")
        case .perPortion:
            try container.encode("per_portion")
        case .fixedBatch:
            try container.encode("fixed_batch")
        }
    }
}

public enum TaskStatus: String, Codable, Sendable {
    case notStarted
    case inProgress
    case done

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "not_started", "notStarted":
            self = .notStarted
        case "in_progress", "inProgress":
            self = .inProgress
        case "done":
            self = .done
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown status \(rawValue)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .notStarted:
            try container.encode("not_started")
        case .inProgress:
            try container.encode("in_progress")
        case .done:
            try container.encode("done")
        }
    }
}

public struct PrepTask: Codable, Sendable, Identifiable {
    public let id: String
    public var scaleMode: ScaleMode
    public var coeffPerCover: Double?
    public var coeffPerPortion: Double?
    public var yield: Double
    public var roundStep: Double?
    public var coversPerBatch: Int?
    public var batchSize: Double?
    public var unit: String
    public var durationMin: Int
    public var leadMinBeforeOpen: Int
    public var shelfLifeDays: Int?
    public var section: String?
    public var status: TaskStatus?

    private enum CodingKeys: String, CodingKey {
        case id
        case scaleMode
        case coeffPerCover
        case coeffPerPortion
        case yield
        case roundStep
        case coversPerBatch
        case batchSize
        case unit
        case durationMin
        case leadMinBeforeOpen
        case shelfLifeDays
        case section
        case status
    }

    public init(
        id: String,
        scaleMode: ScaleMode,
        coeffPerCover: Double? = nil,
        coeffPerPortion: Double? = nil,
        yield: Double = 1,
        roundStep: Double? = nil,
        coversPerBatch: Int? = nil,
        batchSize: Double? = nil,
        unit: String = "",
        durationMin: Int = 0,
        leadMinBeforeOpen: Int = 0,
        shelfLifeDays: Int? = nil,
        section: String? = nil,
        status: TaskStatus? = nil
    ) {
        self.id = id
        self.scaleMode = scaleMode
        self.coeffPerCover = coeffPerCover
        self.coeffPerPortion = coeffPerPortion
        self.yield = yield
        self.roundStep = roundStep
        self.coversPerBatch = coversPerBatch
        self.batchSize = batchSize
        self.unit = unit
        self.durationMin = durationMin
        self.leadMinBeforeOpen = leadMinBeforeOpen
        self.shelfLifeDays = shelfLifeDays
        self.section = section
        self.status = status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        scaleMode = try container.decodeIfPresent(ScaleMode.self, forKey: .scaleMode) ?? .perCover
        coeffPerCover = try container.decodeIfPresent(Double.self, forKey: .coeffPerCover)
        coeffPerPortion = try container.decodeIfPresent(Double.self, forKey: .coeffPerPortion)
        yield = try container.decodeIfPresent(Double.self, forKey: .yield) ?? 1
        roundStep = try container.decodeIfPresent(Double.self, forKey: .roundStep)
        coversPerBatch = try container.decodeIfPresent(Int.self, forKey: .coversPerBatch)
        batchSize = try container.decodeIfPresent(Double.self, forKey: .batchSize)
        unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? ""
        durationMin = try container.decodeIfPresent(Int.self, forKey: .durationMin) ?? 0
        leadMinBeforeOpen = try container.decodeIfPresent(Int.self, forKey: .leadMinBeforeOpen) ?? 0
        shelfLifeDays = try container.decodeIfPresent(Int.self, forKey: .shelfLifeDays)
        section = try container.decodeIfPresent(String.self, forKey: .section)
        status = try container.decodeIfPresent(TaskStatus.self, forKey: .status)
    }
}

public struct Quantity: Codable, Sendable, Equatable {
    public var raw: Double
    public var total: Double
    public var batches: Int?
    public var unit: String

    public init(raw: Double, total: Double, batches: Int? = nil, unit: String) {
        self.raw = raw
        self.total = total
        self.batches = batches
        self.unit = unit
    }
}

public struct AggregatedQuantity: Sendable, Equatable {
    public var task: String
    public var totalCovers: Int
    public var quantity: Quantity
    public var sources: [String]

    public init(task: String, totalCovers: Int, quantity: Quantity, sources: [String]) {
        self.task = task
        self.totalCovers = totalCovers
        self.quantity = quantity
        self.sources = sources
    }
}

public enum PlanChange: Sendable, Equatable {
    case reservationAdded(deltaCovers: Int, course: String)
    case reservationCancelled(deltaCovers: Int, course: String)
    case parDepleted(remainingQty: Double, thresholdPct: Double)
}

public enum AddReason: String, Sendable {
    case reservationIncrease = "reservation_increase"
    case parDepleted = "par_depleted"
}

public struct AddItem: Sendable, Equatable {
    public var task: String
    public var qty: Double?
    public var reason: AddReason
    public var belowThreshold: Bool?

    public init(task: String, qty: Double? = nil, reason: AddReason, belowThreshold: Bool? = nil) {
        self.task = task
        self.qty = qty
        self.reason = reason
        self.belowThreshold = belowThreshold
    }
}

public struct ReduceItem: Sendable, Equatable {
    public var task: String
    public var rawDelta: Double
    public var newCovers: Int
    public var newTotal: Double
    public var carryoverCandidate: Bool

    public init(task: String, rawDelta: Double, newCovers: Int, newTotal: Double, carryoverCandidate: Bool) {
        self.task = task
        self.rawDelta = rawDelta
        self.newCovers = newCovers
        self.newTotal = newTotal
        self.carryoverCandidate = carryoverCandidate
    }
}

public struct PlanDiff: Sendable, Equatable {
    public var added: [AddItem]
    public var reduced: [ReduceItem]

    public init(added: [AddItem] = [], reduced: [ReduceItem] = []) {
        self.added = added
        self.reduced = reduced
    }
}

public struct Scheduled: Sendable, Equatable {
    public var taskId: String
    public var prepDayOffset: Int
    public var prepDate: String?
    public var start: String
    public var finish: String
    public var skipped: [String]

    public init(taskId: String, prepDayOffset: Int, prepDate: String? = nil, start: String, finish: String, skipped: [String] = []) {
        self.taskId = taskId
        self.prepDayOffset = prepDayOffset
        self.prepDate = prepDate
        self.start = start
        self.finish = finish
        self.skipped = skipped
    }
}

public enum DayrailKind: String, Sendable, Equatable {
    case prep
    case service
    case close
}

public struct DayrailOperation: Sendable, Equatable, Identifiable {
    public var id: String
    public var kind: DayrailKind
    public var title: String
    public var startOffsetMin: Int
    public var durationMin: Int
    public var status: TaskStatus

    public init(
        id: String,
        kind: DayrailKind,
        title: String,
        startOffsetMin: Int,
        durationMin: Int,
        status: TaskStatus = .notStarted
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.startOffsetMin = startOffsetMin
        self.durationMin = durationMin
        self.status = status
    }
}

public struct DayrailItem: Sendable, Equatable, Identifiable {
    public var id: String
    public var kind: DayrailKind
    public var refID: String
    public var title: String
    public var prepDayOffset: Int
    public var start: String
    public var finish: String
    public var status: TaskStatus
    public var sort: Int

    public init(
        id: String,
        kind: DayrailKind,
        refID: String,
        title: String,
        prepDayOffset: Int,
        start: String,
        finish: String,
        status: TaskStatus,
        sort: Int
    ) {
        self.id = id
        self.kind = kind
        self.refID = refID
        self.title = title
        self.prepDayOffset = prepDayOffset
        self.start = start
        self.finish = finish
        self.status = status
        self.sort = sort
    }
}

public struct TaskNode: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var status: TaskStatus?
    public var children: [TaskNode]

    public init(id: String, status: TaskStatus? = nil, children: [TaskNode] = []) {
        self.id = id
        self.status = status
        self.children = children
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case status
        case children
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        status = try container.decodeIfPresent(TaskStatus.self, forKey: .status)
        children = try container.decodeIfPresent([TaskNode].self, forKey: .children) ?? []
    }
}

public enum ETAStatus: String, Sendable, Equatable {
    case onTrack = "on_track"
    case tight
    case atRisk = "at_risk"
}

public struct ETA: Sendable, Equatable {
    public var landing: String
    public var delayMin: Int
    public var timeToOpenMin: Int
    public var shortfallMin: Int
    public var status: ETAStatus

    public init(landing: String, delayMin: Int, timeToOpenMin: Int, shortfallMin: Int, status: ETAStatus) {
        self.landing = landing
        self.delayMin = delayMin
        self.timeToOpenMin = timeToOpenMin
        self.shortfallMin = shortfallMin
        self.status = status
    }
}

public struct WasteRecord: Codable, Sendable {
    public var serviceDate: String
    public var covers: Int
    public var made: Double
    public var leftover: Double
    public var exclude: Bool

    public init(serviceDate: String, covers: Int, made: Double, leftover: Double, exclude: Bool = false) {
        self.serviceDate = serviceDate
        self.covers = covers
        self.made = made
        self.leftover = leftover
        self.exclude = exclude
    }

    private enum CodingKeys: String, CodingKey {
        case serviceDate
        case covers
        case made
        case leftover
        case exclude
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        serviceDate = try container.decode(String.self, forKey: .serviceDate)
        covers = try container.decode(Int.self, forKey: .covers)
        made = try container.decode(Double.self, forKey: .made)
        leftover = try container.decode(Double.self, forKey: .leftover)
        exclude = try container.decodeIfPresent(Bool.self, forKey: .exclude) ?? false
    }
}

public enum WasteReason: String, Codable, Sendable, Equatable {
    case overmade
    case expiry
    case quality
    case other
}

public struct CloseTaskRecord: Sendable, Equatable {
    public var task: String
    public var plannedQty: Double
    public var madeQty: Double
    public var leftoverQty: Double
    public var unit: String
    public var wasteReason: WasteReason
    public var carryoverToNext: Bool

    public init(
        task: String,
        plannedQty: Double,
        madeQty: Double,
        leftoverQty: Double,
        unit: String,
        wasteReason: WasteReason,
        carryoverToNext: Bool
    ) {
        self.task = task
        self.plannedQty = plannedQty
        self.madeQty = madeQty
        self.leftoverQty = leftoverQty
        self.unit = unit
        self.wasteReason = wasteReason
        self.carryoverToNext = carryoverToNext
    }
}

public struct CarryoverItem: Sendable, Equatable {
    public var task: String
    public var qty: Double
    public var unit: String

    public init(task: String, qty: Double, unit: String) {
        self.task = task
        self.qty = qty
        self.unit = unit
    }
}

public struct NextDayAdjustment: Sendable, Equatable {
    public var task: String
    public var base: Double
    public var adjusted: Double
    public var unit: String

    public init(task: String, base: Double, adjusted: Double, unit: String) {
        self.task = task
        self.base = base
        self.adjusted = adjusted
        self.unit = unit
    }
}

public struct CloseLoopSummary: Sendable, Equatable {
    public var records: [CloseTaskRecord]
    public var carryovers: [CarryoverItem]
    public var nextDayAdjustments: [NextDayAdjustment]

    public init(records: [CloseTaskRecord], carryovers: [CarryoverItem], nextDayAdjustments: [NextDayAdjustment]) {
        self.records = records
        self.carryovers = carryovers
        self.nextDayAdjustments = nextDayAdjustments
    }
}

public enum PrepLabelStatus: String, Sendable, Equatable {
    case active
    case remaining
    case used
    case wasted
}

public struct PrepLabel: Sendable, Equatable, Identifiable {
    public var id: String
    public var taskInstanceID: String
    public var prepTaskID: String
    public var madeQty: Double
    public var unit: String
    public var printedAt: String
    public var expireAt: String
    public var qrToken: String
    public var status: PrepLabelStatus
    public var remainingQty: Double?
    public var storageUnitID: String?

    public init(
        id: String,
        taskInstanceID: String,
        prepTaskID: String,
        madeQty: Double,
        unit: String,
        printedAt: String,
        expireAt: String,
        qrToken: String,
        status: PrepLabelStatus = .active,
        remainingQty: Double? = nil,
        storageUnitID: String? = nil
    ) {
        self.id = id
        self.taskInstanceID = taskInstanceID
        self.prepTaskID = prepTaskID
        self.madeQty = madeQty
        self.unit = unit
        self.printedAt = printedAt
        self.expireAt = expireAt
        self.qrToken = qrToken
        self.status = status
        self.remainingQty = remainingQty
        self.storageUnitID = storageUnitID
    }
}

public enum LarderStatus: String, Sendable, Equatable {
    case available
    case used
    case wasted
    case expired
}

public struct PrepLarderItem: Sendable, Equatable, Identifiable {
    public var id: String
    public var labelID: String
    public var prepTaskID: String
    public var qty: Double
    public var unit: String
    public var expireAt: String
    public var status: LarderStatus

    public init(id: String, labelID: String, prepTaskID: String, qty: Double, unit: String, expireAt: String, status: LarderStatus) {
        self.id = id
        self.labelID = labelID
        self.prepTaskID = prepTaskID
        self.qty = qty
        self.unit = unit
        self.expireAt = expireAt
        self.status = status
    }
}

public enum LabelScanAction: Sendable, Equatable {
    case remaining(qty: Double)
    case used
    case wasted(qty: Double, reason: WasteReason)
}

public struct LabelScanResult: Sendable, Equatable {
    public var label: PrepLabel
    public var larderItem: PrepLarderItem?
    public var wasteRecord: CloseTaskRecord?

    public init(label: PrepLabel, larderItem: PrepLarderItem?, wasteRecord: CloseTaskRecord?) {
        self.label = label
        self.larderItem = larderItem
        self.wasteRecord = wasteRecord
    }
}

public struct CoeffSuggestion: Sendable, Equatable {
    public var taskId: String
    public var current: Double
    public var suggested: Double
    public var samplesUsed: Int

    public init(taskId: String, current: Double, suggested: Double, samplesUsed: Int) {
        self.taskId = taskId
        self.current = current
        self.suggested = suggested
        self.samplesUsed = samplesUsed
    }
}

public struct PrepEvent: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var tenantID: String
    public var type: String
    public var payload: [String: String]
    public var occurredAt: String
    public var actor: String?

    public init(id: String, tenantID: String, type: String, payload: [String: String] = [:], occurredAt: String, actor: String? = nil) {
        self.id = id
        self.tenantID = tenantID
        self.type = type
        self.payload = payload
        self.occurredAt = occurredAt
        self.actor = actor
    }
}

public struct ServicePeriod: Sendable, Equatable, Identifiable {
    public var id: String
    public var label: String
    public var t0: String
    public var servicePeriod: String

    public init(id: String, label: String, t0: String, servicePeriod: String) {
        self.id = id
        self.label = label
        self.t0 = t0
        self.servicePeriod = servicePeriod
    }
}

public struct ReservationSnapshot: Sendable, Equatable, Identifiable {
    public var id: String
    public var covers: Int
    public var course: String
    public var status: String

    public init(id: String, covers: Int, course: String, status: String = "confirmed") {
        self.id = id
        self.covers = covers
        self.course = course
        self.status = status
    }
}

public enum ConnectorProvider: String, Sendable, Equatable {
    case tablecheck
    case toreta
}

public struct SourceReservationEvent: Sendable, Equatable, Identifiable {
    public var id: String
    public var provider: ConnectorProvider
    public var externalID: String
    public var visitTime: String
    public var covers: Int
    public var course: String
    public var partyName: String
    public var status: String
    public var allergyNote: String?
    public var vipRank: String?

    public init(
        id: String,
        provider: ConnectorProvider,
        externalID: String,
        visitTime: String,
        covers: Int,
        course: String,
        partyName: String,
        status: String = "confirmed",
        allergyNote: String? = nil,
        vipRank: String? = nil
    ) {
        self.id = id
        self.provider = provider
        self.externalID = externalID
        self.visitTime = visitTime
        self.covers = covers
        self.course = course
        self.partyName = partyName
        self.status = status
        self.allergyNote = allergyNote
        self.vipRank = vipRank
    }
}

public struct NormalizedReservation: Sendable, Equatable, Identifiable {
    public var id: String
    public var source: String
    public var externalID: String
    public var visitTime: String
    public var covers: Int
    public var course: String
    public var partyName: String
    public var status: String
    public var prepNote: String?

    public init(
        id: String,
        source: String,
        externalID: String,
        visitTime: String,
        covers: Int,
        course: String,
        partyName: String,
        status: String,
        prepNote: String? = nil
    ) {
        self.id = id
        self.source = source
        self.externalID = externalID
        self.visitTime = visitTime
        self.covers = covers
        self.course = course
        self.partyName = partyName
        self.status = status
        self.prepNote = prepNote
    }
}

public enum DirectBookingStatus: String, Sendable, Equatable {
    case request
    case confirmed
    case cancelled
    case noshow
}

public struct DirectBooking: Sendable, Equatable, Identifiable {
    public var id: String
    public var visitTime: String
    public var covers: Int
    public var course: String
    public var guestName: String
    public var guestNote: String?
    public var status: DirectBookingStatus
    public var stripeCheckoutID: String?

    public init(
        id: String,
        visitTime: String,
        covers: Int,
        course: String,
        guestName: String,
        guestNote: String? = nil,
        status: DirectBookingStatus = .request,
        stripeCheckoutID: String? = nil
    ) {
        self.id = id
        self.visitTime = visitTime
        self.covers = covers
        self.course = course
        self.guestName = guestName
        self.guestNote = guestNote
        self.status = status
        self.stripeCheckoutID = stripeCheckoutID
    }
}

public struct DirectBookingCheckout: Sendable, Equatable, Identifiable {
    public var id: String
    public var bookingID: String
    public var checkoutID: String?
    public var status: DirectBookingStatus
    public var depositRequired: Bool

    public init(
        id: String,
        bookingID: String,
        checkoutID: String? = nil,
        status: DirectBookingStatus,
        depositRequired: Bool
    ) {
        self.id = id
        self.bookingID = bookingID
        self.checkoutID = checkoutID
        self.status = status
        self.depositRequired = depositRequired
    }
}

public struct ReservationDiffSummary: Sendable, Equatable {
    public var addedCovers: Int
    public var cancelledCovers: Int
    public var changedReservationIDs: [String]

    public init(addedCovers: Int, cancelledCovers: Int, changedReservationIDs: [String]) {
        self.addedCovers = addedCovers
        self.cancelledCovers = cancelledCovers
        self.changedReservationIDs = changedReservationIDs
    }
}

public enum ServiceEventSource: String, Sendable, Equatable {
    case prepflow
    case pos
    case kds
    case manual
}

public enum ServiceEventKind: String, Sendable, Equatable {
    case fire
    case hold
    case served
    case remainingSync = "remaining_sync"
}

public struct ServiceSyncEvent: Sendable, Equatable, Identifiable {
    public var id: String
    public var source: ServiceEventSource
    public var kind: ServiceEventKind
    public var covers: Int
    public var reservationID: String?
    public var occurredAt: String
    public var offlineSequence: Int?

    public init(
        id: String,
        source: ServiceEventSource,
        kind: ServiceEventKind,
        covers: Int,
        reservationID: String? = nil,
        occurredAt: String,
        offlineSequence: Int? = nil
    ) {
        self.id = id
        self.source = source
        self.kind = kind
        self.covers = covers
        self.reservationID = reservationID
        self.occurredAt = occurredAt
        self.offlineSequence = offlineSequence
    }
}

public struct ServiceSyncState: Sendable, Equatable {
    public var firedCovers: Int
    public var heldCovers: Int
    public var servedCovers: Int
    public var remainingCovers: Int
    public var pendingOfflineEvents: Int
    public var pacing: PacingProposal

    public init(
        firedCovers: Int,
        heldCovers: Int,
        servedCovers: Int,
        remainingCovers: Int,
        pendingOfflineEvents: Int,
        pacing: PacingProposal
    ) {
        self.firedCovers = firedCovers
        self.heldCovers = heldCovers
        self.servedCovers = servedCovers
        self.remainingCovers = remainingCovers
        self.pendingOfflineEvents = pendingOfflineEvents
        self.pacing = pacing
    }
}

public struct PacingProposal: Sendable, Equatable {
    public var expectedServed: Int
    public var actualServed: Int
    public var delta: Int
    public var recommendation: String

    public init(expectedServed: Int, actualServed: Int, delta: Int, recommendation: String) {
        self.expectedServed = expectedServed
        self.actualServed = actualServed
        self.delta = delta
        self.recommendation = recommendation
    }
}
