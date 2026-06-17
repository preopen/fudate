import Foundation

public actor SyncHub {
    private var appliedMutationIDs: Set<String> = []
    private var tasks: [String: TaskSnapshot] = [:]
    private var quantities: [String: QuantitySnapshot] = [:]
    private var quantityHistory: [QuantityHistoryEntry] = []

    public init() {}

    public func seed(task: TaskSnapshot) {
        tasks[key(task.tenantID, task.id)] = task
    }

    public func apply(_ mutations: [SyncMutation]) {
        for mutation in mutations where !appliedMutationIDs.contains(mutation.id) {
            appliedMutationIDs.insert(mutation.id)

            switch mutation.kind {
            case .checkTaskDone:
                applyCheckTaskDone(mutation)
            case .setMadeQuantity:
                applyMadeQuantity(mutation)
            }
        }
    }

    public func snapshot(forTenant tenantID: String) -> ServerSnapshot {
        ServerSnapshot(
            tasks: tasks.values.filter { $0.tenantID == tenantID }.sorted { $0.id < $1.id },
            quantities: quantities.values.filter { $0.tenantID == tenantID }.sorted { $0.taskID < $1.taskID },
            quantityHistory: quantityHistory.filter { $0.tenantID == tenantID }.sorted {
                if $0.updatedAt == $1.updatedAt { return $0.mutationID < $1.mutationID }
                return $0.updatedAt < $1.updatedAt
            }
        )
    }

    private func applyCheckTaskDone(_ mutation: SyncMutation) {
        let snapshotKey = key(mutation.tenantID, mutation.taskID)
        let current = tasks[snapshotKey]
        let alreadyDone = current?.status == .done
        let shouldAdvance = (current?.updatedAt ?? .min) <= mutation.happenedAt

        guard !alreadyDone || shouldAdvance else {
            return
        }

        tasks[snapshotKey] = TaskSnapshot(
            id: mutation.taskID,
            tenantID: mutation.tenantID,
            status: .done,
            checkedAt: current?.checkedAt ?? mutation.happenedAt,
            updatedAt: max(current?.updatedAt ?? .min, mutation.happenedAt),
            updatedBy: mutation.deviceID
        )
    }

    private func applyMadeQuantity(_ mutation: SyncMutation) {
        guard let madeQty = mutation.madeQty else {
            return
        }

        quantityHistory.append(
            QuantityHistoryEntry(
                mutationID: mutation.id,
                taskID: mutation.taskID,
                tenantID: mutation.tenantID,
                madeQty: madeQty,
                updatedAt: mutation.happenedAt,
                updatedBy: mutation.deviceID
            )
        )

        let snapshotKey = key(mutation.tenantID, mutation.taskID)
        let current = quantities[snapshotKey]
        guard (current?.updatedAt ?? .min) <= mutation.happenedAt else {
            return
        }

        quantities[snapshotKey] = QuantitySnapshot(
            taskID: mutation.taskID,
            tenantID: mutation.tenantID,
            madeQty: madeQty,
            updatedAt: mutation.happenedAt,
            updatedBy: mutation.deviceID
        )
    }

    private func key(_ tenantID: String, _ taskID: String) -> String {
        "\(tenantID):\(taskID)"
    }
}
