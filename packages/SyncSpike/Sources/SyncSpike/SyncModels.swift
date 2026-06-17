import Foundation

public enum SpikeTaskStatus: String, Codable, Equatable, Sendable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case done
}

public struct TaskSnapshot: Equatable, Sendable {
    public var id: String
    public var tenantID: String
    public var status: SpikeTaskStatus
    public var checkedAt: Int64?
    public var updatedAt: Int64
    public var updatedBy: String

    public init(id: String, tenantID: String, status: SpikeTaskStatus, checkedAt: Int64?, updatedAt: Int64, updatedBy: String) {
        self.id = id
        self.tenantID = tenantID
        self.status = status
        self.checkedAt = checkedAt
        self.updatedAt = updatedAt
        self.updatedBy = updatedBy
    }
}

public struct QuantitySnapshot: Equatable, Sendable {
    public var taskID: String
    public var tenantID: String
    public var madeQty: Double
    public var updatedAt: Int64
    public var updatedBy: String

    public init(taskID: String, tenantID: String, madeQty: Double, updatedAt: Int64, updatedBy: String) {
        self.taskID = taskID
        self.tenantID = tenantID
        self.madeQty = madeQty
        self.updatedAt = updatedAt
        self.updatedBy = updatedBy
    }
}

public struct QuantityHistoryEntry: Equatable, Sendable {
    public var mutationID: String
    public var taskID: String
    public var tenantID: String
    public var madeQty: Double
    public var updatedAt: Int64
    public var updatedBy: String

    public init(mutationID: String, taskID: String, tenantID: String, madeQty: Double, updatedAt: Int64, updatedBy: String) {
        self.mutationID = mutationID
        self.taskID = taskID
        self.tenantID = tenantID
        self.madeQty = madeQty
        self.updatedAt = updatedAt
        self.updatedBy = updatedBy
    }
}

public enum SyncMutationKind: String, Sendable {
    case checkTaskDone = "check_task_done"
    case setMadeQuantity = "set_made_quantity"
}

public struct SyncMutation: Equatable, Sendable {
    public var id: String
    public var tenantID: String
    public var deviceID: String
    public var taskID: String
    public var kind: SyncMutationKind
    public var status: SpikeTaskStatus?
    public var madeQty: Double?
    public var happenedAt: Int64

    public init(
        id: String,
        tenantID: String,
        deviceID: String,
        taskID: String,
        kind: SyncMutationKind,
        status: SpikeTaskStatus? = nil,
        madeQty: Double? = nil,
        happenedAt: Int64
    ) {
        self.id = id
        self.tenantID = tenantID
        self.deviceID = deviceID
        self.taskID = taskID
        self.kind = kind
        self.status = status
        self.madeQty = madeQty
        self.happenedAt = happenedAt
    }
}

public struct ServerSnapshot: Equatable, Sendable {
    public var tasks: [TaskSnapshot]
    public var quantities: [QuantitySnapshot]
    public var quantityHistory: [QuantityHistoryEntry]

    public init(tasks: [TaskSnapshot], quantities: [QuantitySnapshot], quantityHistory: [QuantityHistoryEntry]) {
        self.tasks = tasks
        self.quantities = quantities
        self.quantityHistory = quantityHistory
    }
}
