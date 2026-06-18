import Foundation
@preconcurrency import GRDB

public enum P0Table: String, CaseIterable, Sendable {
    case restaurant
    case ownerAccount = "owner_account"
    case section
    case courseTemplate = "course_template"
    case dish
    case component
    case prepTask = "prep_task"
    case serviceDay = "service_day"
    case serviceCover = "service_cover"
    case taskInstance = "task_instance"
    case wasteLog = "waste_log"
    case businessCalendar = "business_calendar"
    case device
    case settings
    case entitlement
    case eventLog = "event_log"
    case reservation
}

public struct DataRow: Equatable, Sendable {
    public var id: String
    public var tenantID: String
    public var deletedAt: String?
    public var values: [String: String]
}

public final class PrepFlowDatabase: @unchecked Sendable {
    private let dbQueue: DatabaseQueue

    public init(path: String = ":memory:") throws {
        dbQueue = try DatabaseQueue(path: path)
        try migrate()
    }

    public func create(_ table: P0Table, values: [String: String?]) throws {
        try create(named: table.rawValue, values: values)
    }

    public func create(named tableName: String, values: [String: String?]) throws {
        try dbQueue.write { db in
            let keys = values.keys.sorted()
            let placeholders = Array(repeating: "?", count: keys.count).joined(separator: ", ")
            let columns = keys.joined(separator: ", ")
            let arguments = StatementArguments(keys.map { values[$0] ?? nil })
            try db.execute(
                sql: "insert into \(tableName) (\(columns)) values (\(placeholders))",
                arguments: arguments
            )
        }
    }

    public func update(_ table: P0Table, id: String, tenantID: String, values: [String: String?]) throws {
        try update(named: table.rawValue, id: id, tenantID: tenantID, values: values)
    }

    public func update(named tableName: String, id: String, tenantID: String, values: [String: String?]) throws {
        try dbQueue.write { db in
            let keys = values.keys.sorted()
            let assignments = keys.map { "\($0) = ?" }.joined(separator: ", ")
            try db.execute(
                sql: "update \(tableName) set \(assignments), updated_at = ? where id = ? and tenant_id = ?",
                arguments: StatementArguments(keys.map { values[$0] ?? nil } + [Self.now, id, tenantID])
            )
        }
    }

    public func softDelete(_ table: P0Table, id: String, tenantID: String) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "update \(table.rawValue) set deleted_at = ?, updated_at = ? where id = ? and tenant_id = ?",
                arguments: [Self.now, Self.now, id, tenantID]
            )
        }
    }

    public func rows(_ table: P0Table, tenantID: String, includeDeleted: Bool = false) throws -> [DataRow] {
        try rows(named: table.rawValue, tenantID: tenantID, includeDeleted: includeDeleted)
    }

    public func rows(named tableName: String, tenantID: String, includeDeleted: Bool = false) throws -> [DataRow] {
        try dbQueue.read { db in
            let deletedClause = includeDeleted ? "" : " and deleted_at is null"
            let rows = try Row.fetchAll(
                db,
                sql: "select * from \(tableName) where tenant_id = ?\(deletedClause) order by id",
                arguments: [tenantID]
            )
            return rows.map(Self.dataRow)
        }
    }

    public func tableColumns(_ table: P0Table) throws -> Set<String> {
        try tableColumns(named: table.rawValue)
    }

    public func tableColumns(named tableName: String) throws -> Set<String> {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "pragma table_info(\(tableName))")
            return Set(rows.map { row in row["name"] as String })
        }
    }

    private func migrate() throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("ws3-p0-schema") { db in
            try Self.createSchema(db)
        }
        migrator.registerMigration("forward-slice-schema-refresh") { db in
            try Self.createSchema(db)
        }
        try migrator.migrate(dbQueue)
    }

    private static func createSchema(_ db: Database) throws {
        try db.execute(sql: "pragma foreign_keys = on")
        for statement in schemaStatements {
            try db.execute(sql: statement)
        }
    }

    private static func dataRow(_ row: Row) -> DataRow {
        var values: [String: String] = [:]
        for (column, databaseValue) in row {
            values[column] = stringValue(databaseValue)
        }
        return DataRow(
            id: row["id"],
            tenantID: row["tenant_id"],
            deletedAt: row["deleted_at"] as String?,
            values: values
        )
    }

    private static func stringValue(_ databaseValue: DatabaseValue) -> String {
        if databaseValue.isNull {
            return "NULL"
        }
        if let value = String.fromDatabaseValue(databaseValue) {
            return value
        }
        if let value = Int64.fromDatabaseValue(databaseValue) {
            return String(value)
        }
        if let value = Double.fromDatabaseValue(databaseValue) {
            return String(value)
        }
        return String(describing: databaseValue)
    }

    private static let now = "2026-06-17T00:00:00Z"
}
