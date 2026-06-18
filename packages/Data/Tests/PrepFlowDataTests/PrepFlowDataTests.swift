@testable import PrepFlowData
import XCTest

final class PrepFlowDataTests: XCTestCase {
    private let tenantA = "tenant-a"
    private let tenantB = "tenant-b"

    func testP0TablesExposeTenantAuditAndSoftDeleteColumns() throws {
        let database = try PrepFlowDatabase()
        let requiredColumns: Set = ["id", "tenant_id", "created_at", "updated_at", "deleted_at"]

        for table in P0Table.allCases {
            let columns = try database.tableColumns(table)
            XCTAssertTrue(requiredColumns.isSubset(of: columns), "\(table.rawValue) missing required columns")
        }
    }

    func testLocalForwardSliceTablesExposeTenantAuditAndSoftDeleteColumns() throws {
        let database = try PrepFlowDatabase()
        let requiredColumns: Set = ["id", "tenant_id", "created_at", "updated_at", "deleted_at"]
        let forwardTables = [
            "service_period",
            "carryover",
            "temp_log",
            "label",
            "larder_item",
            "connector_account",
            "source_event",
            "direct_booking",
            "waitlist_entry",
            "special_prep",
            "allergen_label",
            "guest_message",
            "pass_seat_flag",
            "service_event",
            "dayrail_item",
            "subrecipe_aggregate",
            "subrecipe_reference",
        ]

        for table in forwardTables {
            let columns = try database.tableColumns(named: table)
            XCTAssertTrue(requiredColumns.isSubset(of: columns), "\(table) missing required columns")
        }
    }

    func testCrudAndTenantScopedReadsForP0Graph() throws {
        let database = try PrepFlowDatabase()
        try seedGraph(tenantID: tenantA, suffix: "a", database: database)
        try seedGraph(tenantID: tenantB, suffix: "b", database: database)

        for table in P0Table.allCases {
            XCTAssertEqual(try database.rows(table, tenantID: tenantA).count, 1, table.rawValue)
            XCTAssertEqual(try database.rows(table, tenantID: tenantB).count, 1, table.rawValue)
        }

        try database.update(.restaurant, id: "restaurant-a", tenantID: tenantA, values: ["name": "Hayashi Ginza"])
        XCTAssertEqual(try database.rows(.restaurant, tenantID: tenantA).first?.values["name"], "Hayashi Ginza")
        XCTAssertEqual(try database.rows(.restaurant, tenantID: tenantB).first?.values["name"], "Hayashi b")

        try database.softDelete(.reservation, id: "reservation-a", tenantID: tenantA)
        XCTAssertEqual(try database.rows(.reservation, tenantID: tenantA).count, 0)
        XCTAssertEqual(try database.rows(.reservation, tenantID: tenantA, includeDeleted: true).count, 1)
        XCTAssertEqual(try database.rows(.reservation, tenantID: tenantB).count, 1)
    }

    func testSupabaseMigrationCreatesOnlyP0TablesAndTenantRLSPolicies() throws {
        let sql = try migrationSQL()
        let p0TableNames = Set(P0Table.allCases.map(\.rawValue))

        for tableName in p0TableNames {
            XCTAssertTrue(sql.contains("create table if not exists public.\(tableName)"), tableName)
            XCTAssertTrue(sql.contains("'\(tableName)'"), tableName)
        }

        XCTAssertTrue(sql.contains("alter table public.%I enable row level security"))
        XCTAssertTrue(sql.contains("tenant_id = public.current_tenant_id()"))
        XCTAssertTrue(sql.contains("auth.jwt() ->> 'tenant_id'"))

        for deferredTable in ["label", "printer", "storage_unit", "temp_log", "store_membership"] {
            XCTAssertFalse(sql.contains("create table if not exists public.\(deferredTable)"))
        }
    }

    private func seedGraph(tenantID: String, suffix: String, database: PrepFlowDatabase) throws {
        try database.create(.restaurant, values: base("restaurant", suffix, tenantID, ["name": "Hayashi \(suffix)", "seats": "12"]))
        try database.create(.ownerAccount, values: base("owner", suffix, tenantID, ownerValues(suffix)))
        try database.create(.section, values: base("section", suffix, tenantID, sectionValues(suffix)))
        try database.create(.courseTemplate, values: base("course", suffix, tenantID, courseValues(suffix)))
        try database.create(.dish, values: base("dish", suffix, tenantID, dishValues(suffix)))
        try database.create(.component, values: base("component", suffix, tenantID, componentValues(suffix)))
        try database.create(.prepTask, values: base("prep", suffix, tenantID, prepValues(suffix)))
        try database.create(.serviceDay, values: base("service", suffix, tenantID, serviceValues(suffix)))
        try database.create(.serviceCover, values: base("cover", suffix, tenantID, coverValues(suffix)))
        try database.create(.taskInstance, values: base("instance", suffix, tenantID, instanceValues(suffix)))
        try database.create(.wasteLog, values: base("waste", suffix, tenantID, wasteValues(suffix)))
        try database.create(.businessCalendar, values: base("calendar", suffix, tenantID, calendarValues(suffix)))
        try database.create(.device, values: base("device", suffix, tenantID, deviceValues(suffix)))
        try database.create(.settings, values: base("setting", suffix, tenantID, settingsValues(suffix)))
        try database.create(.entitlement, values: base("entitlement", suffix, tenantID, entitlementValues()))
        try database.create(.eventLog, values: base("event", suffix, tenantID, eventValues()))
        try database.create(.reservation, values: base("reservation", suffix, tenantID, reservationValues(suffix)))
    }

