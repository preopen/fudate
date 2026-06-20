import Foundation
@preconcurrency import GRDB

public final class LocalReplica: @unchecked Sendable {
    private let dbQueue: DatabaseQueue
    private let tenantID: String
    private let deviceID: String

    public init(path: String, tenantID: String, deviceID: String) throws {
        var configuration = Configuration()
        configuration.prepareDatabase { db in
            try db.execute(sql: "pragma journal_mode = WAL")
            try db.execute(sql: "pragma synchronous = NORMAL")
        }
        dbQueue = try DatabaseQueue(path: path, configuration: configuration)
        self.tenantID = tenantID
        self.deviceID = deviceID
        try migrate()
    }

    public func seed(taskID: String, at timestamp: Int64) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: """
                insert or ignore into task_instance
                (id, tenant_id, status, checked_at, updated_at, updated_by)
                values (?, ?, ?, null, ?, ?)
                """,
                arguments: [taskID, tenantID, SpikeTaskStatus.notStarted.rawValue, timestamp, deviceID]
            )
        }
    }

    public func markDone(taskID: String, at timestamp: Int64) throws {
        let mutationID = "\(deviceID)-done-\(taskID)-\(timestamp)"
        try dbQueue.write { db in
            try db.execute(
                sql: """
                insert into task_instance
                (id, tenant_id, status, checked_at, updated_at, updated_by)
                values (?, ?, ?, ?, ?, ?)
                on conflict(id) do update set
                  status = excluded.status,
                  checked_at = coalesce(task_instance.checked_at, excluded.checked_at),
                  updated_at = max(task_instance.updated_at, excluded.updated_at),
                  updated_by = excluded.updated_by
                """,
                arguments: [taskID, tenantID, SpikeTaskStatus.done.rawValue, timestamp, timestamp, deviceID]
            )
            try insertOutbox(
                db,
                SyncMutation(
                    id: mutationID,
                    tenantID: tenantID,
                    deviceID: deviceID,
                    taskID: taskID,
                    kind: .checkTaskDone,
                    status: .done,
                    happenedAt: timestamp
                )
            )
        }
    }

    public func setMadeQuantity(taskID: String, madeQty: Double, at timestamp: Int64) throws {
        let mutationID = "\(deviceID)-qty-\(taskID)-\(timestamp)"
        try dbQueue.write { db in
            try db.execute(
                sql: """
                insert into quantity_state
                (task_id, tenant_id, made_qty, updated_at, updated_by)
                values (?, ?, ?, ?, ?)
                on conflict(task_id) do update set
                  made_qty = case
                    when excluded.updated_at >= quantity_state.updated_at then excluded.made_qty
                    else quantity_state.made_qty
                  end,
                  updated_at = max(quantity_state.updated_at, excluded.updated_at),
                  updated_by = case
                    when excluded.updated_at >= quantity_state.updated_at then excluded.updated_by
                    else quantity_state.updated_by
                  end
                """,
                arguments: [taskID, tenantID, madeQty, timestamp, deviceID]
            )
            try db.execute(
                sql: """
                insert or ignore into quantity_history
                (mutation_id, task_id, tenant_id, made_qty, updated_at, updated_by)
                values (?, ?, ?, ?, ?, ?)
                """,
                arguments: [mutationID, taskID, tenantID, madeQty, timestamp, deviceID]
            )
            try insertOutbox(
                db,
                SyncMutation(
                    id: mutationID,
                    tenantID: tenantID,
                    deviceID: deviceID,
                    taskID: taskID,
                    kind: .setMadeQuantity,
                    madeQty: madeQty,
                    happenedAt: timestamp
                )
            )
        }
    }

    public func taskStatus(taskID: String) throws -> SpikeTaskStatus {
        try dbQueue.read { db in
            let raw = try String.fetchOne(db, sql: "select status from task_instance where id = ?", arguments: [taskID])
            return raw.flatMap(SpikeTaskStatus.init(rawValue:)) ?? .notStarted
        }
    }

    public func quantity(taskID: String) throws -> QuantitySnapshot? {
        try dbQueue.read { db in
            guard let row = try Row.fetchOne(db, sql: "select * from quantity_state where task_id = ?", arguments: [taskID]) else {
                return nil
            }
            return QuantitySnapshot(
                taskID: row["task_id"],
                tenantID: row["tenant_id"],
                madeQty: row["made_qty"],
                updatedAt: row["updated_at"],
                updatedBy: row["updated_by"]
            )
        }
    }

    public func quantityHistoryCount(taskID: String) throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: "select count(*) from quantity_history where task_id = ?", arguments: [taskID]) ?? 0
        }
    }

    public func pendingOutboxCount() throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: "select count(*) from outbox where sent_at is null") ?? 0
        }
    }

    public func sync(with hub: SyncHub, at timestamp: Int64) async throws {
        let pending = try pendingMutations()
        await hub.apply(pending)
        let snapshot = await hub.snapshot(forTenant: tenantID)
        try apply(snapshot: snapshot, sentMutationIDs: pending.map(\.id), at: timestamp)
    }

    private func migrate() throws {
        try dbQueue.write { db in
            try db.execute(sql: """
            create table if not exists task_instance (
              id text primary key,
              tenant_id text not null,
              status text not null,
              checked_at integer,
              updated_at integer not null,
              updated_by text not null
            );
            """)
            try db.execute(sql: """
            create table if not exists quantity_state (
              task_id text primary key,
              tenant_id text not null,
              made_qty real not null,
              updated_at integer not null,
              updated_by text not null
            );
            """)
            try db.execute(sql: """
            create table if not exists quantity_history (
              mutation_id text primary key,
              task_id text not null,
              tenant_id text not null,
              made_qty real not null,
              updated_at integer not null,
              updated_by text not null
            );
            """)
            try db.execute(sql: """
            create table if not exists outbox (
              mutation_id text primary key,
              tenant_id text not null,
              device_id text not null,
              task_id text not null,
              kind text not null,
              status text,
              made_qty real,
              happened_at integer not null,
              sent_at integer
            );
            """)
            try db.execute(sql: "create index if not exists outbox_unsent on outbox(sent_at);")
            try db.execute(sql: "create index if not exists task_tenant on task_instance(tenant_id);")
        }
    }

    private func pendingMutations() throws -> [SyncMutation] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                select mutation_id, tenant_id, device_id, task_id, kind, status, made_qty, happened_at
                from outbox
                where sent_at is null
                order by happened_at, mutation_id
                """
            )
            return rows.map { row in
                SyncMutation(
                    id: row["mutation_id"],
                    tenantID: row["tenant_id"],
                    deviceID: row["device_id"],
                    taskID: row["task_id"],
                    kind: SyncMutationKind(rawValue: row["kind"]) ?? .checkTaskDone,
                    status: (row["status"] as String?).flatMap(SpikeTaskStatus.init(rawValue:)),
                    madeQty: row["made_qty"] as Double?,
                    happenedAt: row["happened_at"]
                )
            }
        }
    }

    private func apply(snapshot: ServerSnapshot, sentMutationIDs: [String], at timestamp: Int64) throws {
        try dbQueue.write { db in
            try applyTasks(snapshot.tasks, db: db)
            try applyQuantities(snapshot.quantities, db: db)
            try applyQuantityHistory(snapshot.quantityHistory, db: db)
            try markSent(mutationIDs: sentMutationIDs, at: timestamp, db: db)
        }
    }

    private func applyTasks(_ tasks: [TaskSnapshot], db: Database) throws {
        for task in tasks {
            try db.execute(
                sql: """
                insert into task_instance
                (id, tenant_id, status, checked_at, updated_at, updated_by)
                values (?, ?, ?, ?, ?, ?)
                on conflict(id) do update set
                  status = case
                    when excluded.updated_at >= task_instance.updated_at then excluded.status
                    else task_instance.status
                  end,
                  checked_at = coalesce(task_instance.checked_at, excluded.checked_at),
                  updated_at = max(task_instance.updated_at, excluded.updated_at),
                  updated_by = case
                    when excluded.updated_at >= task_instance.updated_at then excluded.updated_by
                    else task_instance.updated_by
                  end
                """,
                arguments: [task.id, task.tenantID, task.status.rawValue, task.checkedAt, task.updatedAt, task.updatedBy]
            )
        }
    }

    private func applyQuantities(_ quantities: [QuantitySnapshot], db: Database) throws {
        for quantity in quantities {
            try db.execute(
                sql: """
                insert into quantity_state
                (task_id, tenant_id, made_qty, updated_at, updated_by)
                values (?, ?, ?, ?, ?)
                on conflict(task_id) do update set
                  made_qty = case
                    when excluded.updated_at >= quantity_state.updated_at then excluded.made_qty
                    else quantity_state.made_qty
                  end,
                  updated_at = max(quantity_state.updated_at, excluded.updated_at),
                  updated_by = case
                    when excluded.updated_at >= quantity_state.updated_at then excluded.updated_by
                    else quantity_state.updated_by
                  end
                """,
                arguments: [quantity.taskID, quantity.tenantID, quantity.madeQty, quantity.updatedAt, quantity.updatedBy]
            )
        }
    }

    private func applyQuantityHistory(_ historyEntries: [QuantityHistoryEntry], db: Database) throws {
        for history in historyEntries {
            try db.execute(
                sql: """
                insert or ignore into quantity_history
                (mutation_id, task_id, tenant_id, made_qty, updated_at, updated_by)
                values (?, ?, ?, ?, ?, ?)
                """,
                arguments: [history.mutationID, history.taskID, history.tenantID, history.madeQty, history.updatedAt, history.updatedBy]
            )
        }
    }

    private func markSent(mutationIDs: [String], at timestamp: Int64, db: Database) throws {
        for mutationID in mutationIDs {
            try db.execute(sql: "update outbox set sent_at = ? where mutation_id = ?", arguments: [timestamp, mutationID])
        }
    }

    private func insertOutbox(_ db: Database, _ mutation: SyncMutation) throws {
        try db.execute(
            sql: """
            insert or ignore into outbox
            (mutation_id, tenant_id, device_id, task_id, kind, status, made_qty, happened_at, sent_at)
            values (?, ?, ?, ?, ?, ?, ?, ?, null)
            """,
            arguments: [
                mutation.id,
                mutation.tenantID,
                mutation.deviceID,
                mutation.taskID,
                mutation.kind.rawValue,
                mutation.status?.rawValue,
                mutation.madeQty,
                mutation.happenedAt,
            ]
        )
    }
}
