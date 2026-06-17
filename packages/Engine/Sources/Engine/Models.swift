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