    private func base(_ prefix: String, _ suffix: String, _ tenantID: String, _ values: [String: String?]) -> [String: String?] {
        values.merging([
            "id": "\(prefix)-\(suffix)",
            "tenant_id": tenantID,
        ]) { current, _ in current }
    }

    private func ownerValues(_ suffix: String) -> [String: String?] {
        ["email": "owner-\(suffix)@prepflow.test", "auth_provider": "magiclink", "display_name": "Owner", "role": "owner"]
    }

    private func sectionValues(_ suffix: String) -> [String: String?] {
        ["restaurant_id": "restaurant-\(suffix)", "name": "Shari", "sort": "1"]
    }

    private func courseValues(_ suffix: String) -> [String: String?] {
        ["restaurant_id": "restaurant-\(suffix)", "name": "Omakase", "version": "1", "archived": "0"]
    }

    private func dishValues(_ suffix: String) -> [String: String?] {
        ["course_template_id": "course-\(suffix)", "name": "Tai", "sort": "1"]
    }

    private func componentValues(_ suffix: String) -> [String: String?] {
        ["dish_id": "dish-\(suffix)", "name": "Nikiri", "sort": "1"]
    }

    private func prepValues(_ suffix: String) -> [String: String?] {
        [
            "component_id": "component-\(suffix)", "name": "Nikiri", "scale_mode": "per_cover",
            "coeff_per_cover": "14", "yield": "1", "unit": "ml", "duration_min": "20",
            "lead_min_before_open": "180", "section_id": "section-\(suffix)", "sort": "1",
        ]
    }

    private func serviceValues(_ suffix: String) -> [String: String?] {
        ["restaurant_id": "restaurant-\(suffix)", "date": "2026-06-17", "service_period": "dinner", "open_time": "18:00"]
    }

    private func coverValues(_ suffix: String) -> [String: String?] {
        ["service_day_id": "service-\(suffix)", "course_template_id": "course-\(suffix)", "covers": "14"]
    }

    private func instanceValues(_ suffix: String) -> [String: String?] {
        [
            "service_day_id": "service-\(suffix)", "prep_task_id": "prep-\(suffix)",
            "status": "not_started", "prep_day": "2026-06-17", "planned_qty": "200",
            "unit": "ml", "start_at": "15:00", "finish_at": "15:20", "sort": "1",
        ]
    }

    private func wasteValues(_ suffix: String) -> [String: String?] {
        [
            "service_day_id": "service-\(suffix)", "prep_task_id": "prep-\(suffix)",
            "covers": "14", "planned_qty": "200", "made_qty": "190",
            "leftover_qty": "10", "waste_reason": "overmade", "carryover_to_next": "0", "unit": "ml",
        ]
    }

    private func calendarValues(_ suffix: String) -> [String: String?] {
        ["restaurant_id": "restaurant-\(suffix)", "closed_dates": "[]", "closed_weekdays": "[]", "holidays": "[]"]
    }

    private func deviceValues(_ suffix: String) -> [String: String?] {
        ["name": "iPad \(suffix)", "restaurant_id": "restaurant-\(suffix)", "default_view_override": "now"]
    }

    private func settingsValues(_ suffix: String) -> [String: String?] {
        ["restaurant_id": "restaurant-\(suffix)", "key": "prep.thresholds", "value": "{}"]
    }

    private func entitlementValues() -> [String: String?] {
        ["plan": "lite", "features": "{\"board\":true}"]
    }

    private func eventValues() -> [String: String?] {
        ["type": "task.completed", "payload": "{}", "occurred_at": "2026-06-17T09:00:00Z", "actor": "owner"]
    }

    private func reservationValues(_ suffix: String) -> [String: String?] {
        [
            "service_day_id": "service-\(suffix)", "source": "manual", "visit_time": "18:00",
            "covers": "14", "course_template_id": "course-\(suffix)", "structured": "1",
        ]
    }

    private func migrationSQL() throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("../../")
            .standardized
        let migration = root.appendingPathComponent("supabase/migrations/202606170001_ws3_p0_schema_rls.sql")
        return try String(contentsOf: migration, encoding: .utf8)
    }
}
