import Engine
@testable import PrepFlow
import PrepFlowData
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class PrepFlowBoardSnapshotTests: XCTestCase {
    private let snapshotSize = CGSize(width: 1194, height: 834)

    func testBoardNowMatchesSourceWire() {
        assertBoardSnapshot(mode: .now, named: "p0-wireframe-board-liquidglass")
    }

    func testBoardDishesMatchesSourceWire() {
        assertBoardSnapshot(mode: .dishes, named: "p1-wireframe-view-dishes-liquidglass")
    }

    func testBoardStaffMatchesSourceWire() {
        assertBoardSnapshot(mode: .staff, named: "p1-wireframe-view-staff-liquidglass")
    }

    func testCatalogEditorMatchesSourceWire() {
        let view = CatalogEditorView(store: BoardStore(database: nil))
            .frame(width: snapshotSize.width, height: snapshotSize.height)

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: snapshotSize)
        controller.view.backgroundColor = .clear

        assertSnapshot(
            of: controller,
            as: .image(precision: 0.98, perceptualPrecision: 0.98, size: snapshotSize),
            named: "p1-wireframe-template-editor-liquidglass"
        )
    }

    func testServiceSetupMatchesSourceWire() {
        let view = ServiceSetupView(store: BoardStore(database: nil))
            .frame(width: snapshotSize.width, height: snapshotSize.height)

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: snapshotSize)
        controller.view.backgroundColor = .clear

        assertSnapshot(
            of: controller,
            as: .image(precision: 0.98, perceptualPrecision: 0.98, size: snapshotSize),
            named: "p0-wireframe-service-setup-liquidglass"
        )
    }

    func testSimulationMatchesSourceWire() {
        let view = SimulationView(store: BoardStore(database: nil))
            .frame(width: snapshotSize.width, height: snapshotSize.height)

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: snapshotSize)
        controller.view.backgroundColor = .clear

        assertSnapshot(
            of: controller,
            as: .image(precision: 0.98, perceptualPrecision: 0.98, size: snapshotSize),
            named: "p0-wireframe-simulation-liquidglass"
        )
    }

    func testActivationMatchesSourceWire() {
        let view = ActivationSummaryView(store: BoardStore(database: nil))
            .frame(width: snapshotSize.width, height: snapshotSize.height)

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: snapshotSize)
        controller.view.backgroundColor = .clear

        assertSnapshot(
            of: controller,
            as: .image(precision: 0.98, perceptualPrecision: 0.98, size: snapshotSize),
            named: "p0-wireframe-activation-liquidglass"
        )
    }

    func testAuthGateMatchesSourceWire() throws {
        let store = try AuthStore(database: PrepFlowDatabase())
        let view = AuthGateView(store: store)
            .frame(width: snapshotSize.width, height: snapshotSize.height)

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: snapshotSize)
        controller.view.backgroundColor = .clear

        assertSnapshot(
            of: controller,
            as: .image(precision: 0.98, perceptualPrecision: 0.98, size: snapshotSize),
            named: "p0-wireframe-onboarding-liquidglass"
        )
    }

    func testSettingsHomeMatchesSourceWire() {
        let session = AuthSession(
            ownerID: "owner-hayashi",
            tenantID: "tenant-local",
            email: "owner@prepflow.test",
            provider: .apple,
            displayName: "林 直人",
            role: "owner"
        )
        let view = SettingsHomeView(session: session, backToBoard: {}, signOut: {})
            .frame(width: snapshotSize.width, height: snapshotSize.height)

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: snapshotSize)
        controller.view.backgroundColor = .clear

        assertSnapshot(
            of: controller,
            as: .image(precision: 0.98, perceptualPrecision: 0.98, size: snapshotSize),
            named: "p1-wireframe-settings-home-liquidglass"
        )
    }

    func testMagicLinkAuthResolvesTenantAndScopesRows() throws {
        let database = try PrepFlowDatabase()
        let authStore = AuthStore(database: database)

        authStore.sendMagicLink()
        authStore.completeMagicLink()

        let session = try XCTUnwrap(authStore.session)
        XCTAssertEqual(session.tenantID, "tenant-local")
        XCTAssertEqual(session.provider, .magicLink)

        _ = BoardStore(database: database, tenantID: session.tenantID)
        try database.create(.restaurant, values: [
            "id": "restaurant-other",
            "tenant_id": "tenant-other",
            "name": "別店舗",
            "seats": "8",
        ])

        XCTAssertEqual(try database.rows(.ownerAccount, tenantID: session.tenantID).count, 1)
        XCTAssertEqual(try database.rows(.restaurant, tenantID: session.tenantID).map(\.tenantID), [session.tenantID])
        XCTAssertEqual(try database.rows(.restaurant, tenantID: "tenant-other").map(\.tenantID), ["tenant-other"])
    }

    func testCheckoffRollsUpNikiriAndKeepsETAProjection() throws {
        let store = try BoardStore(completed: ["sake", "shari", "neta"], database: PrepFlowDatabase())

        XCTAssertEqual(store.nikiriRollupStatus, .inProgress)
        store.toggle("tare")
        store.toggle("rest")

        XCTAssertEqual(store.nikiriRollupStatus, .done)
        XCTAssertTrue(store.completed.contains("nikiri"))
        XCTAssertEqual(store.eta.landing, "18:12")
        XCTAssertEqual(store.eta.shortfallMin, 12)
    }

    func testCatalogCrudAndScaleInputsReflectInBoardQuantity() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        XCTAssertEqual(Int(store.nikiriQuantity.total), 200)
        XCTAssertEqual(try database.rows(.dish, tenantID: "tenant-local").count, 1)
        XCTAssertEqual(try database.rows(.component, tenantID: "tenant-local").count, 3)
        XCTAssertEqual(try database.rows(.prepTask, tenantID: "tenant-local").count, 3)

        store.addDish()
        store.addComponent()
        store.addTask()

        XCTAssertEqual(try database.rows(.dish, tenantID: "tenant-local").count, 2)
        XCTAssertEqual(try database.rows(.component, tenantID: "tenant-local").count, 4)
        XCTAssertEqual(try database.rows(.prepTask, tenantID: "tenant-local").count, 4)

        store.selectTask("task-nikiri")
        store.updateSelectedTask(coeffPerCover: 20, yieldPercent: 100)

        XCTAssertEqual(Int(store.nikiriQuantity.total), 280)
        let taskRows = try database.rows(.prepTask, tenantID: "tenant-local")
        let nikiriRow = try XCTUnwrap(taskRows.first { $0.id == "task-nikiri" })
        XCTAssertEqual(nikiriRow.values["coeff_per_cover"], "20")
    }

    func testServiceDayInputsReflectInQuantityAndSchedule() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        XCTAssertEqual(Int(store.nikiriQuantity.total), 200)
        XCTAssertEqual(store.nikiriSchedule.start, "15:00")

        store.updateOmakaseCovers(10)
        XCTAssertEqual(Int(store.nikiriQuantity.total), 140)

        store.updateOpenTime("19:00")
        XCTAssertEqual(store.nikiriSchedule.start, "16:00")

        let coverRows = try database.rows(.serviceCover, tenantID: "tenant-local")
        let coverRow = try XCTUnwrap(coverRows.first { $0.id == "cover-omakase" })
        XCTAssertEqual(coverRow.values["covers"], "10")
    }

    func testSimulationAppliesCoefficientsAndRecordsWasteLog() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        XCTAssertEqual(Int(store.nikiriQuantity.total), 200)
        store.applySimulationCoefficients()
        XCTAssertEqual(Int(store.nikiriQuantity.total), 170)

        store.recordNikiriWaste()
        let wasteRows = try database.rows(.wasteLog, tenantID: "tenant-local")
        let waste = try XCTUnwrap(wasteRows.first)
        XCTAssertEqual(waste.values["prep_task_id"], "task-nikiri")
        XCTAssertEqual(waste.values["made_qty"], "240")
        XCTAssertEqual(waste.values["leftover_qty"], "40")
    }

    private func assertBoardSnapshot(mode: BoardMode, named name: String, filePath: StaticString = #filePath, testName: String = #function, line: UInt = #line) {
        let view = PrepFlowBoardView(initialMode: mode)
            .frame(width: snapshotSize.width, height: snapshotSize.height)

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: snapshotSize)
        controller.view.backgroundColor = .clear

        assertSnapshot(
            of: controller,
            as: .image(precision: 0.98, perceptualPrecision: 0.98, size: snapshotSize),
            named: name,
            file: filePath,
            testName: testName,
            line: line
        )
    }
}
