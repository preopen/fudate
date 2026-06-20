// swiftlint:disable file_length
import Engine
@testable import PrepFlow
import PrepFlowData
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
// swiftlint:disable:next type_body_length
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
        let restoredAuthStore = AuthStore(database: database)
        XCTAssertEqual(restoredAuthStore.session, session)
        XCTAssertEqual(restoredAuthStore.email, session.email)

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
        restoredAuthStore.signOut()
        XCTAssertNil(AuthStore(database: database).session)

        let appleStore = AuthStore(database: database)
        appleStore.signInWithApple()
        XCTAssertEqual(appleStore.session?.provider, .apple)
        XCTAssertEqual(try database.rows(.ownerAccount, tenantID: session.tenantID).count, 1)
    }

    func testAuthEnvironmentReportsLocalFallbackAndStagingReadiness() throws {
        let localEnvironment = AuthEnvironment(
            supabaseURL: "",
            supabaseAnonKey: "",
            appleServicesID: "",
            appleTeamID: "",
            magicLinkRedirectURL: "prepflow://auth-callback"
        )
        XCTAssertTrue(localEnvironment.usesLocalSQLiteFallback)
        XCTAssertFalse(localEnvironment.isReadyForStagingAuth)
        XCTAssertEqual(
            localEnvironment.missingSecrets,
            ["SUPABASE_URL", "SUPABASE_ANON_KEY", "APPLE_SERVICES_ID", "APPLE_TEAM_ID"]
        )
        XCTAssertEqual(localEnvironment.settingsReadinessLabel, "SQLite 起動可")

        let partialEnvironment = AuthEnvironment(
            supabaseURL: "https://project.supabase.co",
            supabaseAnonKey: "anon-key",
            appleServicesID: "",
            appleTeamID: "TEAMID",
            magicLinkRedirectURL: "prepflow://auth-callback"
        )
        XCTAssertFalse(partialEnvironment.usesLocalSQLiteFallback)
        XCTAssertFalse(partialEnvironment.isReadyForStagingAuth)
        XCTAssertEqual(partialEnvironment.missingSecrets, ["APPLE_SERVICES_ID"])
        XCTAssertEqual(partialEnvironment.settingsReadinessLabel, "不足: APPLE_SERVICES_ID")

        let stagingEnvironment = AuthEnvironment(
            supabaseURL: "https://project.supabase.co",
            supabaseAnonKey: "anon-key",
            appleServicesID: "com.prepflow.app",
            appleTeamID: "TEAMID",
            magicLinkRedirectURL: "prepflow://auth-callback"
        )
        XCTAssertFalse(stagingEnvironment.usesLocalSQLiteFallback)
        XCTAssertTrue(stagingEnvironment.isReadyForStagingAuth)
        XCTAssertTrue(stagingEnvironment.missingSecrets.isEmpty)
        XCTAssertEqual(stagingEnvironment.settingsReadinessLabel, "Staging 認証OK")

        let store = try AuthStore(database: PrepFlowDatabase(), environment: partialEnvironment)
        XCTAssertFalse(store.usesLocalSQLiteFallback)
        XCTAssertFalse(store.isReadyForStagingAuth)
        XCTAssertEqual(store.missingSecretsText, "APPLE_SERVICES_ID")
    }

    func testAuthenticatedRouteRestoresP0ProgressAfterRelaunch() throws {
        let database = try PrepFlowDatabase()
        let authStore = AuthStore(database: database)
        authStore.signInWithApple()
        let session = try XCTUnwrap(authStore.session)

        let activationStore = BoardStore(database: database, tenantID: session.tenantID)
        XCTAssertEqual(AuthenticatedScreen.restoredInitialScreen(for: activationStore), .activation)

        activationStore.applySimulationAdjustment()
        let simulationStore = BoardStore(database: database, tenantID: session.tenantID)
        XCTAssertEqual(AuthenticatedScreen.restoredInitialScreen(for: simulationStore), .simulation)

        simulationStore.generateBoardFromService()
        let boardStore = BoardStore(database: database, tenantID: session.tenantID)
        XCTAssertEqual(AuthenticatedScreen.restoredInitialScreen(for: boardStore), .board)
    }

    func testP0VerticalSliceStatusFlowsIntoSettingsExportAndRestores() throws {
        let database = try PrepFlowDatabase()
        let authStore = AuthStore(database: database)
        authStore.signInWithApple()
        let session = try XCTUnwrap(authStore.session)
        let store = BoardStore(database: database, tenantID: session.tenantID)

        XCTAssertEqual(store.p0VerticalSliceStatus, "activation_pending")

        store.applySimulationAdjustment()
        XCTAssertEqual(store.p0VerticalSliceStatus, "simulation_ready")

        store.updateOmakaseCovers(14)
        store.generateBoardFromService()
        XCTAssertEqual(store.p0VerticalSliceStatus, "board_generated")

        store.markAllNowDone()
        XCTAssertEqual(store.p0VerticalSliceStatus, "checkoff_rolled_up")

        let export = store.exportSnapshotJSON(authReadinessLabel: "SQLite 起動可")
        XCTAssertTrue(export.contains("\"p0_flow_status\":\"settings_exported\""))
        XCTAssertEqual(store.p0VerticalSliceStatus, "settings_exported")
        XCTAssertEqual(BoardStore(database: database, tenantID: session.tenantID).p0VerticalSliceStatus, "settings_exported")
    }

    func testP0VerticalSliceBEndToEndMatchesHandoffGoldenAndOfflineRestore() throws {
        let database = try PrepFlowDatabase()
        let authStore = AuthStore(database: database)

        XCTAssertNil(authStore.session)
        XCTAssertTrue(authStore.usesLocalSQLiteFallback)

        authStore.signInWithApple()
        let session = try XCTUnwrap(authStore.session)
        XCTAssertEqual(session.provider, .apple)
        XCTAssertEqual(session.tenantID, "tenant-local")

        let activationStore = BoardStore(database: database, tenantID: session.tenantID)
        XCTAssertEqual(AuthenticatedScreen.restoredInitialScreen(for: activationStore), .activation)
        XCTAssertEqual(activationStore.p0VerticalSliceStatus, "activation_pending")

        activationStore.applySimulationAdjustment()
        XCTAssertEqual(AuthenticatedScreen.restoredInitialScreen(for: activationStore), .simulation)
        XCTAssertEqual(activationStore.p0VerticalSliceStatus, "simulation_ready")

        activationStore.updateOpenTime("18:00")
        activationStore.updateOmakaseCovers(14)
        activationStore.updateOtherCovers(0)
        activationStore.generateBoardFromService()

        XCTAssertEqual(AuthenticatedScreen.restoredInitialScreen(for: activationStore), .board)
        XCTAssertEqual(Int(activationStore.nikiriQuantity.total), 200)
        XCTAssertEqual(activationStore.nikiriSchedule.start, "15:00")
        XCTAssertEqual(activationStore.serviceBoardPreviewSummary, "14名 / 200ml / 15:00着手")
        XCTAssertEqual(activationStore.p0VerticalSliceStatus, "board_generated")

        let offlineBoardStore = BoardStore(database: database, tenantID: session.tenantID)
        XCTAssertEqual(offlineBoardStore.serviceBoardPreviewSummary, "14名 / 200ml / 15:00着手")
        XCTAssertEqual(offlineBoardStore.eta.landing, "18:12")
        XCTAssertEqual(offlineBoardStore.eta.shortfallMin, 12)

        let lineGateStatus = offlineBoardStore.markAllNowDone()
        XCTAssertEqual(lineGateStatus.completedCount, lineGateStatus.totalCount)
        XCTAssertTrue(offlineBoardStore.completed.isSuperset(of: ["sake", "tare", "rest"]))
        XCTAssertEqual(offlineBoardStore.nikiriRollupStatus, .done)
        XCTAssertEqual(offlineBoardStore.p0VerticalSliceStatus, "checkoff_rolled_up")

        let export = offlineBoardStore.exportSnapshotJSON(authReadinessLabel: authStore.environment.settingsReadinessLabel)
        XCTAssertTrue(export.contains("\"open_time\":\"18:00\""))
        XCTAssertTrue(export.contains("\"covers\":\"14\""))
        XCTAssertTrue(export.contains("\"eta_landing\":\"18:12\""))
        XCTAssertTrue(export.contains("\"p0_flow_status\":\"settings_exported\""))
        XCTAssertEqual(offlineBoardStore.latestExportSummary, "JSON / SQLite 起動可")

        let restoredAfterOffline = BoardStore(database: database, tenantID: session.tenantID)
        XCTAssertEqual(restoredAfterOffline.p0VerticalSliceStatus, "settings_exported")
        XCTAssertEqual(restoredAfterOffline.serviceBoardPreviewSummary, "14名 / 200ml / 15:00着手")
        XCTAssertEqual(restoredAfterOffline.eta.landing, "18:12")
        XCTAssertTrue(restoredAfterOffline.completed.isSuperset(of: ["sake", "tare", "rest", "nikiri"]))

        let eventTypes = try database.rows(.eventLog, tenantID: session.tenantID).compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("simulation.adjusted"))
        XCTAssertTrue(eventTypes.contains("board.generated"))
        XCTAssertTrue(eventTypes.contains("today_prep.batch_completed"))
        XCTAssertTrue(eventTypes.contains("task.completed"))
        XCTAssertTrue(eventTypes.contains("data.exported"))
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

    func testDishAndStaffBoardRowsToggleCanonicalTasks() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake", "shari", "neta"], database: database)

        store.toggleDishBoardTask("dish-wan-suiji")
        XCTAssertTrue(store.completed.contains("suiji"))

        store.toggleStaffBoardTask("staff-garde-wandane")
        XCTAssertTrue(store.completed.contains("wandane"))

        store.toggleStaffBoardTask("staff-shari-rice")
        XCTAssertFalse(store.completed.contains("shari"))
        store.toggleStaffBoardTask("staff-shari-rice")
        XCTAssertTrue(store.completed.contains("shari"))

        store.toggleDishBoardTask("dish-omakase-nikiri")
        XCTAssertFalse(store.completed.contains("nikiri"))
        XCTAssertEqual(store.todayPrepStartedAt["tare"], "17:25")

        store.toggleDishBoardTask("dish-omakase-nikiri")
        XCTAssertFalse(store.completed.contains("tare"))
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("未完:"))

        store.completeCurrentTodayPrepChecks()
        store.toggleStaffBoardTask("staff-chef-nikiri")
        XCTAssertTrue(store.completed.contains("tare"))
        XCTAssertFalse(store.completed.contains("nikiri"))
        XCTAssertEqual(store.todayPrepProgress.nextStepID, "rest")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("board.dish_task_toggled"))
        XCTAssertTrue(eventTypes.contains("board.staff_task_toggled"))
        XCTAssertTrue(eventTypes.contains("today_prep.aggregate_step_routed"))
        XCTAssertTrue(eventTypes.contains("today_prep.board_step_started"))
        XCTAssertTrue(eventTypes.contains("today_prep.completion_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.step_toggled"))
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
        store.updateSelectedTask(
            coeffPerCover: 20,
            yieldPercent: 100,
            sectionName: "ガルド",
            instruction: "温度を確認して冷ます"
        )

        XCTAssertEqual(Int(store.nikiriQuantity.total), 280)
        XCTAssertEqual(store.selectedCatalogTask.sectionName, "ガルド")
        XCTAssertEqual(store.selectedCatalogTask.instruction, "温度を確認して冷ます")
        let taskRows = try database.rows(.prepTask, tenantID: "tenant-local")
        let nikiriRow = try XCTUnwrap(taskRows.first { $0.id == "task-nikiri" })
        XCTAssertEqual(nikiriRow.values["coeff_per_cover"], "20")
        XCTAssertEqual(nikiriRow.values["section_id"], "section-garde")
        XCTAssertEqual(nikiriRow.values["instruction"], "温度を確認して冷ます")

        assertCatalogRestoresEditedGraph(database)

        store.saveCatalogForBoard()
        XCTAssertEqual(store.catalogSaveCount, 1)
        XCTAssertNotNil(store.catalogLastSavedAt)
        XCTAssertTrue(store.catalogBoardPreviewSummary?.contains("煮切り仕込み") == true)

        store.previewCatalogOnBoard()
        XCTAssertEqual(store.catalogSaveCount, 1)
        XCTAssertEqual(store.serviceBoardGenerateCount, 1)
        store.previewCatalogOnBoard()
        XCTAssertEqual(store.catalogSaveCount, 1)
        XCTAssertEqual(store.serviceBoardGenerateCount, 1)
        try assertCatalogBoardStateRestores(database)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("catalog.saved"))
        XCTAssertTrue(eventTypes.contains("catalog.save_skipped"))
        XCTAssertTrue(eventTypes.contains("catalog.previewed_on_board"))
        XCTAssertTrue(eventTypes.contains("catalog.preview_skipped"))
        XCTAssertTrue(eventTypes.contains("board.generated"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "catalog.saved" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "catalog.previewed_on_board" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "board.generated" }), 1)
    }

    private func assertCatalogRestoresEditedGraph(_ database: PrepFlowDatabase) {
        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.catalog.dishes.count, 2)
        XCTAssertEqual(restoredStore.catalog.dishes.flatMap(\.components).count, 4)
        XCTAssertEqual(restoredStore.catalog.dishes.flatMap { $0.components.flatMap(\.tasks) }.count, 4)
        XCTAssertEqual(restoredStore.selectedCatalogTask.id, "task-nikiri")
        XCTAssertEqual(restoredStore.selectedCatalogTask.coeffPerCover, 20)
        XCTAssertEqual(restoredStore.selectedCatalogTask.sectionName, "ガルド")
        XCTAssertEqual(restoredStore.selectedCatalogTask.instruction, "温度を確認して冷ます")
    }

    private func assertCatalogBoardStateRestores(_ database: PrepFlowDatabase) throws {
        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.catalogSaveCount, 1)
        XCTAssertNotNil(restoredStore.catalogLastSavedAt)
        XCTAssertTrue(restoredStore.catalogBoardPreviewSummary?.contains("煮切り仕込み") == true)
        XCTAssertEqual(restoredStore.serviceBoardGenerateCount, 1)
        XCTAssertTrue(restoredStore.serviceBoardPreviewSummary?.contains("14名") == true)

        restoredStore.previewCatalogOnBoard()
        XCTAssertEqual(restoredStore.catalogSaveCount, 1)
        XCTAssertEqual(restoredStore.serviceBoardGenerateCount, 1)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "catalog.saved" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "catalog.previewed_on_board" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "board.generated" }), 1)
    }

    func testCatalogCustomSequenceRestoresWithoutIDCollision() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.addDish()
        store.addComponent()
        store.addTask()

        let restoredStore = BoardStore(database: database)
        restoredStore.addTask()

        XCTAssertEqual(restoredStore.selectedCatalogTask.id, "task-custom-4")
        XCTAssertEqual(try database.rows(.prepTask, tenantID: "tenant-local").count, 5)
    }

    func testCatalogInvalidSelectionOperationsAreAudited() throws {
        var catalog = CatalogTemplate.seed
        catalog.selectedTaskID = "task-missing"
        let database = try PrepFlowDatabase()
        let store = BoardStore(catalog: catalog, database: database)

        store.selectTask("task-not-found")
        store.addTask()
        store.updateSelectedTask(name: "無効な更新")

        XCTAssertEqual(try database.rows(.prepTask, tenantID: "tenant-local").count, 3)
        XCTAssertEqual(store.catalog.selectedTaskID, "task-missing")

        let emptyDatabase = try PrepFlowDatabase()
        let emptyStore = BoardStore(catalog: CatalogTemplate(id: "empty", courseName: "空", dishes: [], selectedTaskID: "none"), database: emptyDatabase)
        emptyStore.addComponent()

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("catalog.task_select_blocked"))
        XCTAssertTrue(eventTypes.contains("catalog.task_add_blocked"))
        XCTAssertTrue(eventTypes.contains("catalog.task_update_blocked"))
        let emptyEvents = try emptyDatabase.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(emptyEvents.contains("catalog.component_add_blocked"))
    }

    func testCatalogTaskUpdateRejectsInvalidScaleAndScheduleInputs() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.selectTask("task-nikiri")
        let originalQuantity = Int(store.nikiriQuantity.total)
        store.updateSelectedTask(coeffPerCover: -.infinity)
        store.updateSelectedTask(yieldPercent: 0)
        store.updateSelectedTask(durationMin: -5)
        store.updateSelectedTask(leadMinBeforeOpen: -10)

        XCTAssertEqual(Int(store.nikiriQuantity.total), originalQuantity)
        XCTAssertEqual(store.selectedCatalogTask.coeffPerCover, 14)
        XCTAssertEqual(store.selectedCatalogTask.yieldPercent, 100)
        XCTAssertEqual(store.selectedCatalogTask.durationMin, 40)
        XCTAssertEqual(store.selectedCatalogTask.leadMinBeforeOpen, 180)

        let nikiriRow = try XCTUnwrap(try database.rows(.prepTask, tenantID: "tenant-local").first { $0.id == "task-nikiri" })
        XCTAssertEqual(nikiriRow.values["coeff_per_cover"], "14")
        XCTAssertEqual(nikiriRow.values["yield"], "1")
        XCTAssertEqual(nikiriRow.values["duration_min"], "40")
        XCTAssertEqual(nikiriRow.values["lead_min_before_open"], "180")

        store.updateSelectedTask(coeffPerCover: 12, yieldPercent: 80, durationMin: 35, leadMinBeforeOpen: 150)
        XCTAssertEqual(store.selectedCatalogTask.coeffPerCover, 12)
        XCTAssertEqual(store.selectedCatalogTask.yieldPercent, 80)
        XCTAssertEqual(store.selectedCatalogTask.durationMin, 35)
        XCTAssertEqual(store.selectedCatalogTask.leadMinBeforeOpen, 150)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "catalog.task_update_blocked" }), 4)
    }

    func testCatalogTaskUpdateRejectsBlankNameAndSection() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.selectTask("task-nikiri")
        store.updateSelectedTask(name: "   ")
        store.updateSelectedTask(sectionName: "\n\t")

        XCTAssertEqual(store.selectedCatalogTask.name, "煮切り仕込み")
        XCTAssertEqual(store.selectedCatalogTask.sectionName, "親方")
        var nikiriRow = try XCTUnwrap(try database.rows(.prepTask, tenantID: "tenant-local").first { $0.id == "task-nikiri" })
        XCTAssertEqual(nikiriRow.values["name"], "煮切り仕込み")
        XCTAssertEqual(nikiriRow.values["section_id"], "section-oyakata")

        store.updateSelectedTask(name: "  煮切り調整  ", sectionName: "  ガルド  ")
        XCTAssertEqual(store.selectedCatalogTask.name, "煮切り調整")
        XCTAssertEqual(store.selectedCatalogTask.sectionName, "ガルド")
        nikiriRow = try XCTUnwrap(try database.rows(.prepTask, tenantID: "tenant-local").first { $0.id == "task-nikiri" })
        XCTAssertEqual(nikiriRow.values["name"], "煮切り調整")
        XCTAssertEqual(nikiriRow.values["section_id"], "section-garde")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "catalog.task_update_blocked" }), 2)
    }

    func testServiceDayInputsReflectInQuantityAndSchedule() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        XCTAssertEqual(Int(store.nikiriQuantity.total), 200)
        XCTAssertEqual(store.nikiriSchedule.start, "15:00")

        assertInvalidServiceInputsAreClampedOrBlocked(store)

        store.updateOmakaseCovers(10)
        XCTAssertEqual(Int(store.nikiriQuantity.total), 140)

        store.updateOpenTime("19:00")
        XCTAssertEqual(store.nikiriSchedule.start, "16:00")

        let coverRows = try database.rows(.serviceCover, tenantID: "tenant-local")
        let coverRow = try XCTUnwrap(coverRows.first { $0.id == "cover-omakase" })
        XCTAssertEqual(coverRow.values["covers"], "10")

        store.updateReservation("reservation-sato", covers: 3, note: "人数変更")
        XCTAssertEqual(store.service.reservations.first { $0.id == "reservation-sato" }?.covers, 3)
        XCTAssertEqual(store.service.omakaseCovers, 15)

        store.deleteReservation("reservation-suzuki")
        XCTAssertFalse(store.service.reservations.contains { $0.id == "reservation-suzuki" })
        XCTAssertEqual(store.service.omakaseCovers, 11)

        store.editReservation("reservation-missing-edit")
        store.updateReservation("reservation-missing-update", covers: 6, note: "存在しない予約")
        store.deleteReservation("reservation-missing-delete")
        XCTAssertEqual(store.service.omakaseCovers, 11)
        XCTAssertFalse(store.service.reservations.contains { $0.id.hasPrefix("reservation-missing") })

        store.generateBoardFromService()
        XCTAssertEqual(store.serviceBoardGenerateCount, 1)
        XCTAssertNotNil(store.serviceBoardGeneratedAt)
        XCTAssertTrue(store.serviceBoardPreviewSummary?.contains("11名") == true)
        store.generateBoardFromService()
        XCTAssertEqual(store.serviceBoardGenerateCount, 1)

        let activeReservations = try database.rows(.reservation, tenantID: "tenant-local")
        XCTAssertFalse(activeReservations.contains { $0.id == "reservation-suzuki" })
        let updatedReservation = try XCTUnwrap(activeReservations.first { $0.id == "reservation-sato" })
        XCTAssertEqual(updatedReservation.values["covers"], "3")
        XCTAssertEqual(updatedReservation.values["note"], "人数変更")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("reservation.updated"))
        XCTAssertTrue(eventTypes.contains("reservation.deleted"))
        XCTAssertTrue(eventTypes.contains("reservation.update_blocked"))
        XCTAssertTrue(eventTypes.contains("reservation.delete_blocked"))
        XCTAssertTrue(eventTypes.contains("board.generated"))
        XCTAssertTrue(eventTypes.contains("board.generate_skipped"))
        XCTAssertTrue(eventTypes.contains("service_cover.update_clamped"))
        XCTAssertTrue(eventTypes.contains("service_time.update_blocked"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_cover.update_clamped" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_time.update_blocked" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.update_blocked" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.delete_blocked" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "board.generated" }), 1)
    }

    func testReservationUpdateClampsInvalidCoversWithAuditTrail() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.updateReservation("reservation-sato", covers: 0, note: "0名入力")

        XCTAssertEqual(store.service.reservations.first { $0.id == "reservation-sato" }?.covers, 1)
        XCTAssertEqual(store.service.omakaseCovers, 13)
        let reservation = try XCTUnwrap(try database.rows(.reservation, tenantID: "tenant-local").first { $0.id == "reservation-sato" })
        XCTAssertEqual(reservation.values["covers"], "1")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("reservation.update_clamped"))
        XCTAssertTrue(eventTypes.contains("reservation.updated"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.update_clamped" }), 1)
    }

    func testReservationNoteNormalizesAndPersistsWithAuditTrail() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.updateReservation("reservation-sato", covers: 2, note: "  席札確認  \n")

        XCTAssertEqual(store.service.reservations.first { $0.id == "reservation-sato" }?.note, "席札確認")
        var reservation = try XCTUnwrap(try database.rows(.reservation, tenantID: "tenant-local").first { $0.id == "reservation-sato" })
        XCTAssertEqual(reservation.values["note"], "席札確認")

        let longNote = String(repeating: "メ", count: 180)
        store.updateReservation("reservation-sato", covers: 2, note: longNote)

        let storedNote = try XCTUnwrap(store.service.reservations.first { $0.id == "reservation-sato" }?.note)
        XCTAssertEqual(storedNote.count, 160)
        reservation = try XCTUnwrap(try database.rows(.reservation, tenantID: "tenant-local").first { $0.id == "reservation-sato" })
        XCTAssertEqual(reservation.values["note"]?.count, 160)

        store.addManualReservation()
        let manualReservation = try XCTUnwrap(try database.rows(.reservation, tenantID: "tenant-local").first { $0.id.hasPrefix("reservation-manual-") })
        XCTAssertEqual(manualReservation.values["note"], "手入力・当日追加")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.note_normalized" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.updated" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.created" }), 1)
    }

    func testServiceSetupRestoresManualCoversPeriodAndReservations() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.selectServicePeriod("period-part2")
        store.updateOtherCovers(3)
        store.updateReservation("reservation-sato", covers: 5, note: "  復元確認  ")
        store.deleteReservation("reservation-tanaka")
        store.addManualReservation()

        let restored = BoardStore(database: database)

        XCTAssertEqual(restored.service.selectedPeriodID, "period-part2")
        XCTAssertEqual(restored.service.openTime, "20:30")
        XCTAssertEqual(restored.service.period, "夜 第二部")
        XCTAssertEqual(restored.service.otherCovers, 3)
        XCTAssertEqual(restored.service.omakaseCovers, 17)
        XCTAssertEqual(restored.service.totalCovers, 20)
        XCTAssertNil(restored.service.reservations.first { $0.id == "reservation-tanaka" })
        XCTAssertEqual(restored.service.reservations.first { $0.id == "reservation-sato" }?.covers, 5)
        XCTAssertEqual(restored.service.reservations.first { $0.id == "reservation-sato" }?.note, "復元確認")
        XCTAssertTrue(restored.service.reservations.contains { $0.id.hasPrefix("reservation-manual-") })

        let otherCovers = try XCTUnwrap(try database.rows(.settings, tenantID: "tenant-local").first { $0.id == "setting-service-other-covers" })
        XCTAssertEqual(otherCovers.values["value"], "3")
        let serviceDay = try XCTUnwrap(try database.rows(.serviceDay, tenantID: "tenant-local").first { $0.id == "service-2026-06-11-dinner" })
        XCTAssertEqual(serviceDay.values["service_period"], "part2")
        XCTAssertEqual(serviceDay.values["open_time"], "20:30")
    }

    func testServicePeriodSelectionRemainsIdempotentAfterRelaunchAndManualTimeEdit() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.selectServicePeriod("period-part2")

        let restored = BoardStore(database: database)
        restored.selectServicePeriod("period-part2")
        XCTAssertEqual(restored.service.openTime, "20:30")

        restored.updateOpenTime("20:45")
        XCTAssertEqual(restored.service.openTime, "20:45")

        restored.selectServicePeriod("period-part2")
        XCTAssertEqual(restored.service.openTime, "20:30")
        restored.selectServicePeriod("period-part2")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_period.selected" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_period.select_skipped" }), 2)
    }

    func testServiceAndReservationInputsClampUpperBoundsBeforePersistence() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.updateOmakaseCovers(250)
        store.updateOtherCovers(230)

        XCTAssertEqual(store.service.omakaseCovers, 200)
        XCTAssertEqual(store.service.otherCovers, 200)
        XCTAssertEqual(try XCTUnwrap(database.rows(.serviceCover, tenantID: "tenant-local").first?.values["covers"]), "200")

        store.updateReservation("reservation-sato", covers: 99, note: "上限超過")

        XCTAssertEqual(store.service.reservations.first { $0.id == "reservation-sato" }?.covers, 60)
        XCTAssertEqual(store.service.omakaseCovers, 72)
        let reservation = try XCTUnwrap(try database.rows(.reservation, tenantID: "tenant-local").first { $0.id == "reservation-sato" })
        XCTAssertEqual(reservation.values["covers"], "60")
        let cover = try XCTUnwrap(try database.rows(.serviceCover, tenantID: "tenant-local").first { $0.id == "cover-omakase" })
        XCTAssertEqual(cover.values["covers"], "72")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_cover.update_clamped" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.update_clamped" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.updated" }), 1)
    }

    func testManualReservationEditsAfterBoardGenerationReturnToPrepChecks() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.generateBoardFromService()
        store.markAllNowDone()

        store.updateReservation("reservation-sato", covers: 5, note: "当日増員")
        store.updateReservation("reservation-sato", covers: 5, note: "当日増員")
        store.deleteReservation("reservation-suzuki")

        XCTAssertEqual(store.service.omakaseCovers, 13)
        XCTAssertEqual(Set(store.todayPrepImpactItems.map(\.sourceLabel)), ["手入力予約"])
        XCTAssertEqual(store.todayPrepImpactItems.count, 2)
        XCTAssertFalse(store.lineGateStatus.canOpen)

        _ = store.issueNikiriPrepLabel(printedAt: "2026-06-11T16:20:00Z")
        XCTAssertNil(store.latestPrepLabel)

        for impact in store.todayPrepImpactItems.map(\.id) {
            store.applyTodayPrepImpact(impact)
        }
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:42")
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:51")

        _ = store.issueNikiriPrepLabel(printedAt: "2026-06-11T16:20:00Z")
        XCTAssertNotNil(store.latestPrepLabel)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.diffed" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.update_skipped" }), 1)
        XCTAssertTrue(eventTypes.contains("today_prep.impact_queued"))
        XCTAssertTrue(eventTypes.contains("label.issue_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.impact_applied"))
    }

    func testSimulationAppliesCoefficientsAndRecordsWasteLog() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        XCTAssertEqual(Int(store.nikiriQuantity.total), 200)
        store.changeSimulationPeriod()
        XCTAssertEqual(store.simulationPeriodDays, 30)
        XCTAssertEqual(store.simulationDateRange, "5/16〜6/14")
        XCTAssertTrue(store.simulationLastAdjustmentSummary?.contains("期間 30日") == true)

        store.applySimulationAdjustment()
        assertSimulationAdjustedState(store)

        store.applySimulationAdjustment()
        assertSimulationAdjustedState(store)

        store.applySimulationCoefficients()
        XCTAssertEqual(Int(store.nikiriQuantity.total), 170)
        XCTAssertEqual(store.simulationAppliedCount, 1)
        XCTAssertNotNil(store.simulationAppliedAt)
        XCTAssertTrue(store.simulationBoardImpactSummary?.contains("14名") == true)
        XCTAssertEqual(store.serviceBoardGenerateCount, 1)
        store.applySimulationCoefficients()
        XCTAssertEqual(store.simulationAppliedCount, 1)
        XCTAssertEqual(store.serviceBoardGenerateCount, 1)
        try assertSimulationRestoresAppliedState(database)

        store.recordNikiriWaste()
        store.recordNikiriWaste()
        let wasteRows = try database.rows(.wasteLog, tenantID: "tenant-local")
        XCTAssertEqual(wasteRows.count(where: { $0.values["prep_task_id"] == "task-nikiri" }), 1)
        let waste = try XCTUnwrap(wasteRows.first)
        XCTAssertEqual(waste.values["prep_task_id"], "task-nikiri")
        XCTAssertEqual(waste.values["made_qty"], "240")
        XCTAssertEqual(waste.values["leftover_qty"], "40")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("simulation.period_changed"))
        XCTAssertTrue(eventTypes.contains("simulation.adjusted"))
        XCTAssertTrue(eventTypes.contains("simulation.adjust_skipped"))
        XCTAssertTrue(eventTypes.contains("simulation.applied"))
        XCTAssertTrue(eventTypes.contains("simulation.apply_skipped"))
        XCTAssertTrue(eventTypes.contains("board.generated"))
        XCTAssertTrue(eventTypes.contains("waste.recorded"))
        XCTAssertTrue(eventTypes.contains("waste.record_skipped"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "simulation.applied" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "simulation.adjusted" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "simulation.adjust_skipped" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "board.generated" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "waste.recorded" }), 1)
    }

    private func assertSimulationAdjustedState(_ store: BoardStore) {
        XCTAssertEqual(store.simulationAdjustmentCount, 1)
        XCTAssertEqual(store.simulation.hitRatePercent, 89)
        XCTAssertEqual(store.simulation.stockoutRisks, 1)
        XCTAssertTrue(store.simulationLastAdjustmentSummary?.contains("安全係数 +10%") == true)
        XCTAssertEqual(store.simulation.items.first { $0.outcome == .risk }?.recommended, 15)
    }

    private func assertSimulationRestoresAppliedState(_ database: PrepFlowDatabase) throws {
        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.simulationPeriodDays, 30)
        XCTAssertEqual(restoredStore.simulationDateRange, "5/16〜6/14")
        XCTAssertEqual(restoredStore.simulationAdjustmentCount, 1)
        XCTAssertEqual(restoredStore.simulation.hitRatePercent, 89)
        XCTAssertEqual(restoredStore.simulation.stockoutRisks, 1)
        XCTAssertEqual(restoredStore.simulation.items.first { $0.outcome == .risk }?.recommended, 15)
        XCTAssertEqual(restoredStore.simulationAppliedCount, 1)
        XCTAssertTrue(restoredStore.simulationBoardImpactSummary?.contains("14名") == true)
        XCTAssertEqual(restoredStore.serviceBoardGenerateCount, 1)
        XCTAssertEqual(Int(restoredStore.nikiriQuantity.total), 170)

        restoredStore.applySimulationCoefficients()
        restoredStore.generateBoardFromService()
        XCTAssertEqual(restoredStore.simulationAppliedCount, 1)
        XCTAssertEqual(restoredStore.serviceBoardGenerateCount, 1)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "simulation.applied" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "board.generated" }), 1)
    }

    func testWasteAndCarryoverRejectInvalidQuantitiesBeforePersistence() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.recordNikiriWaste(madeQty: -1, leftoverQty: 0)
        store.recordNikiriWaste(madeQty: 40, leftoverQty: 80)
        store.recordNikiriWaste(madeQty: .nan, leftoverQty: 1)
        store.recordNikiriCarryover(qty: 0)
        store.recordNikiriCarryover(qty: -.infinity)

        XCTAssertTrue(try database.rows(.wasteLog, tenantID: "tenant-local").isEmpty)
        XCTAssertTrue(try database.rows(named: "carryover", tenantID: "tenant-local").isEmpty)

        store.recordNikiriWaste(madeQty: 100, leftoverQty: 20)
        store.recordNikiriCarryover(qty: 12)

        let waste = try XCTUnwrap(try database.rows(.wasteLog, tenantID: "tenant-local").first)
        XCTAssertEqual(waste.values["made_qty"], "100")
        XCTAssertEqual(waste.values["leftover_qty"], "20")
        let carryover = try XCTUnwrap(try database.rows(named: "carryover", tenantID: "tenant-local").first)
        XCTAssertEqual(carryover.values["qty"], "12")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "waste.record_blocked" }), 3)
        XCTAssertEqual(eventTypes.count(where: { $0 == "carryover.create_blocked" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "waste.recorded" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "carryover.created" }), 1)
    }

    func testP1DailyOpsPersistServicePeriodAssignmentETACarryoverAndExport() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.selectServicePeriod("period-part2")
        store.selectServicePeriod("period-part2")
        store.selectServicePeriod("period-missing")
        XCTAssertEqual(store.service.openTime, "20:30")
        XCTAssertEqual(store.service.selectedPeriodID, "period-part2")

        try assertPart2ServicePeriodPersists(database)

        store.assignNikiri(toSectionName: "ガルド")
        store.assignNikiri(toSectionName: "ガルド")
        store.generateBoardFromService()
        let taskRows = try database.rows(.prepTask, tenantID: "tenant-local")
        let nikiriTask = try XCTUnwrap(taskRows.first { $0.id == "task-nikiri" })
        XCTAssertEqual(nikiriTask.values["section_id"], "section-garde")

        let instanceRows = try database.rows(.taskInstance, tenantID: "tenant-local")
        let nikiriInstance = try XCTUnwrap(instanceRows.first { $0.id == "instance-task-nikiri" })
        XCTAssertEqual(nikiriInstance.values["assignee_section_id"], "section-garde")

        store.recordETAInput(now: "20:00", remainingDurationsMin: [12, 10])
        store.recordETAInput(now: "20:00", remainingDurationsMin: [12, 10])
        XCTAssertEqual(store.eta.landing, "20:22")
        XCTAssertEqual(store.eta.shortfallMin, 0)
        assertDailyOpsETARestores(database)

        store.recordNikiriCarryover(qty: 36)
        store.recordNikiriCarryover(qty: 36)
        let carryoverRows = try database.rows(named: "carryover", tenantID: "tenant-local")
        XCTAssertEqual(carryoverRows.count(where: { $0.values["prep_task_id"] == "task-nikiri" }), 1)
        let carryover = try XCTUnwrap(carryoverRows.first)
        XCTAssertEqual(carryover.values["prep_task_id"], "task-nikiri")
        XCTAssertEqual(carryover.values["qty"], "36")
        XCTAssertEqual(carryover.values["status"], "available")

        store.toggleSettingsLock()
        XCTAssertFalse(store.settingsLocked)
        assertExportSnapshotIncludesStagingReadiness(store)
        XCTAssertFalse(BoardStore(database: database).settingsLocked)
        XCTAssertEqual(BoardStore(database: database).latestExportSummary, "JSON / 不足: APPLE_SERVICES_ID")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("service_period.selected"))
        XCTAssertTrue(eventTypes.contains("service_period.select_skipped"))
        XCTAssertTrue(eventTypes.contains("service_period.select_blocked"))
        XCTAssertTrue(eventTypes.contains("task.assigned"))
        XCTAssertTrue(eventTypes.contains("task.assignment_skipped"))
        XCTAssertTrue(eventTypes.contains("eta.recorded"))
        XCTAssertTrue(eventTypes.contains("eta.record_skipped"))
        XCTAssertTrue(eventTypes.contains("carryover.created"))
        XCTAssertTrue(eventTypes.contains("carryover.create_skipped"))
        XCTAssertTrue(eventTypes.contains("data.exported"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "task.assigned" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "eta.recorded" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "carryover.created" }), 1)
    }

    func testETAInputRejectsInvalidTimeAndDurationsBeforePersistence() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.recordETAInput(now: "invalid", remainingDurationsMin: [12, 10])
        store.recordETAInput(now: "17:30", remainingDurationsMin: [])
        store.recordETAInput(now: "17:30", remainingDurationsMin: [-1])
        store.recordETAInput(now: "17:30", remainingDurationsMin: [241])
        store.recordETAInput(now: "17:30", remainingDurationsMin: [240, 240, 1])

        XCTAssertEqual(store.eta.landing, "18:12")
        XCTAssertFalse(try database.rows(.settings, tenantID: "tenant-local").contains { $0.id == "setting-eta-last" })

        store.recordETAInput(now: "17:30", remainingDurationsMin: [12, 10])

        XCTAssertEqual(store.eta.landing, "17:52")
        let setting = try XCTUnwrap(try database.rows(.settings, tenantID: "tenant-local").first { $0.id == "setting-eta-last" })
        XCTAssertTrue(setting.values["value"]?.contains("\"landing\":\"17:52\"") == true)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "eta.record_blocked" }), 5)
        XCTAssertEqual(eventTypes.count(where: { $0 == "eta.recorded" }), 1)
    }

    func testP15DayrailAndSubrecipeAggregatePersistAndRollUp() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.generateBoardFromService()
        store.prepareDayrail()
        store.prepareDayrail()

        XCTAssertEqual(store.dayrailItems.count, 5)
        XCTAssertEqual(Set(store.dayrailItems.map(\.kind)), [.prep, .service, .close])
        let dayrailRows = try database.rows(named: "dayrail_item", tenantID: "tenant-local")
        XCTAssertEqual(dayrailRows.count, 5)
        XCTAssertEqual(Set(dayrailRows.compactMap { $0.values["sort"] }), ["0", "1", "2", "3", "4"])

        store.updateOtherCovers(2)
        let aggregate = store.aggregateSharedPrep()
        let duplicateAggregate = store.aggregateSharedPrep()
        XCTAssertEqual(aggregate.totalCovers, 16)
        XCTAssertEqual(duplicateAggregate, aggregate)
        XCTAssertEqual(Int(aggregate.quantity.total), 220)
        XCTAssertEqual(aggregate.sources, ["omakase:14", "walkin:2"])
        assertDailyOpsRailAndAggregateRestore(database, aggregate: aggregate)

        let instanceRows = try database.rows(.taskInstance, tenantID: "tenant-local")
        XCTAssertEqual(instanceRows.count(where: { $0.values["prep_task_id"] == "task-nikiri" }), 1)

        let aggregateRows = try database.rows(named: "subrecipe_aggregate", tenantID: "tenant-local")
        let aggregateRow = try XCTUnwrap(aggregateRows.first)
        XCTAssertEqual(aggregateRow.values["prep_task_id"], "task-nikiri")
        XCTAssertEqual(aggregateRow.values["total_covers"], "16")
        XCTAssertEqual(aggregateRow.values["total_qty"], "220")
        XCTAssertEqual(aggregateRow.values["status"], "in_progress")

        store.completeSharedPrepAggregate()
        XCTAssertEqual(store.todayPrepStartedAt["tare"], "17:25")
        XCTAssertFalse(store.completed.contains("tare"))
        let blockedAggregate = try XCTUnwrap(try database.rows(named: "subrecipe_aggregate", tenantID: "tenant-local").first)
        XCTAssertEqual(blockedAggregate.values["status"], "in_progress")

        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:42")
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:51")
        store.completeSharedPrepAggregate()
        let completedAggregate = try XCTUnwrap(try database.rows(named: "subrecipe_aggregate", tenantID: "tenant-local").first)
        XCTAssertEqual(completedAggregate.values["status"], "done")

        let references = try database.rows(named: "subrecipe_reference", tenantID: "tenant-local")
        XCTAssertEqual(references.compactMap { $0.values["course_key"] }.sorted(), ["omakase", "walkin"])
        XCTAssertTrue(references.allSatisfy { $0.values["rollup_status"] == "done" })

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("dayrail.planned"))
        XCTAssertTrue(eventTypes.contains("dayrail.plan_skipped"))
        XCTAssertTrue(eventTypes.contains("subrecipe.aggregated"))
        XCTAssertTrue(eventTypes.contains("subrecipe.aggregate_skipped"))
        XCTAssertTrue(eventTypes.contains("subrecipe.rollup_completion_blocked"))
        XCTAssertTrue(eventTypes.contains("subrecipe.rollup_completed"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "dayrail.planned" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "subrecipe.aggregated" }), 1)
    }

    func testP2CloseLoopCarryoverAndReservationDiffPersistLocally() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.generateBoardFromService()
        let blockedGate = store.completeCloseGate()
        XCTAssertTrue(blockedGate.records.isEmpty)
        XCTAssertNil(store.closeGateCompletedAt)
        XCTAssertEqual(store.closeGateLastAction, "締め表を記録してから完了")
        XCTAssertTrue(try database.rows(.wasteLog, tenantID: "tenant-local").isEmpty)

        let invalidClose = store.recordCloseLoop(madeQty: 40, leftoverQty: 80, wasteReason: .overmade, carryoverToNext: true)
        XCTAssertTrue(invalidClose.records.isEmpty)
        XCTAssertNil(store.closeLoopSummary)
        XCTAssertEqual(store.closeLoopCommitCount, 0)
        XCTAssertEqual(store.closeLoopLastAction, "締め入力を確認")
        XCTAssertTrue(try database.rows(.wasteLog, tenantID: "tenant-local").isEmpty)

        let close = store.recordCloseLoop(madeQty: 240, leftoverQty: 40, wasteReason: .overmade, carryoverToNext: true)

        XCTAssertTrue(store.canCommitCloseLoop(madeQty: 240, leftoverQty: 40))
        XCTAssertFalse(store.canCommitCloseLoop(madeQty: 40, leftoverQty: 80))
        XCTAssertEqual(store.closeLoopCommitCount, 1)
        XCTAssertEqual(close.carryovers, [CarryoverItem(task: "task-nikiri", qty: 40, unit: "ml")])
        XCTAssertEqual(close.nextDayAdjustments.first?.adjusted, 160)
        let waste = try XCTUnwrap(try database.rows(.wasteLog, tenantID: "tenant-local").first { $0.id == "waste-close-task-nikiri-1" })
        XCTAssertEqual(waste.values["waste_reason"], "overmade")
        XCTAssertEqual(waste.values["carryover_to_next"], "1")
        XCTAssertEqual(waste.values["leftover_qty"], "40")

        let carryover = try XCTUnwrap(try database.rows(named: "carryover", tenantID: "tenant-local").first { $0.id == "carryover-task-nikiri-close-1" })
        XCTAssertEqual(carryover.values["qty"], "40")
        XCTAssertEqual(carryover.values["status"], "available")

        store.recordCloseLoop(madeQty: 230, leftoverQty: 30, wasteReason: .quality, carryoverToNext: false)
        XCTAssertEqual(store.closeLoopCommitCount, 2)

        store.markAllNowDone()
        let diff = store.previewReservationCancellation("reservation-sato")

        XCTAssertEqual(diff.cancelledCovers, 2)
        XCTAssertEqual(diff.changedReservationIDs, ["reservation-sato"])
        XCTAssertEqual(store.reservationPlanDiff?.reduced.first?.newCovers, 12)
        XCTAssertEqual(Int(store.reservationPlanDiff?.reduced.first?.newTotal ?? 0), 170)
        XCTAssertEqual(store.reservationPlanDiff?.reduced.first?.carryoverCandidate, true)
        XCTAssertTrue(store.todayPrepImpactItems.contains { $0.sourceLabel == "予約取消" })
        XCTAssertFalse(store.lineGateStatus.canOpen)

        assertMissingReservationPreviewNoops(store)

        let activeReservations = try database.rows(.reservation, tenantID: "tenant-local")
        XCTAssertFalse(activeReservations.contains { $0.id == "reservation-sato" })

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        assertCloseLoopReservationEvents(eventTypes)
    }

    private func assertCloseLoopReservationEvents(_ eventTypes: [String?]) {
        XCTAssertTrue(eventTypes.contains("close.gate_blocked"))
        XCTAssertTrue(eventTypes.contains("close.record_blocked"))
        XCTAssertTrue(eventTypes.contains("close.completed"))
        XCTAssertTrue(eventTypes.contains("close.revised"))
        XCTAssertTrue(eventTypes.contains("nextday.previewed"))
        XCTAssertTrue(eventTypes.contains("reservation.diffed"))
        XCTAssertTrue(eventTypes.contains("reservation.carryover_candidate"))
        XCTAssertTrue(eventTypes.contains("reservation.preview_cancel_blocked"))
        XCTAssertTrue(eventTypes.contains("reservation.preview_increase_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.impact_queued"))
    }

    func testReservationHubActionsSyncMergeAndApplyToPrep() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let synced = store.syncReservationHubSources()

        assertReservationHubSyncedState(synced, store: store)

        _ = store.applyReservationHubToPrep()
        XCTAssertEqual(store.reservationHubApplyCount, 0)

        store.assignReservationHubCourse("reservation-missing")
        XCTAssertNil(store.reservationHubAssignedCourses["reservation-missing"])

        store.assignReservationHubCourse("reservation-tablecheck-suzuki-1800")
        store.assignReservationHubCourse("reservation-tablecheck-suzuki-1800")
        XCTAssertEqual(store.reservationHubAssignedCourses["reservation-tablecheck-suzuki-1800"], "omakase")
        XCTAssertEqual(store.reservationHubUnassignedCovers, 0)
        XCTAssertFalse(store.reservationHubCanApplyToPrep)

        store.keepReservationHubDuplicateSeparate()
        store.keepReservationHubDuplicateSeparate()
        XCTAssertEqual(store.reservationHubDuplicateDecision, "kept_separate")
        XCTAssertTrue(store.service.reservations.contains { $0.id == "reservation-tablecheck-suzuki-1800" })
        XCTAssertTrue(store.reservationHubCanApplyToPrep)

        let merged = store.mergeReservationHubDuplicate()
        let duplicateMerge = store.mergeReservationHubDuplicate()

        XCTAssertEqual(merged.cancelledCovers, 4)
        XCTAssertEqual(duplicateMerge, merged)
        XCTAssertEqual(store.reservationHubDuplicateDecision, "merged")
        XCTAssertEqual(store.reservationHubUnassignedCovers, 0)
        XCTAssertTrue(store.reservationHubCanApplyToPrep)
        XCTAssertEqual(store.service.omakaseCovers, 17)
        XCTAssertFalse(store.service.reservations.contains { $0.id == "reservation-tablecheck-suzuki-1800" })
        XCTAssertTrue(store.service.reservations.contains { $0.id == "reservation-direct-takahashi-1830" })
        XCTAssertEqual(store.service.reservations.count { $0.id == "reservation-direct-takahashi-1830" }, 1)

        let plan = store.applyReservationHubToPrep()

        XCTAssertEqual(Int(plan.added.first?.qty ?? 0), 42)
        XCTAssertEqual(plan.reduced.first?.newCovers, 14)
        XCTAssertEqual(Int(plan.reduced.first?.newTotal ?? 0), 200)
        XCTAssertEqual(store.reservationHubApplyCount, 1)
        XCTAssertNotNil(store.reservationHubAppliedAt)
        let appliedAt = store.reservationHubAppliedAt
        let impactCount = store.todayPrepImpactItems.count

        let duplicatePlan = store.applyReservationHubToPrep()
        XCTAssertEqual(duplicatePlan.added.count, plan.added.count)
        XCTAssertEqual(duplicatePlan.reduced.count, plan.reduced.count)
        XCTAssertEqual(store.reservationHubApplyCount, 1)
        XCTAssertEqual(store.reservationHubAppliedAt, appliedAt)
        XCTAssertEqual(store.todayPrepImpactItems.count, impactCount)
        try assertReservationHubStateRestores(database: database, appliedAt: appliedAt)

        let reservations = try database.rows(.reservation, tenantID: "tenant-local")
        XCTAssertTrue(reservations.contains { $0.id == "reservation-direct-takahashi-1830" })

        try assertReservationHubIdempotencyEvents(database)
    }

    private func assertReservationHubSyncedState(_ diff: ReservationDiffSummary, store: BoardStore) {
        XCTAssertEqual(diff.addedCovers, 4)
        XCTAssertEqual(store.service.omakaseCovers, 18)
        XCTAssertTrue(store.service.reservations.contains { $0.id == "reservation-tablecheck-suzuki-1800" })
        XCTAssertEqual(store.reservationHubUnassignedCovers, 4)
        XCTAssertFalse(store.reservationHubCanApplyToPrep)
    }

    private func assertReservationHubStateRestores(database: PrepFlowDatabase, appliedAt: String?) throws {
        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.reservationHubDuplicateDecision, "merged")
        XCTAssertEqual(restoredStore.reservationHubUnassignedCovers, 0)
        XCTAssertTrue(restoredStore.reservationHubCanApplyToPrep)
        XCTAssertEqual(restoredStore.reservationHubApplyCount, 1)
        XCTAssertEqual(restoredStore.reservationHubAppliedAt, appliedAt)
        XCTAssertEqual(restoredStore.reservationDiffSummary?.cancelledCovers, 4)
        XCTAssertEqual(Int(restoredStore.reservationPlanDiff?.added.first?.qty ?? 0), 42)

        _ = restoredStore.applyReservationHubToPrep()
        XCTAssertEqual(restoredStore.reservationHubApplyCount, 1)
        XCTAssertEqual(try database.rows(.eventLog, tenantID: "tenant-local").count { $0.values["type"] == "reservation.applied_to_prep" }, 1)
    }

    func testP25LabelQRFlowPersistsLarderCarryoverAndWaste() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.generateBoardFromService()
        store.markAllNowDone()
        let label = store.issueNikiriPrepLabel()
        let duplicateLabel = store.issueNikiriPrepLabel()

        XCTAssertEqual(label.id, "label-instance-task-nikiri")
        XCTAssertEqual(duplicateLabel, label)
        XCTAssertEqual(label.status, .active)
        XCTAssertEqual(label.expireAt, "2026-06-12T23:59:00Z")
        XCTAssertEqual(label.storageUnitID, "storage-cold-2")

        let labelRow = try XCTUnwrap(try database.rows(named: "label", tenantID: "tenant-local").first { $0.id == label.id })
        XCTAssertEqual(labelRow.values["task_instance_id"], "instance-task-nikiri")
        XCTAssertEqual(labelRow.values["status"], "active")
        XCTAssertEqual(labelRow.values["qr_token"], "prepflow://label/instance-task-nikiri")

        let issuedLarder = try XCTUnwrap(try database.rows(named: "larder_item", tenantID: "tenant-local").first { $0.id == "larder-\(label.id)" })
        XCTAssertEqual(issuedLarder.values["qty"], "200")
        XCTAssertEqual(issuedLarder.values["status"], "available")

        let remaining = store.scanLatestLabelRemaining(qty: 65)
        XCTAssertEqual(remaining.label.status, .remaining)
        XCTAssertEqual(remaining.larderItem?.qty, 65)
        let blockedReissue = store.issueNikiriPrepLabel()
        XCTAssertEqual(blockedReissue.status, .remaining)

        let remainingLabel = try XCTUnwrap(try database.rows(named: "label", tenantID: "tenant-local").first { $0.id == label.id })
        XCTAssertEqual(remainingLabel.values["status"], "remaining")
        XCTAssertEqual(remainingLabel.values["remaining_qty"], "65")

        let carryover = try XCTUnwrap(try database.rows(named: "carryover", tenantID: "tenant-local").first { $0.id == "carryover-task-nikiri-\(label.id)" })
        XCTAssertEqual(carryover.values["qty"], "65")
        XCTAssertEqual(carryover.values["expire_at"], "2026-06-12T23:59:00Z")

        let inflatedRemaining = store.scanLatestLabelRemaining(qty: 90)
        XCTAssertEqual(inflatedRemaining.label.remainingQty, 65)

        let wasted = store.scanLatestLabelWaste(qty: 120, reason: .quality)
        XCTAssertEqual(wasted.label.status, .wasted)
        XCTAssertEqual(wasted.wasteRecord?.wasteReason, .quality)
        XCTAssertEqual(wasted.wasteRecord?.leftoverQty, 65)

        let wastedLarder = try XCTUnwrap(try database.rows(named: "larder_item", tenantID: "tenant-local").first { $0.id == "larder-\(label.id)" })
        XCTAssertEqual(wastedLarder.values["status"], "wasted")
        XCTAssertEqual(wastedLarder.values["qty"], "0")

        let waste = try XCTUnwrap(try database.rows(.wasteLog, tenantID: "tenant-local").first { $0.values["recorded_by"] == "label-qr" })
        XCTAssertEqual(waste.values["waste_reason"], "quality")
        XCTAssertEqual(waste.values["leftover_qty"], "65")
        XCTAssertEqual(waste.values["carryover_to_next"], "0")

        let used = store.scanLatestLabelUsed()
        XCTAssertEqual(used.label.status, .wasted)
        XCTAssertNil(used.larderItem)
        XCTAssertEqual(store.labelScanLastAction, "QR記録不可: wasted")
        let duplicateUsed = store.scanLatestLabelUsed()
        XCTAssertEqual(duplicateUsed, used)
        XCTAssertEqual(store.labelScanLastAction, "QR記録不可: wasted")

        try assertLabelIssueIdempotencyEvents(database)
    }

    func testLabelScanRejectsNonPositiveQuantitiesWithoutMutatingActiveLabel() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.markAllNowDone()
        let label = store.issueNikiriPrepLabel(madeQty: 100)

        let negativeRemaining = store.scanLatestLabelRemaining(qty: -5)
        XCTAssertEqual(negativeRemaining.label, label)
        XCTAssertNil(negativeRemaining.larderItem)
        XCTAssertNil(negativeRemaining.wasteRecord)
        XCTAssertEqual(store.latestPrepLabel?.status, .active)

        let duplicateNegativeRemaining = store.scanLatestLabelRemaining(qty: -5)
        XCTAssertEqual(duplicateNegativeRemaining, negativeRemaining)

        let zeroWaste = store.scanLatestLabelWaste(qty: 0, reason: .quality)
        XCTAssertEqual(zeroWaste.label, label)
        XCTAssertNil(zeroWaste.larderItem)
        XCTAssertNil(zeroWaste.wasteRecord)
        XCTAssertEqual(store.latestPrepLabel?.status, .active)

        let labelRow = try XCTUnwrap(try database.rows(named: "label", tenantID: "tenant-local").first { $0.id == label.id })
        XCTAssertEqual(labelRow.values["status"], "active")
        let larder = try XCTUnwrap(try database.rows(named: "larder_item", tenantID: "tenant-local").first { $0.id == "larder-\(label.id)" })
        XCTAssertEqual(larder.values["qty"], "100")
        XCTAssertEqual(larder.values["status"], "available")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("label.scan_blocked"))
        XCTAssertTrue(eventTypes.contains("label.scan_blocked_skipped"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "label.scanned" }), 0)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label.scan_blocked" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label.scan_blocked_skipped" }), 1)
    }

    func testP25LabelLarderPhysicalOpsConsumeInspectAndLogTemperature() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.markAllNowDone()
        _ = store.issueNikiriPrepLabel(madeQty: 90, printedAt: "2026-06-12T16:20:00Z")
        _ = store.scanLatestLabelRemaining(qty: 90)

        try assertInvalidLarderUseDoesNotConsume(store: store, database: database)

        let plan = store.applyPlannedLarderUse(requiredQty: 60, nowDate: "2026-06-12")
        XCTAssertEqual(plan.plannedQty, 60)
        XCTAssertEqual(plan.shortfallQty, 0)
        XCTAssertEqual(store.latestLarderUseSummary, "60ml をFIFO使用 / 不足 0ml")

        var larder = try XCTUnwrap(try database.rows(named: "larder_item", tenantID: "tenant-local").first { $0.id == "larder-label-instance-task-nikiri" })
        XCTAssertEqual(larder.values["qty"], "30")
        XCTAssertEqual(larder.values["status"], "available")

        let duplicatePlan = store.applyPlannedLarderUse(requiredQty: 60, nowDate: "2026-06-12")
        XCTAssertEqual(duplicatePlan.plannedQty, 0)
        XCTAssertEqual(duplicatePlan.shortfallQty, 0)
        XCTAssertEqual(store.latestLarderUseSummary, "FIFO使用済み / 再適用なし")
        larder = try XCTUnwrap(try database.rows(named: "larder_item", tenantID: "tenant-local").first { $0.id == "larder-label-instance-task-nikiri" })
        XCTAssertEqual(larder.values["qty"], "30")
        XCTAssertEqual(larder.values["status"], "available")

        store.recordFridgeTemperature(valueC: 3, loggedAt: "2026-06-12T15:50:00Z")
        store.recordFridgeTemperature(valueC: 3, loggedAt: "2026-06-12T15:50:00Z")
        XCTAssertEqual(try database.rows(named: "temp_log", tenantID: "tenant-local").count, 1)
        let temperature = try XCTUnwrap(try database.rows(named: "temp_log", tenantID: "tenant-local").first { $0.id == "temp-storage-cold-2-2026-06-12T15:50:00Z" })
        XCTAssertEqual(temperature.values["kind"], "fridge")
        XCTAssertEqual(temperature.values["value"], "3")
        XCTAssertEqual(store.fridgeTemperatureLoggedAt, "2026-06-12T15:50:00Z")

        let changedCount = store.completeFridgeInspection(nowDate: "2026-06-14")
        XCTAssertEqual(changedCount, 1)
        XCTAssertEqual(store.fridgeInspectionMissingCount, 1)

        larder = try XCTUnwrap(try database.rows(named: "larder_item", tenantID: "tenant-local").first { $0.id == "larder-label-instance-task-nikiri" })
        XCTAssertEqual(larder.values["qty"], "0")
        XCTAssertEqual(larder.values["status"], "expired")

        let duplicateInspectionCount = store.completeFridgeInspection(nowDate: "2026-06-14")
        XCTAssertEqual(duplicateInspectionCount, 1)
        XCTAssertEqual(store.fridgeInspectionMissingCount, 1)
        XCTAssertEqual(store.latestLarderUseSummary, "点検済み / 再実行なし")
        try assertLabelLarderFridgeStateRestores(database: database)

        let waste = try XCTUnwrap(try database.rows(.wasteLog, tenantID: "tenant-local").first { $0.values["recorded_by"] == "fridge-inspection" })
        XCTAssertEqual(waste.values["leftover_qty"], "30")
        XCTAssertEqual(waste.values["waste_reason"], "quality")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        assertLabelLarderFridgeEvents(eventTypes)
    }

    private func assertLabelLarderFridgeEvents(_ eventTypes: [String]) {
        XCTAssertTrue(eventTypes.contains("larder.used_for_prep"))
        XCTAssertTrue(eventTypes.contains("larder.use_blocked"))
        XCTAssertTrue(eventTypes.contains("fridge.temperature_recorded"))
        XCTAssertTrue(eventTypes.contains("fridge.temperature_skipped"))
        XCTAssertTrue(eventTypes.contains("fridge.inspection_completed"))
        XCTAssertTrue(eventTypes.contains("fridge.inspection_skipped"))
        XCTAssertEqual(eventTypes.count { $0 == "larder.use_blocked" }, 4)
        XCTAssertEqual(eventTypes.count { $0 == "fridge.temperature_recorded" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "fridge.inspection_completed" }, 1)
    }

    private func assertLabelLarderFridgeStateRestores(database: PrepFlowDatabase) throws {
        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.latestPrepLabel?.id, "label-instance-task-nikiri")
        XCTAssertEqual(restoredStore.latestPrepLabel?.status, .remaining)
        XCTAssertEqual(restoredStore.larderItems.first?.status, .expired)
        XCTAssertEqual(restoredStore.larderItems.first?.qty, 0)
        XCTAssertEqual(restoredStore.fridgeTemperatureC, 3)
        XCTAssertEqual(restoredStore.fridgeTemperatureLoggedAt, "2026-06-12T15:50:00Z")
        XCTAssertEqual(restoredStore.fridgeInspectionCompletedAt, "2026-06-14T10:10:00Z")
        XCTAssertEqual(restoredStore.fridgeInspectionMissingCount, 1)

        let duplicateUse = restoredStore.applyPlannedLarderUse(requiredQty: 60, nowDate: "2026-06-12")
        XCTAssertEqual(duplicateUse.plannedQty, 0)
        XCTAssertEqual(restoredStore.latestLarderUseSummary, "FIFO使用済み / 再適用なし")
        XCTAssertEqual(try database.rows(named: "larder_item", tenantID: "tenant-local").count, 1)
    }

    func testFridgeTemperatureRejectsInvalidInputsBeforePersistence() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.recordFridgeTemperature(valueC: 99, loggedAt: "2026-06-12T15:50:00Z")
        store.recordFridgeTemperature(valueC: -99, loggedAt: "2026-06-12T15:51:00Z")
        store.recordFridgeTemperature(valueC: 3, storageUnitID: "", loggedAt: "2026-06-12T15:52:00Z")
        store.recordFridgeTemperature(valueC: 3, loggedAt: "")

        XCTAssertTrue(try database.rows(named: "temp_log", tenantID: "tenant-local").isEmpty)
        XCTAssertNil(store.fridgeTemperatureLoggedAt)
        XCTAssertEqual(store.fridgeTemperatureC, 3)

        store.recordFridgeTemperature(valueC: 12, loggedAt: "2026-06-12T15:53:00Z")

        let temperature = try XCTUnwrap(try database.rows(named: "temp_log", tenantID: "tenant-local").first)
        XCTAssertEqual(temperature.values["value"], "12")
        XCTAssertEqual(store.fridgeTemperatureC, 12)
        XCTAssertEqual(store.fridgeTemperatureLoggedAt, "2026-06-12T15:53:00Z")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count { $0 == "fridge.temperature_blocked" }, 4)
        XCTAssertEqual(eventTypes.count { $0 == "fridge.temperature_recorded" }, 1)
    }

    func testLabelIssueRequiresCompletedPrepAndDoesNotBatchComplete() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        let requestedLabel = store.issueNikiriPrepLabel(madeQty: 180)
        XCTAssertEqual(requestedLabel.id, "label-instance-task-nikiri")
        XCTAssertNil(store.latestPrepLabel)
        XCTAssertEqual(store.todayPrepStartedAt["tare"], "17:25")
        XCTAssertFalse(store.completed.contains("tare"))
        XCTAssertFalse(store.completed.contains("nikiri"))
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("ラベル発行不可"))
        XCTAssertTrue(try database.rows(named: "label", tenantID: "tenant-local").isEmpty)
        XCTAssertTrue(try database.rows(named: "larder_item", tenantID: "tenant-local").isEmpty)

        let blockedScan = store.scanLatestLabelRemaining(qty: 50)
        XCTAssertNil(blockedScan.larderItem)
        XCTAssertNil(blockedScan.wasteRecord)
        XCTAssertTrue(try database.rows(named: "label", tenantID: "tenant-local").isEmpty)

        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:42")
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:51")

        let blockedReadyScan = store.scanLatestLabelRemaining(qty: 50)
        XCTAssertNil(blockedReadyScan.larderItem)
        XCTAssertNil(blockedReadyScan.wasteRecord)
        XCTAssertNil(store.latestPrepLabel)
        XCTAssertEqual(store.labelScanLastAction, "QR記録不可: ラベル未発行")
        XCTAssertTrue(try database.rows(named: "label", tenantID: "tenant-local").isEmpty)

        let issued = store.issueNikiriPrepLabel(madeQty: 180)
        XCTAssertEqual(store.latestPrepLabel?.id, issued.id)
        XCTAssertFalse(try database.rows(named: "label", tenantID: "tenant-local").isEmpty)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("label.issue_blocked"))
        XCTAssertTrue(eventTypes.contains("label.scan_blocked"))
        XCTAssertTrue(eventTypes.contains("label.printed"))
    }

    func testLabelMissingOutputActionsAreIdempotent() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        let blockedPrint = store.testLabelPrint(now: "2026-06-12T16:22:00Z")
        let duplicateBlockedPrint = store.testLabelPrint(now: "2026-06-12T16:22:00Z")
        XCTAssertEqual(blockedPrint, duplicateBlockedPrint)
        XCTAssertEqual(blockedPrint.status, "blocked")
        XCTAssertEqual(blockedPrint.destination, "ラベル未発行")

        let blockedPDF = store.exportLatestLabelPDF(now: "2026-06-12T16:24:00Z")
        let duplicateBlockedPDF = store.exportLatestLabelPDF(now: "2026-06-12T16:24:00Z")
        XCTAssertEqual(blockedPDF, duplicateBlockedPDF)
        XCTAssertEqual(blockedPDF.status, "blocked")
        XCTAssertNil(blockedPDF.outputPath)

        let blockedQR = store.openLatestLabelQR()
        let duplicateBlockedQR = store.openLatestLabelQR()
        XCTAssertEqual(blockedQR, "ラベル未発行 → 仕込み完了後にQR")
        XCTAssertEqual(duplicateBlockedQR, blockedQR)
        XCTAssertNil(store.latestPrepLabel)
        XCTAssertTrue(try database.rows(named: "label", tenantID: "tenant-local").isEmpty)

        let blockedScan = store.scanLatestLabelRemaining(qty: 50)
        let duplicateBlockedScan = store.scanLatestLabelRemaining(qty: 50)
        XCTAssertEqual(blockedScan, duplicateBlockedScan)
        XCTAssertNil(blockedScan.larderItem)
        XCTAssertNil(blockedScan.wasteRecord)
        XCTAssertEqual(store.labelScanLastAction, "QR記録不可: ラベル未発行")

        try assertLabelMissingOutputIdempotencyEvents(database)
    }

    func testP25LabelPrinterPDFAndQRRoutePersistLocalModeSettings() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let storage = try XCTUnwrap(try database.rows(named: "storage_unit", tenantID: "tenant-local").first { $0.id == "storage-cold-2" })
        XCTAssertEqual(storage.values["qr_token"], "prepflow://storage/storage-cold-2")
        XCTAssertEqual(storage.values["temp_max"], "4")

        let printers = try database.rows(named: "printer", tenantID: "tenant-local")
        XCTAssertEqual(printers.count, 3)
        XCTAssertTrue(printers.contains { $0.id == "printer-brother-ql" && $0.values["is_default"] == "1" })

        store.markAllNowDone()
        let label = store.issueNikiriPrepLabel(madeQty: 120)
        XCTAssertEqual(store.latestLabelPrintJob?.labelID, label.id)
        XCTAssertEqual(store.latestLabelPrintJob?.destination, "Brother QL-820NWB")
        XCTAssertEqual(store.latestLabelPrintJob?.status, "queued")

        store.selectLabelPrinter("printer-pdf-a4")
        store.selectLabelPrinter("printer-pdf-a4")
        store.selectLabelPrinter("printer-missing")
        XCTAssertEqual(store.selectedLabelPrinterID, "printer-pdf-a4")
        store.selectLabelPaperSize("PDF / A4")
        store.selectLabelPaperSize("PDF / A4")
        let pdfJob = store.exportLatestLabelPDF()
        let duplicatePDFJob = store.exportLatestLabelPDF()
        XCTAssertEqual(pdfJob.status, "pdf_ready")
        XCTAssertEqual(pdfJob.outputPath, "/tmp/prepflow-label-instance-task-nikiri-labels.pdf")
        XCTAssertEqual(duplicatePDFJob, pdfJob)
        XCTAssertEqual(store.latestLabelPDFPath, pdfJob.outputPath)

        let testJob = store.testLabelPrint()
        let duplicateTestJob = store.testLabelPrint()
        XCTAssertEqual(testJob.destination, "PDF / A4")
        XCTAssertEqual(testJob.status, "pdf_ready")
        XCTAssertEqual(duplicateTestJob, testJob)

        let route = store.openLatestLabelQR()
        let duplicateRoute = store.openLatestLabelQR()
        XCTAssertEqual(route, "QR → label-instance-task-nikiri → 残量/使い切り/廃棄")
        XCTAssertEqual(duplicateRoute, route)

        let pdfPrinter = try XCTUnwrap(try database.rows(named: "printer", tenantID: "tenant-local").first { $0.id == "printer-pdf-a4" })
        XCTAssertEqual(pdfPrinter.values["is_default"], "1")
        XCTAssertEqual(pdfPrinter.values["last_tested_at"], "2026-06-12T16:22:00Z")
        store.toggleLabelMode()
        let restoredStore = BoardStore(database: database)
        XCTAssertFalse(restoredStore.labelModeEnabled)
        XCTAssertEqual(restoredStore.selectedLabelPrinterID, "printer-pdf-a4")
        XCTAssertEqual(restoredStore.labelPaperSize, "PDF / A4")
        let restoredPDFPrinter = try XCTUnwrap(try database.rows(named: "printer", tenantID: "tenant-local").first { $0.id == "printer-pdf-a4" })
        XCTAssertEqual(restoredPDFPrinter.values["last_tested_at"], "2026-06-12T16:22:00Z")

        try assertLabelOutputIdempotencyEvents(database)
    }

    func testP3ConnectorReservationReplayPersistsSourceEventAndPrepImpact() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let addEvent = p3ConnectorAddEvent()
        let added = store.replayConnectorReservation(addEvent)

        XCTAssertEqual(added.addedCovers, 3)
        XCTAssertEqual(added.cancelledCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 17)
        XCTAssertEqual(Int(store.reservationPlanDiff?.added.first?.qty ?? 0), 42)

        assertConnectorReplayIsSkipped(store, event: addEvent, expectedCovers: 17)

        let connector = try XCTUnwrap(try database.rows(named: "connector_account", tenantID: "tenant-local").first { $0.id == "connector-tablecheck-mock" })
        XCTAssertEqual(connector.values["provider"], "tablecheck")
        XCTAssertEqual(connector.values["status"], "mock")

        let sourceEvent = try XCTUnwrap(try database.rows(named: "source_event", tenantID: "tenant-local").first { $0.id == "source-tablecheck-r100" })
        XCTAssertEqual(sourceEvent.values["type"], "reservation.upserted")
        XCTAssertEqual(sourceEvent.values["processed_at"], "2026-06-17T09:00:01Z")
        XCTAssertTrue(sourceEvent.values["payload"]?.contains("\"reservation_id\":\"reservation-tablecheck-r100\"") == true)

        let reservation = try XCTUnwrap(try database.rows(.reservation, tenantID: "tenant-local").first { $0.id == "reservation-tablecheck-r100" })
        XCTAssertEqual(reservation.values["source"], "api")
        XCTAssertEqual(reservation.values["covers"], "3")
        XCTAssertEqual(reservation.values["dup_group"], "r100")

        let cancelEvent = p3ConnectorCancelEvent()
        let cancelled = store.replayConnectorReservation(cancelEvent)

        XCTAssertEqual(cancelled.addedCovers, 0)
        XCTAssertEqual(cancelled.cancelledCovers, 3)
        XCTAssertEqual(store.service.omakaseCovers, 14)
        XCTAssertEqual(Int(store.reservationPlanDiff?.reduced.first?.newTotal ?? 0), 200)

        assertConnectorReplayIsSkipped(store, event: cancelEvent, expectedCovers: 14)

        let activeReservations = try database.rows(.reservation, tenantID: "tenant-local")
        XCTAssertFalse(activeReservations.contains { $0.id == "reservation-tablecheck-r100" })

        let events = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        XCTAssertTrue(events.contains("connector.reservation_applied"))
        XCTAssertEqual(events.count(where: { $0 == "connector.reservation_applied" }), 2)
        XCTAssertEqual(events.count(where: { $0 == "connector.reservation_replay_skipped" }), 2)
        XCTAssertEqual(events.count(where: { $0 == "reservation.diffed" }), 2)
    }

    func testConnectorReservationRejectsInvalidEventsBeforePersistence() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let invalidAdd = SourceReservationEvent(
            id: "source-tablecheck-invalid-covers",
            provider: .tablecheck,
            externalID: "invalid-covers",
            visitTime: "18:30",
            covers: 0,
            course: "course-omakase",
            partyName: "Invalid Covers"
        )
        let replayed = store.replayConnectorReservation(invalidAdd)
        XCTAssertEqual(replayed.addedCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 14)

        let invalidMissingID = SourceReservationEvent(
            id: "",
            provider: .tablecheck,
            externalID: "invalid-empty-id",
            visitTime: "19:00",
            covers: 2,
            course: "course-omakase",
            partyName: "Invalid Empty ID"
        )
        let queued = store.queueConnectorReservationDiffs([invalidMissingID])
        XCTAssertTrue(queued.isEmpty)
        XCTAssertTrue(store.connectorLastSyncSummary.contains("承認待ち 0件"))

        XCTAssertTrue(try database.rows(named: "source_event", tenantID: "tenant-local").isEmpty)
        XCTAssertFalse(try database.rows(.reservation, tenantID: "tenant-local").contains { $0.id.contains("invalid") })

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "connector.reservation_blocked" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "connector.reservation_applied" }), 0)
        XCTAssertEqual(eventTypes.count(where: { $0 == "connector.sync_replayed" }), 1)
    }

    func testConnectorDiffReviewRestoresPendingQueueBeforeDecision() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        _ = store.queueConnectorReservationDiffs()

        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.connectorDiffReviewItems.count, 2)
        XCTAssertEqual(restoredStore.connectorDiffReviewItems.count { $0.state == "未処理" }, 2)
        XCTAssertTrue(restoredStore.connectorLastSyncSummary.contains("承認待ち 2件"))
        XCTAssertEqual(restoredStore.connectorDiffReviewItems.first { $0.id == "source-tablecheck-kimura-2030-review" }?.partyName, "木村 様")
        XCTAssertEqual(
            restoredStore.connectorDiffReviewItems.first { $0.id == "source-tablecheck-kimura-2030-review" }?.prepNote,
            "貝類NG / 記念日 / 日本酒好き / VIP:gold"
        )

        let accepted = restoredStore.acceptConnectorDiff("source-tablecheck-kimura-2030-review")
        XCTAssertEqual(accepted.addedCovers, 2)
        XCTAssertEqual(restoredStore.service.omakaseCovers, 16)
        XCTAssertEqual(restoredStore.connectorDiffReviewItems.first { $0.id == "source-tablecheck-kimura-2030-review" }?.state, "承認済み")

        restoredStore.rejectConnectorDiff("source-tablecheck-suzuki-1800-review")
        XCTAssertEqual(restoredStore.connectorDiffReviewItems.first { $0.id == "source-tablecheck-suzuki-1800-review" }?.state, "却下")

        let finalRestoredStore = BoardStore(database: database)
        XCTAssertEqual(finalRestoredStore.connectorDiffReviewItems.count { $0.state == "未処理" }, 0)
        XCTAssertEqual(finalRestoredStore.connectorDiffReviewItems.first { $0.id == "source-tablecheck-kimura-2030-review" }?.state, "承認済み")
        XCTAssertEqual(finalRestoredStore.connectorDiffReviewItems.first { $0.id == "source-tablecheck-suzuki-1800-review" }?.state, "却下")
        XCTAssertEqual(finalRestoredStore.latestConnectorReservation?.id, "reservation-tablecheck-kimura-2030")
    }

    func testP3ConnectorDiffReviewQueuesAcceptsAndRejectsExternalChanges() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let queued = store.queueConnectorReservationDiffs()

        XCTAssertEqual(queued.count, 2)
        XCTAssertEqual(store.connectorDiffReviewItems.count { $0.state == "未処理" }, 2)
        XCTAssertEqual(store.service.omakaseCovers, 14)
        XCTAssertTrue(store.connectorLastSyncSummary.contains("承認待ち 2件"))

        let pendingEvent = try XCTUnwrap(
            try database.rows(named: "source_event", tenantID: "tenant-local")
                .first { $0.id == "source-tablecheck-suzuki-1800-review" }
        )
        XCTAssertEqual(pendingEvent.values["processed_at"], "NULL")
        XCTAssertTrue(pendingEvent.values["payload"]?.contains("\"review_state\":\"pending\"") == true)

        store.rejectConnectorDiff("source-tablecheck-suzuki-1800-review")

        XCTAssertEqual(store.connectorDiffReviewItems.first { $0.id == "source-tablecheck-suzuki-1800-review" }?.state, "却下")
        XCTAssertFalse(store.service.reservations.contains { $0.id == "reservation-tablecheck-suzuki-1800" })

        let accepted = store.acceptConnectorDiff("source-tablecheck-kimura-2030-review")

        XCTAssertEqual(accepted.addedCovers, 2)
        XCTAssertEqual(store.service.omakaseCovers, 16)
        XCTAssertEqual(store.connectorDiffReviewItems.first { $0.id == "source-tablecheck-kimura-2030-review" }?.state, "承認済み")
        XCTAssertEqual(Int(store.reservationPlanDiff?.added.first?.qty ?? 0), 28)
        XCTAssertEqual(store.specialPrepTasks.count, 2)
        XCTAssertEqual(store.allergenLabels.count, 1)
        XCTAssertEqual(store.guestMessages.count, 1)
        XCTAssertEqual(store.passSeatFlags.first?.seatRef, "卓5")

        assertConnectorDuplicateReviewIsNoop(store)

        store.sendGuestConfirmationMessages()
        store.sendGuestConfirmationMessages()
        store.printAllergenLabels()
        store.printAllergenLabels()
        XCTAssertEqual(store.allergenLabelPrintCount, 1)
        XCTAssertEqual(store.specialPrepLastAction, "席札印刷済み / 再印刷なし")
        store.recordGuestMessageReply(reservationID: "reservation-tablecheck-kimura-2030", changed: true)
        store.recordGuestMessageReply(reservationID: "reservation-tablecheck-kimura-2030", changed: true)
        XCTAssertEqual(store.guestReplyRecheckCount, 1)
        XCTAssertTrue(store.guestReplyRequiresLabelReprint)
        XCTAssertTrue(store.passSeatFlags.contains { $0.kind == .special && $0.displayText.contains("返信変更") })

        try assertSpecialPrepCompleteSkipIdempotency(store)
        store.completeGuestReplyRecheck("reservation-tablecheck-kimura-2030")

        XCTAssertEqual(store.allergenLabelPrintCount, 1)
        XCTAssertEqual(store.guestReplyRecheckCount, 0)
        try assertConnectorReviewOmotenashiPersistence(database)
        try assertCompletedOmotenashiStateRestores(database)
    }

    func testP35DirectBookingPersistsCheckoutReservationAndPrepImpact() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let added = store.acceptDirectBooking(DirectBooking(
            id: "direct-b200",
            visitTime: "20:00",
            covers: 2,
            course: "course-omakase",
            guestName: "Direct Guest",
            guestNote: "English menu"
        ))

        XCTAssertEqual(added.addedCovers, 2)
        XCTAssertEqual(added.cancelledCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 16)
        XCTAssertEqual(Int(store.reservationPlanDiff?.added.first?.qty ?? 0), 28)
        XCTAssertEqual(store.latestDirectBooking?.status, .confirmed)
        XCTAssertEqual(store.latestDirectBooking?.stripeCheckoutID, "stripe-direct-b200")

        let duplicateAccept = store.acceptDirectBooking(DirectBooking(
            id: "direct-b200",
            visitTime: "20:00",
            covers: 2,
            course: "course-omakase",
            guestName: "Direct Guest",
            guestNote: "English menu"
        ))
        XCTAssertEqual(duplicateAccept.addedCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 16)

        try assertConfirmedDirectReevaluationIsStable(store: store, database: database)

        let cancelled = store.cancelDirectBooking("direct-b200")

        XCTAssertEqual(cancelled.addedCovers, 0)
        XCTAssertEqual(cancelled.cancelledCovers, 2)
        XCTAssertEqual(store.service.omakaseCovers, 14)
        XCTAssertEqual(Int(store.reservationPlanDiff?.reduced.first?.newTotal ?? 0), 200)

        let duplicateCancel = store.cancelDirectBooking("direct-b200")
        XCTAssertEqual(duplicateCancel.cancelledCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 14)

        let cancelledDirect = try XCTUnwrap(try database.rows(named: "direct_booking", tenantID: "tenant-local").first { $0.id == "direct-b200" })
        XCTAssertEqual(cancelledDirect.values["status"], "cancelled")
        let activeReservations = try database.rows(.reservation, tenantID: "tenant-local")
        XCTAssertFalse(activeReservations.contains { $0.id == "reservation-direct-direct-b200" })
        try assertDirectAcceptCancelStateRestores(database)

        let events = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        assertDirectAcceptCancelEvents(events)
    }

    func testDirectBookingRejectsInvalidCoversBeforePersistence() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let zeroDiff = store.acceptDirectBooking(DirectBooking(
            id: "direct-invalid-zero",
            visitTime: "20:00",
            covers: 0,
            course: "course-omakase",
            guestName: "Invalid Zero"
        ))
        XCTAssertEqual(zeroDiff.addedCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 14)

        let decision = store.evaluateDirectAllotment(DirectBooking(
            id: "direct-invalid-negative",
            visitTime: "20:30",
            covers: -2,
            course: "course-omakase",
            guestName: "Invalid Negative"
        ), allottedCovers: 4)
        XCTAssertEqual(decision.reason, "invalid_covers")
        XCTAssertEqual(decision.confirmedCovers, 0)
        XCTAssertEqual(decision.waitlistCovers, 0)

        try assertInvalidDirectCoversWereBlocked(database)
    }

    func testDirectWaitlistPromotionRejectsInvalidInputsBeforePersistence() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let invalidCovers = store.promoteWaitlistedDirectBooking(DirectBooking(
            id: "direct-invalid-promotion-covers",
            visitTime: "20:00",
            covers: 0,
            course: "course-omakase",
            guestName: "Invalid Promotion Covers"
        ), allottedCovers: 4)
        XCTAssertEqual(invalidCovers.status, .request)
        XCTAssertEqual(invalidCovers.promotedCovers, 0)
        XCTAssertEqual(invalidCovers.reason, "invalid_covers")

        let invalidAllotment = store.promoteWaitlistedDirectBooking(DirectBooking(
            id: "direct-invalid-promotion-allotment",
            visitTime: "20:15",
            covers: 2,
            course: "course-omakase",
            guestName: "Invalid Promotion Allotment"
        ), allottedCovers: -1)
        XCTAssertEqual(invalidAllotment.status, .request)
        XCTAssertEqual(invalidAllotment.promotedCovers, 0)
        XCTAssertEqual(invalidAllotment.reason, "invalid_allotment")

        XCTAssertFalse(try database.rows(named: "direct_booking", tenantID: "tenant-local").contains { $0.id.hasPrefix("direct-invalid-promotion-") })
        XCTAssertFalse(try database.rows(named: "waitlist_entry", tenantID: "tenant-local").contains { $0.values["booking_id"]?.hasPrefix("direct-invalid-promotion-") == true })
        XCTAssertFalse(try database.rows(.reservation, tenantID: "tenant-local").contains { $0.id.hasPrefix("reservation-direct-direct-invalid-promotion-") })

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "direct_waitlist.promotion_blocked" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "direct_waitlist.promoted" }), 0)
    }

    func testP4ServiceSyncPersistsEventsRemainingAndPacing() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let state = store.replayServiceSyncEvents(p4ServiceSyncEvents(), elapsedMinutes: 60, serviceMinutes: 120)

        XCTAssertEqual(state.firedCovers, 6)
        XCTAssertEqual(state.heldCovers, 2)
        XCTAssertEqual(state.servedCovers, 7)
        XCTAssertEqual(state.remainingCovers, 7)
        XCTAssertEqual(state.pendingOfflineEvents, 1)
        XCTAssertEqual(store.servicePacingProposal?.recommendation, "keep")

        let serviceEvents = try database.rows(named: "service_event", tenantID: "tenant-local")
        XCTAssertEqual(serviceEvents.count, 4)
        let offline = try XCTUnwrap(serviceEvents.first { $0.id == "service-event-served-offline" })
        XCTAssertEqual(offline.values["source"], "pos")
        XCTAssertEqual(offline.values["type"], "served")
        XCTAssertTrue(offline.values["payload"]?.contains("\"offline_sequence\":\"1\"") == true)

        let synced = store.replayServiceSyncEvent(
            ServiceSyncEvent(
                id: "service-event-remaining-sync",
                source: .pos,
                kind: .remainingSync,
                covers: 5,
                occurredAt: "2026-06-17T10:30:00Z"
            ),
            elapsedMinutes: 90,
            serviceMinutes: 120
        )
        XCTAssertEqual(synced.remainingCovers, 5)
        XCTAssertEqual(store.serviceSyncState?.remainingCovers, 5)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_sync.replayed" }), 5)
    }

    func testDirectNoShowRemovesReservationAndReturnsToCarryoverCheck() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)
        let booking = p35InboundDirectBooking()

        _ = store.acceptDirectBooking(booking)
        let acceptImpactID = try XCTUnwrap(store.todayPrepImpactItems.first?.id)
        store.applyTodayPrepImpact(acceptImpactID)
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:42")
        store.markAllNowDone()

        let settlement = store.recordDirectNoShow(booking, forfeitsDeposit: true)

        XCTAssertEqual(settlement.status, .noshow)
        XCTAssertEqual(settlement.prepImpactCovers, 4)
        XCTAssertEqual(store.service.omakaseCovers, 14)
        XCTAssertFalse(store.service.reservations.contains { $0.id == "reservation-direct-\(booking.id)" })
        XCTAssertEqual(store.todayPrepImpactItems.first?.sourceLabel, "Direct no-show")
        XCTAssertEqual(store.todayPrepImpactItems.count, 1)
        XCTAssertFalse(store.lineGateStatus.canOpen)

        _ = store.issueNikiriPrepLabel(printedAt: "2026-06-17T16:20:00Z")
        XCTAssertNil(store.latestPrepLabel)

        let duplicateNoShow = store.recordDirectNoShow(booking, forfeitsDeposit: true)
        XCTAssertEqual(duplicateNoShow.status, .noshow)
        XCTAssertEqual(duplicateNoShow.prepImpactCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 14)
        XCTAssertEqual(store.todayPrepImpactItems.count, 1)

        let direct = try XCTUnwrap(try database.rows(named: "direct_booking", tenantID: "tenant-local").first { $0.id == booking.id })
        XCTAssertEqual(direct.values["status"], "noshow")
        let reservations = try database.rows(.reservation, tenantID: "tenant-local")
        XCTAssertFalse(reservations.contains { $0.id == "reservation-direct-\(booking.id)" })

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("direct_booking.noshow_recorded"))
        XCTAssertTrue(eventTypes.contains("direct_booking.noshow_blocked"))
        XCTAssertTrue(eventTypes.contains("reservation.diffed"))
        XCTAssertTrue(eventTypes.contains("today_prep.impact_queued"))
        XCTAssertTrue(eventTypes.contains("label.issue_blocked"))
    }

    func testForwardSliceCompletionPersistsDirectSignalsPassAndMultistore() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)
        let booking = p35InboundDirectBooking()

        let decision = store.evaluateDirectAllotment(booking, allottedCovers: 1)
        XCTAssertEqual(decision.status, .request)
        XCTAssertEqual(decision.waitlistCovers, 4)
        let waitlist = try XCTUnwrap(try database.rows(named: "waitlist_entry", tenantID: "tenant-local").first { $0.id == "waitlist-direct-b300" })
        XCTAssertEqual(waitlist.values["status"], "waiting")
        let duplicateDecision = store.evaluateDirectAllotment(booking, allottedCovers: 1)
        XCTAssertEqual(duplicateDecision.status, .request)
        XCTAssertEqual(duplicateDecision.reason, "waitlist_registered")
        XCTAssertEqual(try database.rows(named: "waitlist_entry", tenantID: "tenant-local").count { $0.id == "waitlist-direct-b300" }, 1)
        XCTAssertEqual(try database.rows(named: "direct_booking", tenantID: "tenant-local").count { $0.id == booking.id }, 1)

        let settlement = store.recordDirectNoShow(booking, forfeitsDeposit: true)
        XCTAssertEqual(settlement.status, .request)
        XCTAssertEqual(settlement.prepImpactCovers, 0)
        XCTAssertEqual(try database.rows(named: "direct_booking", tenantID: "tenant-local").first { $0.id == booking.id }?.values["status"], "request")

        let signals = store.replayGuestSignals(p3VIPReservation(), seatRef: "卓3", language: "en")
        XCTAssertEqual(signals.count, 3)
        XCTAssertEqual(try database.rows(named: "special_prep", tenantID: "tenant-local").count, 2)
        XCTAssertEqual(try database.rows(named: "allergen_label", tenantID: "tenant-local").first?.values["language"], "en")
        XCTAssertEqual(try database.rows(named: "guest_message", tenantID: "tenant-local").first?.values["language"], "en")

        let state = store.replayServiceSyncEvents(p4ServiceSyncEvents(), elapsedMinutes: 60, serviceMinutes: 120)
        XCTAssertEqual(state.firedCovers, 6)
        XCTAssertEqual(store.passState?.seatFlags.count, 1)
        XCTAssertEqual(try database.rows(named: "pass_seat_flag", tenantID: "tenant-local").first?.values["seat_ref"], "卓3")
        XCTAssertEqual(store.storeSummaries.first?.remainingCovers, 7)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("direct_booking.evaluated"))
        XCTAssertTrue(eventTypes.contains("direct_booking.evaluate_skipped"))
        XCTAssertEqual(eventTypes.count { $0 == "direct_booking.evaluated" }, 1)
    }

    func testServicePassOperationsUpdateRemainingPacingAndOfflineFlush() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let fired = store.acceptIncomingServiceFire()
        XCTAssertEqual(fired.firedCovers, 4)
        XCTAssertEqual(store.passState?.firedCovers, 4)
        XCTAssertEqual(store.servicePassLastAction, "卓3 握り FIRE を厨房へ反映")
        let duplicateFire = store.acceptIncomingServiceFire()
        XCTAssertEqual(duplicateFire.firedCovers, 4)
        XCTAssertEqual(store.servicePassLastAction, "卓3 握り FIRE は反映済み")

        let held = store.holdIncomingServiceFire()
        XCTAssertEqual(held.heldCovers, 4)
        XCTAssertEqual(store.serviceSyncEventTimeline.last?.kind, .hold)
        let duplicateHold = store.holdIncomingServiceFire()
        XCTAssertEqual(duplicateHold.heldCovers, 4)
        XCTAssertEqual(store.servicePassLastAction, "卓3 握り HOLD は反映済み")

        let served = store.markServiceCourseServed()
        XCTAssertEqual(served.servedCovers, 4)
        XCTAssertEqual(served.remainingCovers, store.service.omakaseCovers - 4)
        XCTAssertEqual(store.servicePassLastAction, "卓3 握りを提供済みに更新")

        let duplicateServed = store.markServiceCourseServed()
        XCTAssertEqual(duplicateServed.servedCovers, 4)
        XCTAssertEqual(duplicateServed.remainingCovers, served.remainingCovers)
        XCTAssertEqual(store.servicePassLastAction, "卓3 握り提供は反映済み")

        let offline = store.queueOfflineServiceServed()
        XCTAssertEqual(offline.pendingOfflineEvents, 1)
        XCTAssertEqual(store.servicePassPendingOfflineCount, 1)
        XCTAssertEqual(store.serviceSyncEventTimeline.last?.offlineSequence, 1)

        let duplicateOffline = store.queueOfflineServiceServed()
        XCTAssertEqual(duplicateOffline.pendingOfflineEvents, 1)
        XCTAssertEqual(store.servicePassPendingOfflineCount, 1)
        XCTAssertEqual(store.servicePassLastAction, "卓1 握りはオフライン保存済み")

        let flushed = store.flushOfflineServiceEvents()
        XCTAssertEqual(flushed.pendingOfflineEvents, 0)
        XCTAssertEqual(store.servicePassPendingOfflineCount, 0)
        XCTAssertEqual(store.servicePassLastAction, "未送信 1件を再同期")

        let replayedCountAfterFlush = try database.rows(.eventLog, tenantID: "tenant-local")
            .count { $0.values["type"] == "service_sync.replayed" }
        let emptyFlush = store.flushOfflineServiceEvents()
        XCTAssertEqual(emptyFlush.pendingOfflineEvents, 0)
        XCTAssertEqual(store.servicePassPendingOfflineCount, 0)
        XCTAssertEqual(store.servicePassLastAction, "未送信なし")

        let serviceEvents = try database.rows(named: "service_event", tenantID: "tenant-local")
        XCTAssertEqual(serviceEvents.count, 4)
        XCTAssertFalse(serviceEvents.contains { ($0.values["payload"] ?? "").contains("\"offline_sequence\":\"1\"") })
        try assertServicePassStateRestores(database)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        assertServicePassIdempotencyEvents(eventTypes, replayedCountAfterFlush: replayedCountAfterFlush)
    }

    func testServiceSyncSingleReplayIgnoresDuplicateAndBlocksConflictRewrite() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)
        let event = ServiceSyncEvent(
            id: "service-event-single-dedupe",
            source: .kds,
            kind: .served,
            covers: 4,
            reservationID: "reservation-sato",
            occurredAt: "2026-06-17T19:10:00Z"
        )

        let initial = store.replayServiceSyncEvent(event, elapsedMinutes: 80)
        let duplicate = store.replayServiceSyncEvent(event, elapsedMinutes: 80)
        let conflict = store.replayServiceSyncEvent(ServiceSyncEvent(
            id: event.id,
            source: .pos,
            kind: .served,
            covers: 9,
            reservationID: "reservation-sato",
            occurredAt: "2026-06-17T19:10:05Z"
        ), elapsedMinutes: 80)

        XCTAssertEqual(initial.servedCovers, 4)
        XCTAssertEqual(duplicate.servedCovers, 4)
        XCTAssertEqual(conflict.servedCovers, 4)
        XCTAssertEqual(store.serviceSyncEventTimeline.count, 1)
        XCTAssertEqual(store.serviceSyncEventTimeline.first?.covers, 4)

        let serviceEvent = try XCTUnwrap(try database.rows(named: "service_event", tenantID: "tenant-local").first { $0.id == event.id })
        XCTAssertEqual(serviceEvent.values["source"], "kds")
        XCTAssertTrue(serviceEvent.values["payload"]?.contains("\"covers\":4") == true)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_sync.replayed" }), 1)
        XCTAssertTrue(eventTypes.contains("service_sync.duplicate_ignored"))
        XCTAssertTrue(eventTypes.contains("service_sync.conflict_blocked"))
    }

    func testServiceSyncRejectsInvalidEventsBeforePersistence() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let initial = store.replayServiceSyncEvent(ServiceSyncEvent(
            id: "service-event-valid-zero-remaining",
            source: .pos,
            kind: .remainingSync,
            covers: 0,
            occurredAt: "2026-06-17T19:20:00Z"
        ), elapsedMinutes: 90)
        XCTAssertEqual(initial.remainingCovers, 0)

        _ = store.replayServiceSyncEvent(ServiceSyncEvent(
            id: "",
            source: .kds,
            kind: .served,
            covers: 1,
            occurredAt: "2026-06-17T19:21:00Z"
        ), elapsedMinutes: 90)
        _ = store.replayServiceSyncEvent(ServiceSyncEvent(
            id: "service-event-invalid-negative-covers",
            source: .kds,
            kind: .served,
            covers: -2,
            occurredAt: "2026-06-17T19:22:00Z"
        ), elapsedMinutes: 90)
        _ = store.replayServiceSyncEvent(ServiceSyncEvent(
            id: "service-event-invalid-empty-time",
            source: .kds,
            kind: .fire,
            covers: 2,
            occurredAt: ""
        ), elapsedMinutes: 90)
        _ = store.replayServiceSyncEvent(ServiceSyncEvent(
            id: "service-event-invalid-offline-sequence",
            source: .manual,
            kind: .served,
            covers: 2,
            occurredAt: "2026-06-17T19:23:00Z",
            offlineSequence: 0
        ), elapsedMinutes: 90)

        XCTAssertEqual(store.serviceSyncEventTimeline.map(\.id), ["service-event-valid-zero-remaining"])
        let serviceEvents = try database.rows(named: "service_event", tenantID: "tenant-local")
        XCTAssertEqual(serviceEvents.count, 1)
        XCTAssertEqual(serviceEvents.first?.id, "service-event-valid-zero-remaining")
        XCTAssertTrue(serviceEvents.first?.values["payload"]?.contains("\"covers\":0") == true)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_sync.replayed" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_sync.event_blocked" }), 4)
    }

    func testServiceSyncBatchRejectsInvalidEventsBeforePersistence() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let replay = store.replayServiceSyncBatch([
            ServiceSyncEvent(
                id: "service-event-batch-valid",
                source: .kds,
                kind: .fire,
                covers: 3,
                reservationID: "reservation-sato",
                occurredAt: "2026-06-17T19:30:00Z"
            ),
            ServiceSyncEvent(
                id: "service-event-batch-invalid-covers",
                source: .kds,
                kind: .served,
                covers: -3,
                reservationID: "reservation-sato",
                occurredAt: "2026-06-17T19:31:00Z"
            ),
            ServiceSyncEvent(
                id: "",
                source: .pos,
                kind: .served,
                covers: 2,
                reservationID: "reservation-sato",
                occurredAt: "2026-06-17T19:32:00Z"
            ),
            ServiceSyncEvent(
                id: "service-event-batch-invalid-offline",
                source: .manual,
                kind: .served,
                covers: 2,
                reservationID: "reservation-sato",
                occurredAt: "2026-06-17T19:33:00Z",
                offlineSequence: -1
            ),
        ], elapsedMinutes: 95)

        XCTAssertEqual(replay.acceptedEventIDs, ["service-event-batch-valid"])
        XCTAssertEqual(store.serviceSyncEventTimeline.map(\.id), ["service-event-batch-valid"])
        XCTAssertEqual(try database.rows(named: "service_event", tenantID: "tenant-local").map(\.id), ["service-event-batch-valid"])

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_sync.batch_replayed" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_sync.event_blocked" }), 3)
    }

    func testThickenedSlicesPromoteWaitlistAlertFIFOAndDedupeServiceReplay() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)
        let booking = p35InboundDirectBooking()

        _ = store.evaluateDirectAllotment(booking, allottedCovers: 1)
        let promotion = store.promoteWaitlistedDirectBooking(booking, allottedCovers: 4)
        XCTAssertEqual(promotion.status, .confirmed)
        XCTAssertEqual(store.service.omakaseCovers, 18)
        XCTAssertEqual(try database.rows(named: "waitlist_entry", tenantID: "tenant-local").first?.values["status"], "confirmed")
        XCTAssertEqual(try database.rows(named: "direct_booking", tenantID: "tenant-local").first { $0.id == booking.id }?.values["status"], "confirmed")
        XCTAssertEqual(store.todayPrepImpactItems.first?.sourceLabel, "Direct待機")
        XCTAssertFalse(store.lineGateStatus.canOpen)

        let duplicatePromotion = store.promoteWaitlistedDirectBooking(booking, allottedCovers: 4)
        XCTAssertEqual(duplicatePromotion.status, .confirmed)
        XCTAssertEqual(duplicatePromotion.promotedCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 18)

        _ = store.issueNikiriPrepLabel(printedAt: "2026-06-10T16:20:00Z")
        XCTAssertNil(store.latestPrepLabel)
        let waitlistImpactID = try XCTUnwrap(store.todayPrepImpactItems.first?.id)
        store.applyTodayPrepImpact(waitlistImpactID)
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:36")

        store.markAllNowDone()
        _ = store.issueNikiriPrepLabel(printedAt: "2026-06-10T16:20:00Z")
        _ = store.scanLatestLabelRemaining(qty: 80)
        let alerts = store.refreshLarderFIFO(nowDate: "2026-06-12", alertWithinDays: 1)
        XCTAssertEqual(alerts.first?.level, "expired")
        XCTAssertEqual(alerts.first?.labelID, "label-instance-task-nikiri")

        try assertServiceBatchReplayIdempotency(store: store, database: database)

        let summary = store.summarizeMultistore(thickStoreSummaries())
        XCTAssertEqual(summary.remainingCovers, 12)
        XCTAssertEqual(summary.recommendation, "fire")
        try assertPromotedDirectAndServiceBatchStateRestores(database)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("direct_waitlist.promoted"))
        XCTAssertTrue(eventTypes.contains("direct_waitlist.promotion_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.impact_queued"))
        XCTAssertTrue(eventTypes.contains("label.issue_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.impact_applied"))
        XCTAssertTrue(eventTypes.contains("larder.fifo_refreshed"))
        XCTAssertTrue(eventTypes.contains("service_sync.batch_replayed"))
        XCTAssertTrue(eventTypes.contains("service_sync.batch_replay_skipped"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_sync.batch_replayed" }), 1)
        XCTAssertTrue(eventTypes.contains("multistore.summarized"))
    }

    func testThickenedOpsPlanMixedReservationLarderUseAndCloseBatch() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.markAllNowDone()
        let inbound = ManualReservation(
            id: "reservation-inbound-mixed",
            visitTime: "19:00",
            partyName: "追加 田中様",
            note: "混在差分",
            covers: 3
        )
        let diff = store.previewMixedReservationChange(cancelledID: "reservation-sato", addedReservation: inbound)

        try assertMixedReservation(diff: diff, inbound: inbound, store: store, database: database)
        XCTAssertEqual(Set(store.todayPrepImpactItems.map(\.sourceLabel)), ["予約差分"])
        XCTAssertEqual(store.todayPrepImpactItems.count, 2)
        XCTAssertFalse(store.lineGateStatus.canOpen)

        _ = store.issueNikiriPrepLabel(madeQty: 90, printedAt: "2026-06-12T16:20:00Z")
        XCTAssertNil(store.latestPrepLabel)
        for impact in store.todayPrepImpactItems.map(\.id) {
            store.applyTodayPrepImpact(impact)
        }
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:42")
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:51")

        _ = store.issueNikiriPrepLabel(madeQty: 90, printedAt: "2026-06-12T16:20:00Z")
        _ = store.scanLatestLabelRemaining(qty: 90)
        assertLarderUsePlan(store.planLarderUse(requiredQty: 120, nowDate: "2026-06-12"))
        try assertCloseBatch(store: store, database: database)
        assertCloseGate(store.completeCloseGate(), store: store)
        store.toggleCloseNextDayPrepReservation("nextday-akami-zuke")
        store.toggleCloseNextDayPrepReservation("nextday-missing")
        XCTAssertEqual(store.closeNextDayPrepReservations.count(where: { $0.isReserved }), 3)
        try assertCloseOpsStateRestores(database: database)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("reservation.diffed"))
        XCTAssertTrue(eventTypes.contains("reservation.carryover_candidate"))
        XCTAssertTrue(eventTypes.contains("larder.consumption_planned"))
        XCTAssertTrue(eventTypes.contains("close.batch_completed"))
        XCTAssertTrue(eventTypes.contains("close.batch_skipped"))
        XCTAssertTrue(eventTypes.contains("close.gate_completed"))
        XCTAssertTrue(eventTypes.contains("close.gate_skipped"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "close.batch_completed" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "close.gate_completed" }), 1)
        XCTAssertTrue(eventTypes.contains("close.nextday_prep_toggled"))
        XCTAssertTrue(eventTypes.contains("close.nextday_prep_toggle_blocked"))
    }

    func testTodayPrepOperationsTrackNextStepUndoGuidanceAndETA() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        XCTAssertEqual(store.todayPrepProgress.nextStepID, "tare")
        XCTAssertEqual(store.todayPrepProgress.remainingMinutes, 30)
        XCTAssertEqual(store.todayPrepProgress.eta.landing, "17:55")

        assertTodayPrepUndoPath(store)
        assertTodayPrepGuidanceQualityGate(store)
        store.markAllNowDone()
        XCTAssertTrue(store.todayPrepProgress.isComplete)
        XCTAssertEqual(store.todayPrepProgress.remainingMinutes, 0)
        store.startNextTodayStep(now: "18:05")
        store.completeNextTodayStep(now: "18:05")
        store.completeCurrentTodayPrepChecks()
        XCTAssertTrue(store.todayPrepProgress.isComplete)
        XCTAssertEqual(store.todayPrepProgress.remainingMinutes, 0)
        XCTAssertEqual(store.todayPrepCompletionBlockReason, "確認項目なし")

        try assertTodayPrepPersistence(store: store, database: database)
    }

    func testTodayPrepUndoSurvivesRelaunchAndStillRollsBackProgress() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.toggleTodayPrepStep("tare")
        XCTAssertEqual(store.todayPrepProgress.nextStepID, "rest")
        XCTAssertEqual(store.lastTodayPrepUndo?.previousCompletedIDs, ["sake"])
        XCTAssertEqual(store.lastTodayPrepUndo?.nextCompletedIDs, ["sake", "tare"])

        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.lastTodayPrepUndo?.previousCompletedIDs, ["sake"])
        XCTAssertEqual(restoredStore.lastTodayPrepUndo?.nextCompletedIDs, ["sake", "tare"])

        restoredStore.undoLastTodayPrepAction()
        XCTAssertEqual(restoredStore.todayPrepProgress.nextStepID, "tare")
        XCTAssertNil(restoredStore.todayPrepCompletionDisplay(for: "tare"))
        XCTAssertNil(restoredStore.lastTodayPrepUndo)
    }

    func testTodayPrepExternalImpactsReturnToGuidanceChecks() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        _ = store.acceptDirectBooking(DirectBooking(
            id: "direct-impact",
            visitTime: "18:30",
            covers: 2,
            course: "course-omakase",
            guestName: "Impact Guest"
        ))

        let reservationImpactID = try XCTUnwrap(store.todayPrepImpactItems.first?.id)
        XCTAssertEqual(store.todayPrepImpactItems.first?.sourceLabel, "Direct")
        try assertTodayPrepImpactQueueRestores(database, impactID: reservationImpactID, sourceLabel: "Direct")
        store.applyTodayPrepImpact(reservationImpactID)
        store.applyTodayPrepImpact(reservationImpactID)
        store.applyTodayPrepImpact("impact-missing")
        store.dismissTodayPrepImpact(reservationImpactID)
        store.dismissTodayPrepImpact("impact-missing")
        XCTAssertEqual(store.todayPrepImpactAppliedCount, 1)
        XCTAssertTrue(store.currentTodayPrepChecks.contains { $0.id == "check-\(reservationImpactID)" })
        XCTAssertFalse(store.currentTodayPrepReadiness.canComplete)
        try assertAppliedTodayPrepImpactRestores(database, impactID: reservationImpactID)

        store.toggleTodayPrepCheck("check-tare-boil")
        store.toggleTodayPrepCheck("check-tare-clear")
        store.toggleTodayPrepCheck("check-\(reservationImpactID)")
        XCTAssertTrue(store.currentTodayPrepReadiness.canComplete)
        store.completeNextTodayStep(now: "17:40")
        XCTAssertEqual(store.todayPrepCompletionDisplay(for: "tare"), "親方")

        store.recordGuestMessageReply(reservationID: "reservation-tablecheck-kimura-2030", changed: true)
        let replyImpactID = try XCTUnwrap(store.todayPrepImpactItems.first { $0.sourceLabel == "ゲスト返信" }?.id)
        store.applyTodayPrepImpact(replyImpactID)
        XCTAssertEqual(store.todayPrepProgress.nextStepID, "rest")
        XCTAssertTrue(store.currentTodayPrepChecks.contains { $0.id == "check-\(replyImpactID)" })

        _ = store.replayServiceSyncEvents([
            ServiceSyncEvent(
                id: "service-impact-served",
                source: .pos,
                kind: .served,
                covers: 9,
                occurredAt: "2026-06-17T19:05:00Z"
            ),
        ], elapsedMinutes: 80)
        XCTAssertTrue(store.todayPrepImpactItems.contains { $0.sourceLabel == "残数同期" })
        try assertTodayPrepImpactQueueRestores(database, impactID: "impact-service-remaining", sourceLabel: "残数同期")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        assertTodayPrepImpactEvents(eventTypes)
    }

    func testLineGateBlocksUntilImpactsRechecksAndLabelReprintResolve() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.replayGuestSignals(p3VIPReservation(), seatRef: "卓5")
        store.recordGuestMessageReply(reservationID: "reservation-tablecheck-vip", changed: true)
        store.recordGuestMessageReply(reservationID: "reservation-tablecheck-vip", changed: true)
        try assertOpenGuestReplyStateRestores(database)
        var status = store.markAllNowDone()

        XCTAssertFalse(status.canOpen)
        XCTAssertEqual(status.unresolvedImpactCount, 1)
        XCTAssertEqual(status.recheckCount, 1)
        XCTAssertTrue(status.labelReprintRequired)
        XCTAssertEqual(store.lineGateLastAction, "外部変化 1件を手順へ追加")
        XCTAssertEqual(store.todayPrepImpactItems.count { $0.id == "impact-reply-reservation-tablecheck-vip" }, 1)

        let impactID = try XCTUnwrap(store.todayPrepImpactItems.first?.id)
        store.applyTodayPrepImpact(impactID)
        store.toggleTodayPrepCheck("check-\(impactID)")
        store.printAllergenLabels()
        store.printAllergenLabels()
        XCTAssertEqual(store.allergenLabelPrintCount, 1)
        store.completeGuestReplyRecheck("reservation-tablecheck-vip")
        store.completeGuestReplyRecheck("reservation-tablecheck-vip")
        status = store.markAllNowDone()

        XCTAssertTrue(status.canOpen)
        XCTAssertEqual(status.blockingCount, 0)
        XCTAssertEqual(store.lineGateLastAction, "開店ゲートOK")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("line_gate.blocked"))
        XCTAssertTrue(eventTypes.contains("line_gate.ready"))
        XCTAssertTrue(eventTypes.contains("today_prep.impact_applied"))
        XCTAssertTrue(eventTypes.contains("guest_reply.recheck_completed"))
        XCTAssertTrue(eventTypes.contains("guest_reply.recheck_skipped"))
        XCTAssertTrue(eventTypes.contains("allergen_label.printed"))
        XCTAssertEqual(eventTypes.count { $0 == "guest_reply.recheck_requested" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "guest_reply.recheck_completed" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "guest_reply.recheck_skipped" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.impact_queued" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "guest_message.reply_change_skipped" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "allergen_label.printed" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "allergen_label.print_skipped" }, 1)
    }

    func testGuestReplyWithoutAllergenLabelDoesNotRequireEmptyReprint() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.printAllergenLabels()
        XCTAssertEqual(store.allergenLabelPrintCount, 0)
        XCTAssertNil(store.allergenLabelPrintedAt)
        XCTAssertEqual(store.specialPrepLastAction, "印刷する席札なし")

        store.recordGuestMessageReply(reservationID: "reservation-manual-no-allergy", changed: true)
        XCTAssertEqual(store.guestReplyRecheckCount, 1)
        XCTAssertFalse(store.guestReplyRequiresLabelReprint)

        let status = store.markAllNowDone()
        XCTAssertFalse(status.canOpen)
        XCTAssertEqual(status.recheckCount, 1)
        XCTAssertFalse(status.labelReprintRequired)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("allergen_label.print_blocked"))
        XCTAssertTrue(eventTypes.contains("guest_reply.recheck_requested"))
    }

    func testTodayPrepReadinessBatchCompletesDynamicChecksBeforeCompletion() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        _ = store.acceptDirectBooking(DirectBooking(
            id: "direct-readiness",
            visitTime: "18:10",
            covers: 3,
            course: "course-omakase",
            guestName: "Readiness Guest"
        ))
        let impactID = try XCTUnwrap(store.todayPrepImpactItems.first?.id)
        store.applyTodayPrepImpact(impactID)

        store.completeNextTodayStep(now: "17:33")
        XCTAssertNil(store.todayPrepCompletionDisplay(for: "tare"))
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("未完:"))
        XCTAssertEqual(store.currentTodayPrepReadiness.remainingTitles.count, 3)

        store.completeCurrentTodayPrepChecks()
        XCTAssertTrue(store.currentTodayPrepReadiness.canComplete)
        XCTAssertEqual(store.todayPrepCompletionBlockReason, "3件を一括確認")
        store.completeCurrentTodayPrepChecks()
        XCTAssertEqual(store.todayPrepCompletionBlockReason, "3件は確認済み")
        store.completeNextTodayStep(now: "17:34")

        XCTAssertEqual(store.todayPrepCompletionDisplay(for: "tare"), "親方")
        XCTAssertEqual(store.todayPrepProgress.nextStepID, "rest")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("today_prep.completion_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.checks_completed_batch"))
        XCTAssertTrue(eventTypes.contains("today_prep.checks_completed_batch_skipped"))
        XCTAssertTrue(eventTypes.contains("today_prep.step_toggled"))
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.checks_completed_batch" }, 1)
    }

    func testTodayPrepBoardVisibleControlsDriveActiveWorkState() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.startNextTodayStep(now: "17:26")
        XCTAssertEqual(store.todayPrepStartedAt["tare"], "17:26")

        store.pauseTodayPrep(reason: "火入れ待ち", now: "17:29")
        XCTAssertEqual(store.todayPrepActiveHold?.reason, "火入れ待ち")
        XCTAssertEqual(store.todayPrepActiveHold?.pausedAt, "17:29")
        store.pauseTodayPrep(reason: "別作業", now: "17:30")
        XCTAssertEqual(store.todayPrepActiveHold?.reason, "火入れ待ち")
        XCTAssertEqual(store.todayPrepActiveHold?.pausedAt, "17:29")
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:35")
        XCTAssertNil(store.todayPrepCompletionDisplay(for: "tare"))
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("停止中"))

        store.resumeTodayPrep(now: "17:31")
        store.resumeTodayPrep(now: "17:32")
        store.completeNextTodayStep(now: "17:35")
        XCTAssertEqual(store.todayPrepCompletionDisplay(for: "tare"), "親方")
        XCTAssertEqual(store.todayPrepProgress.nextStepID, "rest")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("today_prep.step_started"))
        XCTAssertTrue(eventTypes.contains("today_prep.paused"))
        XCTAssertTrue(eventTypes.contains("today_prep.pause_skipped"))
        XCTAssertTrue(eventTypes.contains("today_prep.resumed"))
        XCTAssertTrue(eventTypes.contains("today_prep.resume_skipped"))
        XCTAssertTrue(eventTypes.contains("today_prep.checks_completed_batch"))
        XCTAssertTrue(eventTypes.contains("today_prep.step_toggled"))
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.paused" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.resumed" }, 1)
    }

    func testTodayPrepPauseResumeRejectInvalidInputsWithoutChangingHold() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.startNextTodayStep(now: "17:26")
        store.pauseTodayPrep(reason: "   ", now: "17:29")
        store.pauseTodayPrep(reason: "火入れ待ち", now: "25:90")
        store.pauseTodayPrep(reason: "火入れ待ち", now: "17:20")
        XCTAssertNil(store.todayPrepActiveHold)
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("着手前"))

        store.pauseTodayPrep(reason: " 火入れ待ち ", now: "17:29")
        XCTAssertEqual(store.todayPrepActiveHold?.reason, "火入れ待ち")
        XCTAssertEqual(store.todayPrepActiveHold?.pausedAt, "17:29")

        store.resumeTodayPrep(now: "invalid")
        XCTAssertEqual(store.todayPrepActiveHold?.reason, "火入れ待ち")
        XCTAssertEqual(store.todayPrepActiveHold?.pausedAt, "17:29")
        store.resumeTodayPrep(now: "17:20")
        XCTAssertEqual(store.todayPrepActiveHold?.reason, "火入れ待ち")
        XCTAssertEqual(store.todayPrepActiveHold?.pausedAt, "17:29")

        store.resumeTodayPrep(now: "17:31")
        XCTAssertNil(store.todayPrepActiveHold)
        XCTAssertEqual(store.todayPrepHoldHistory.last?.resumedAt, "17:31")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.pause_blocked" }, 3)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.resume_blocked" }, 2)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.paused" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.resumed" }, 1)
    }

    func testTodayPrepBoardRowTapRequiresStartAndChecksBeforeCompletion() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.handleTodayPrepBoardStepTap("rest", now: "17:24")
        XCTAssertNil(store.todayPrepStartedAt["rest"])
        XCTAssertEqual(store.todayPrepProgress.nextStepID, "tare")
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("次は"))

        store.handleTodayPrepBoardStepTap("tare", now: "17:25")
        XCTAssertEqual(store.todayPrepStartedAt["tare"], "17:25")
        XCTAssertNil(store.todayPrepCompletionDisplay(for: "tare"))

        store.handleTodayPrepBoardStepTap("tare", now: "17:31")
        XCTAssertNil(store.todayPrepCompletionDisplay(for: "tare"))
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("未完:"))

        store.completeCurrentTodayPrepChecks()
        store.handleTodayPrepBoardStepTap("tare", now: "17:35")
        XCTAssertEqual(store.todayPrepCompletionDisplay(for: "tare"), "親方")
        XCTAssertEqual(store.todayPrepProgress.nextStepID, "rest")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("today_prep.board_step_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.board_step_started"))
        XCTAssertTrue(eventTypes.contains("today_prep.board_step_completed_attempted"))
        XCTAssertTrue(eventTypes.contains("today_prep.completion_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.step_toggled"))
    }

    func testTodayPrepStartIsStableAndReopenClearsOperationalState() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.startNextTodayStep(now: "17:25")
        store.startNextTodayStep(now: "17:40")
        XCTAssertEqual(store.todayPrepStartedAt["tare"], "17:25")
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("着手済み"))

        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:42")
        XCTAssertEqual(store.todayPrepCompletionDisplay(for: "tare"), "親方")
        XCTAssertEqual(store.todayPrepActualDisplay(for: "tare")?.actualMinutes, 17)
        XCTAssertTrue(store.todayPrepCompletedCheckIDs.contains("check-tare-boil"))

        store.handleTodayPrepBoardStepTap("tare", now: "17:50")
        XCTAssertFalse(store.completed.contains("tare"))
        XCTAssertNil(store.todayPrepStartedAt["tare"])
        XCTAssertNil(store.todayPrepCompletionDisplay(for: "tare"))
        XCTAssertNil(store.todayPrepActualDisplay(for: "tare"))
        XCTAssertFalse(store.todayPrepCompletedCheckIDs.contains("check-tare-boil"))
        XCTAssertEqual(store.todayPrepProgress.nextStepID, "tare")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("today_prep.step_start_ignored"))
        XCTAssertTrue(eventTypes.contains("today_prep.board_step_reopened"))
    }

    func testTodayPrepStartAndCompleteRejectInvalidTimesWithoutMutatingProgress() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.startNextTodayStep(now: "25:90")
        XCTAssertNil(store.todayPrepStartedAt["tare"])
        XCTAssertFalse(store.completed.contains("tare"))
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("着手時刻"))

        store.startNextTodayStep(now: "17:25")
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "invalid")
        store.completeNextTodayStep(now: "17:20")

        XCTAssertEqual(store.todayPrepStartedAt["tare"], "17:25")
        XCTAssertFalse(store.completed.contains("tare"))
        XCTAssertNil(store.todayPrepCompletionDisplay(for: "tare"))
        XCTAssertNil(store.todayPrepActualDisplay(for: "tare"))
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("着手前"))

        store.completeNextTodayStep(now: "17:40")
        XCTAssertTrue(store.completed.contains("tare"))
        XCTAssertEqual(store.todayPrepActualDisplay(for: "tare")?.actualMinutes, 15)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.step_start_blocked" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.completion_blocked" }, 2)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.step_started" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.step_toggled" }, 1)
    }

    func testTodayPrepDirectToggleRejectsInvalidTimeWithoutMutatingProgress() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.toggleTodayPrepStep("tare", now: "invalid")
        XCTAssertFalse(store.completed.contains("tare"))
        XCTAssertNil(store.todayPrepCompletionDisplay(for: "tare"))
        XCTAssertNil(store.todayPrepActualDisplay(for: "tare"))
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("操作時刻"))

        store.toggleTodayPrepStep("tare", now: "17:40")
        XCTAssertTrue(store.completed.contains("tare"))
        XCTAssertEqual(store.todayPrepCompletionDisplay(for: "tare"), "親方")

        store.toggleTodayPrepStep("tare", now: "24:00")
        XCTAssertTrue(store.completed.contains("tare"))
        XCTAssertEqual(store.todayPrepCompletionDisplay(for: "tare"), "親方")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.step_toggle_blocked" }, 2)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.step_toggled" }, 1)
    }

    func testTodayPrepActualAdjustmentRejectsNoopAndExtremeDelta() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.startNextTodayStep(now: "17:25")
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:42")
        XCTAssertEqual(store.todayPrepActualDisplay(for: "tare")?.actualMinutes, 17)

        store.adjustTodayPrepActualMinutes(stepID: "tare", delta: 0)
        store.adjustTodayPrepActualMinutes(stepID: "tare", delta: 999)
        store.adjustTodayPrepActualMinutes(stepID: "tare", delta: Int.max)
        XCTAssertEqual(store.todayPrepActualDisplay(for: "tare")?.actualMinutes, 17)

        store.adjustTodayPrepActualMinutes(stepID: "tare", delta: -2)
        XCTAssertEqual(store.todayPrepActualDisplay(for: "tare")?.actualMinutes, 15)
        XCTAssertEqual(store.todayPrepActualDisplay(for: "tare")?.varianceMinutes, 0)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.actual_adjust_blocked" }, 3)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.actual_adjusted" }, 1)
    }

    func testTodayPrepAssistRejectsInvalidRequestTimeWithoutClearingProposal() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.requestTodayPrepAssist(now: "17:45")
        let proposal = try XCTUnwrap(store.todayPrepAssistProposal)
        XCTAssertEqual(proposal.shortfallMinutes, 15)

        store.requestTodayPrepAssist(now: "invalid")
        XCTAssertEqual(store.todayPrepAssistProposal, proposal)
        XCTAssertNil(store.todayPrepAssistAppliedSummary)
        XCTAssertNil(store.todayPrepAssistETAAfterApply)

        store.applyTodayPrepAssist()
        XCTAssertEqual(store.todayPrepAssistAppliedSummary, "シャリ場へ割当 / −10分 / 着地 18:05")
        let restoredStore = BoardStore(completed: ["sake"], database: database)
        XCTAssertEqual(restoredStore.todayPrepAssistProposal, proposal)
        XCTAssertEqual(restoredStore.todayPrepAssistAppliedSummary, "シャリ場へ割当 / −10分 / 着地 18:05")
        XCTAssertEqual(restoredStore.todayPrepAssistETAAfterApply?.landing, "18:05")
        XCTAssertEqual(restoredStore.selectedTodayPrepOperatorID, "operator-shari")
        restoredStore.applyTodayPrepAssist()

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.assist_requested" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.assist_request_blocked" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.assist_applied" }, 1)
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.assist_apply_skipped" }, 1)
    }

    func testStaffLineCheckRequiresReadyLineGate() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.toggleStaffBoardTask("line-check")
        XCTAssertFalse(store.completed.contains("line-check"))
        XCTAssertEqual(store.lineGateLastAction, "残り 2工程")
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("ライン点検不可"))

        _ = store.acceptDirectBooking(DirectBooking(
            id: "direct-line-gate",
            visitTime: "18:10",
            covers: 2,
            course: "course-omakase",
            guestName: "Line Gate Guest"
        ))
        store.markAllNowDone()
        store.toggleStaffBoardTask("line-check")
        XCTAssertFalse(store.completed.contains("line-check"))
        XCTAssertTrue(store.lineGateLastAction.contains("外部変化"))

        let impactID = try XCTUnwrap(store.todayPrepImpactItems.first?.id)
        store.applyTodayPrepImpact(impactID)
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:44")
        store.markAllNowDone()
        store.toggleStaffBoardTask("line-check")
        XCTAssertTrue(store.completed.contains("line-check"))
        XCTAssertEqual(store.lineGateLastAction, "ライン点検完了")
        var restoredStore = BoardStore(completed: ["sake"], database: database)
        XCTAssertTrue(restoredStore.completed.contains("line-check"))
        XCTAssertEqual(restoredStore.lineGateLastAction, "ライン点検完了")

        store.toggleStaffBoardTask("line-check")
        XCTAssertFalse(store.completed.contains("line-check"))
        XCTAssertEqual(store.lineGateLastAction, "ライン点検を取り消し")
        restoredStore = BoardStore(completed: ["sake"], database: database)
        XCTAssertFalse(restoredStore.completed.contains("line-check"))
        XCTAssertEqual(restoredStore.lineGateLastAction, "ライン点検を取り消し")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("line_gate.check_blocked"))
        XCTAssertTrue(eventTypes.contains("line_gate.check_completed"))
        XCTAssertTrue(eventTypes.contains("line_gate.check_reopened"))
    }

    func testBoardLineGateActionDoesNotBatchCompleteHeldOrUncheckedPrep() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.startNextTodayStep(now: "17:27")
        store.pauseTodayPrep(reason: "火入れ待ち", now: "17:31")
        var status = store.requestLineGateFromBoard()

        XCTAssertFalse(status.canOpen)
        XCTAssertFalse(store.completed.contains("tare"))
        XCTAssertFalse(store.completed.contains("rest"))
        XCTAssertFalse(store.completed.contains("nikiri"))
        XCTAssertEqual(store.todayPrepProgress.completedCount, 1)
        XCTAssertTrue(store.lineGateLastAction.contains("停止中"))

        store.resumeTodayPrep(now: "17:36")
        status = store.requestLineGateFromBoard()
        XCTAssertFalse(status.canOpen)
        XCTAssertFalse(store.completed.contains("tare"))
        XCTAssertEqual(store.lineGateLastAction, "残り 2工程")

        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:42")
        store.completeCurrentTodayPrepChecks()
        store.completeNextTodayStep(now: "17:51")
        status = store.requestLineGateFromBoard()

        XCTAssertTrue(status.canOpen)
        XCTAssertTrue(store.completed.contains("nikiri"))
        XCTAssertEqual(store.lineGateLastAction, "開店ゲートOK")
        let restoredReadyStore = BoardStore(completed: ["sake"], database: database)
        XCTAssertFalse(restoredReadyStore.completed.contains("line-check"))
        XCTAssertEqual(restoredReadyStore.lineGateLastAction, "開店ゲートOK")
        status = store.requestLineGateFromBoard()
        XCTAssertTrue(status.canOpen)
        XCTAssertEqual(store.lineGateLastAction, "開店ゲートOK")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("line_gate.board_request_blocked"))
        XCTAssertTrue(eventTypes.contains("line_gate.ready"))
        XCTAssertTrue(eventTypes.contains("line_gate.ready_skipped"))
        XCTAssertEqual(eventTypes.count { $0 == "line_gate.ready" }, 1)
    }

    func testDirectNikiriToggleRoutesThroughTodayPrepGate() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(completed: ["sake"], database: database)

        store.toggle("nikiri")
        XCTAssertEqual(store.todayPrepStartedAt["tare"], "17:25")
        XCTAssertFalse(store.completed.contains("tare"))
        XCTAssertFalse(store.completed.contains("nikiri"))

        store.toggle("nikiri")
        XCTAssertNil(store.todayPrepCompletionDisplay(for: "tare"))
        XCTAssertTrue(store.todayPrepCompletionBlockReason.contains("未完:"))

        store.completeCurrentTodayPrepChecks()
        store.toggle("nikiri")
        XCTAssertEqual(store.todayPrepCompletionDisplay(for: "tare"), "親方")
        XCTAssertFalse(store.completed.contains("nikiri"))

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("today_prep.aggregate_step_routed"))
        XCTAssertTrue(eventTypes.contains("today_prep.board_step_started"))
        XCTAssertTrue(eventTypes.contains("today_prep.completion_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.step_toggled"))
    }

    private func assertTodayPrepUndoPath(_ store: BoardStore) {
        store.selectTodayPrepOperator("operator-garde")
        store.selectTodayPrepOperator("operator-garde")
        store.selectTodayPrepOperator("operator-missing")
        XCTAssertEqual(store.selectedTodayPrepOperatorID, "operator-garde")
        XCTAssertEqual(store.todayPrepStepOperatorOverrides["tare"], "operator-garde")
        let gardeBeforeCompletion = store.todayPrepOperatorWorkloads.first { $0.operatorID == "operator-garde" }
        XCTAssertEqual(gardeBeforeCompletion?.assignedCount, 2)
        XCTAssertEqual(gardeBeforeCompletion?.remainingMinutes, 30)
        store.toggleTodayPrepStep("tare")
        XCTAssertEqual(store.todayPrepProgress.nextStepID, "rest")
        XCTAssertEqual(store.todayPrepProgress.remainingMinutes, 15)
        XCTAssertEqual(store.todayPrepCompletionDisplay(for: "tare"), "ガルド")
        let gardeAfterCompletion = store.todayPrepOperatorWorkloads.first { $0.operatorID == "operator-garde" }
        XCTAssertEqual(gardeAfterCompletion?.completedCount, 1)
        XCTAssertEqual(gardeAfterCompletion?.remainingMinutes, 15)
        XCTAssertEqual(store.lastTodayPrepUndo?.previousCompletedIDs, ["sake"])

        store.undoLastTodayPrepAction()
        XCTAssertEqual(store.todayPrepProgress.nextStepID, "tare")
        XCTAssertNil(store.todayPrepCompletionDisplay(for: "tare"))
        XCTAssertNil(store.lastTodayPrepUndo)
        XCTAssertTrue(store.todayPrepCompletedCheckIDs.isEmpty)
        store.undoLastTodayPrepAction()
        XCTAssertNil(store.lastTodayPrepUndo)
    }

    private func assertTodayPrepGuidanceQualityGate(_ store: BoardStore) {
        store.startNowGuidance()
        XCTAssertEqual(store.nowGuidanceTitle, "たまり・濃口を合わせ ひと煮立ち")
        XCTAssertTrue(store.nowGuidanceBody.contains("たまり"))
        store.startNextTodayStep(now: "17:25")
        XCTAssertEqual(store.todayPrepStartedAt["tare"], "17:25")
        XCTAssertEqual(store.currentTodayPrepChecks.map(\.id), ["check-tare-boil", "check-tare-clear"])
        XCTAssertFalse(store.currentTodayPrepReadiness.canComplete)

        store.applyTodayPrepAssist()
        store.requestTodayPrepAssist(now: "17:45")
        XCTAssertEqual(store.todayPrepAssistProposal?.shortfallMinutes, 15)
        XCTAssertEqual(store.todayPrepAssistProposal?.suggestedOperatorID, "operator-shari")
        store.applyTodayPrepAssist()
        XCTAssertEqual(store.todayPrepAssistAppliedSummary, "シャリ場へ割当 / −10分 / 着地 18:05")
        XCTAssertEqual(store.todayPrepAssistETAAfterApply?.landing, "18:05")
        XCTAssertEqual(store.todayPrepAssistETAAfterApply?.shortfallMin, 5)
        XCTAssertEqual(store.todayPrepStepOperatorOverrides["tare"], "operator-shari")
        let shariBeforeCompletion = store.todayPrepOperatorWorkloads.first { $0.operatorID == "operator-shari" }
        XCTAssertEqual(shariBeforeCompletion?.assignedCount, 1)
        XCTAssertEqual(shariBeforeCompletion?.remainingMinutes, 15)
        store.applyTodayPrepAssist()
        XCTAssertEqual(store.todayPrepAssistAppliedSummary, "シャリ場へ割当 / −10分 / 着地 18:05")
        XCTAssertEqual(store.todayPrepAssistETAAfterApply?.landing, "18:05")
        store.pauseTodayPrep(reason: "火入れ待ち", now: "17:31")
        XCTAssertEqual(store.todayPrepActiveHold?.reason, "火入れ待ち")
        store.completeNextTodayStep(now: "17:42")
        XCTAssertNil(store.todayPrepCompletionDisplay(for: "tare"))
        store.resumeTodayPrep(now: "17:36")
        XCTAssertNil(store.todayPrepActiveHold)
        XCTAssertEqual(store.todayPrepHoldHistory.last?.resumedAt, "17:36")
        store.toggleTodayPrepCheck("check-missing")
        store.toggleTodayPrepCheck("check-tare-boil")
        XCTAssertFalse(store.currentTodayPrepReadiness.canComplete)
        store.toggleTodayPrepCheck("check-tare-clear")
        XCTAssertTrue(store.currentTodayPrepReadiness.canComplete)
        store.completeNextTodayStep(now: "17:42")
        XCTAssertEqual(store.todayPrepCompletionDisplay(for: "tare"), "シャリ場")
        XCTAssertEqual(store.todayPrepActualDisplay(for: "tare")?.actualMinutes, 17)
        XCTAssertEqual(store.todayPrepActualDisplay(for: "tare")?.varianceMinutes, 2)
        let shariAfterCompletion = store.todayPrepOperatorWorkloads.first { $0.operatorID == "operator-shari" }
        XCTAssertEqual(shariAfterCompletion?.completedCount, 1)
        XCTAssertEqual(shariAfterCompletion?.remainingMinutes, 0)
        store.adjustTodayPrepActualMinutes(stepID: "rest", delta: -2)
        store.adjustTodayPrepActualMinutes(stepID: "tare", delta: -2)
        XCTAssertEqual(store.todayPrepActualDisplay(for: "tare")?.actualMinutes, 15)
        XCTAssertEqual(store.todayPrepActualDisplay(for: "tare")?.varianceMinutes, 0)
    }

    private func assertTodayPrepPersistence(store: BoardStore, database: PrepFlowDatabase) throws {
        let instanceRows = try database.rows(.taskInstance, tenantID: "tenant-local")
        let nikiri = try XCTUnwrap(instanceRows.first { $0.id == "instance-task-nikiri" })
        XCTAssertEqual(nikiri.values["status"], "done")
        XCTAssertEqual(nikiri.values["completed_by"], "シャリ場")
        XCTAssertEqual(nikiri.values["checked_at"], "2026-06-17T17:25:00Z")

        let sections = try database.rows(.section, tenantID: "tenant-local")
        XCTAssertNotNil(sections.first { $0.id == "section-shari" })
        let assignment = try XCTUnwrap(try database.rows(.settings, tenantID: "tenant-local").first { $0.id == "setting-today-prep-assignments" })
        XCTAssertTrue(assignment.values["value"]?.contains("tare=operator-shari") == true)
        XCTAssertEqual(store.todayPrepStepOperatorOverrides["tare"], "operator-shari")
        let state = try XCTUnwrap(try database.rows(.settings, tenantID: "tenant-local").first { $0.id == "setting-today-prep-state" })
        XCTAssertTrue(state.values["value"]?.contains("\"completed_focus_ids\"") == true)
        XCTAssertTrue(state.values["value"]?.contains("\"manual_actual_minutes\"") == true)

        let restoredStore = BoardStore(completed: ["sake"], database: database)
        XCTAssertEqual(restoredStore.todayPrepStepOperatorOverrides["tare"], "operator-shari")
        XCTAssertTrue(restoredStore.completed.isSuperset(of: ["sake", "tare", "rest"]))
        XCTAssertTrue(restoredStore.todayPrepProgress.isComplete)
        XCTAssertEqual(restoredStore.todayPrepCompletionDisplay(for: "tare"), "シャリ場")
        XCTAssertEqual(restoredStore.todayPrepActualDisplay(for: "tare")?.actualMinutes, 15)
        XCTAssertEqual(restoredStore.todayPrepCompletedCheckIDs.count, 4)
        let restoredShari = restoredStore.todayPrepOperatorWorkloads.first { $0.operatorID == "operator-shari" }
        XCTAssertEqual(restoredShari?.assignedCount, 1)
        XCTAssertEqual(restoredShari?.completedCount, 1)

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("today_prep.operator_selected"))
        XCTAssertTrue(eventTypes.contains("today_prep.operator_select_skipped"))
        XCTAssertTrue(eventTypes.contains("today_prep.operator_select_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.step_started"))
        XCTAssertTrue(eventTypes.contains("today_prep.step_start_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.check_toggled"))
        XCTAssertTrue(eventTypes.contains("today_prep.check_toggle_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.completion_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.completion_skipped"))
        XCTAssertTrue(eventTypes.contains("today_prep.step_toggled"))
        XCTAssertTrue(eventTypes.contains("today_prep.undo_applied"))
        XCTAssertTrue(eventTypes.contains("today_prep.undo_skipped"))
        XCTAssertTrue(eventTypes.contains("today_prep.guidance_opened"))
        XCTAssertTrue(eventTypes.contains("today_prep.assist_requested"))
        XCTAssertTrue(eventTypes.contains("today_prep.assist_apply_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.assist_applied"))
        XCTAssertTrue(eventTypes.contains("today_prep.assist_apply_skipped"))
        XCTAssertTrue(eventTypes.contains("today_prep.paused"))
        XCTAssertTrue(eventTypes.contains("today_prep.resumed"))
        XCTAssertTrue(eventTypes.contains("today_prep.actual_adjusted"))
        XCTAssertTrue(eventTypes.contains("today_prep.actual_adjust_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.checks_completed_batch_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.batch_completed"))
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.assist_applied" }, 1)
    }

    private func assertMixedReservation(
        diff: ReservationDiffSummary,
        inbound: ManualReservation,
        store: BoardStore,
        database: PrepFlowDatabase
    ) throws {
        XCTAssertEqual(diff.addedCovers, 3)
        XCTAssertEqual(diff.cancelledCovers, 2)
        XCTAssertEqual(store.service.omakaseCovers, 15)
        XCTAssertEqual(Int(store.reservationPlanDiff?.added.first?.qty ?? 0), 42)
        XCTAssertEqual(store.reservationPlanDiff?.reduced.first?.newCovers, 12)
        XCTAssertEqual(store.reservationPlanDiff?.reduced.first?.carryoverCandidate, true)

        let reservationRows = try database.rows(.reservation, tenantID: "tenant-local")
        XCTAssertFalse(reservationRows.contains { $0.id == "reservation-sato" })
        XCTAssertEqual(reservationRows.first { $0.id == inbound.id }?.values["covers"], "3")
    }

    private func assertMissingReservationPreviewNoops(_ store: BoardStore) {
        let missingCancel = store.previewReservationCancellation("reservation-sato")
        XCTAssertEqual(missingCancel.cancelledCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 12)
        XCTAssertTrue(store.reservationPlanDiff?.reduced.isEmpty == true)

        let missingIncrease = store.previewReservationIncrease("reservation-missing", addedCovers: 2)
        XCTAssertEqual(missingIncrease.addedCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 12)
        XCTAssertTrue(store.reservationPlanDiff?.added.isEmpty == true)
    }

    private func assertLarderUsePlan(_ larderPlan: LarderConsumptionPlan) {
        XCTAssertEqual(larderPlan.plannedQty, 90)
        XCTAssertEqual(larderPlan.shortfallQty, 30)
        XCTAssertEqual(larderPlan.uses.first?.labelID, "label-instance-task-nikiri")
    }

    private func assertCloseBatch(store: BoardStore, database: PrepFlowDatabase) throws {
        let invalid = store.recordCloseBatch([
            CloseTaskRecord(
                task: "task-nikiri",
                plannedQty: 200,
                madeQty: 20,
                leftoverQty: 30,
                unit: "ml",
                wasteReason: .overmade,
                carryoverToNext: true
            ),
        ])
        XCTAssertTrue(invalid.records.isEmpty)
        XCTAssertEqual(store.closeGateLastAction, "締め表の数量を確認")
        XCTAssertTrue(store.latestLearningWasteRecords.isEmpty)
        XCTAssertEqual(try database.rows(.wasteLog, tenantID: "tenant-local").count { $0.id.hasPrefix("waste-close-") }, 0)

        let close = store.recordCloseBatch([
            CloseTaskRecord(
                task: "task-nikiri",
                plannedQty: 200,
                madeQty: 230,
                leftoverQty: 30,
                unit: "ml",
                wasteReason: .overmade,
                carryoverToNext: true
            ),
            CloseTaskRecord(
                task: "task-shari",
                plannedQty: 10,
                madeQty: 10,
                leftoverQty: 2,
                unit: "合",
                wasteReason: .quality,
                carryoverToNext: false
            ),
        ])

        XCTAssertEqual(close.records.count, 2)
        XCTAssertEqual(close.carryovers, [CarryoverItem(task: "task-nikiri", qty: 30, unit: "ml")])
        XCTAssertEqual(store.latestLearningWasteRecords.map(\.exclude), [false, true])
        XCTAssertEqual(try database.rows(.wasteLog, tenantID: "tenant-local").count { $0.id.hasPrefix("waste-close-") }, 2)
        XCTAssertEqual(try database.rows(named: "carryover", tenantID: "tenant-local").count { $0.id.hasPrefix("carryover-task-nikiri-close-") }, 1)

        let duplicate = store.recordCloseBatch(close.records)
        XCTAssertEqual(duplicate.records.count, 2)
        XCTAssertEqual(store.closeGateLastAction, "締め表は記録済み")
        XCTAssertEqual(try database.rows(.wasteLog, tenantID: "tenant-local").count { $0.id.hasPrefix("waste-close-") }, 2)
        XCTAssertEqual(try database.rows(named: "carryover", tenantID: "tenant-local").count { $0.id.hasPrefix("carryover-task-nikiri-close-") }, 1)
    }

    private func assertCloseGate(_ close: CloseLoopSummary, store: BoardStore) {
        XCTAssertEqual(close.records.count, 2)
        XCTAssertEqual(close.carryovers.map(\.task), ["task-nikiri"])
        XCTAssertEqual(store.latestLearningWasteRecords.count, 2)
        XCTAssertEqual(store.latestLearningWasteRecords.count(where: { $0.exclude }), 1)
        XCTAssertEqual(store.closeNextDayPrepReservations.count(where: { $0.isReserved }), 2)
        XCTAssertEqual(store.closeGateCompletedAt, "2026-06-11T23:12:00Z")
        XCTAssertEqual(store.closeGateLastAction, "締めゲート完了")

        let duplicate = store.completeCloseGate(now: "2026-06-11T23:20:00Z")
        XCTAssertEqual(duplicate.records.count, 2)
        XCTAssertEqual(store.closeGateCompletedAt, "2026-06-11T23:12:00Z")
        XCTAssertEqual(store.closeGateLastAction, "締めゲート完了済み")
    }

    private func assertCloseOpsStateRestores(database: PrepFlowDatabase) throws {
        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.closeLoopSummary?.records.count, 2)
        XCTAssertEqual(restoredStore.closeLoopSummary?.carryovers, [CarryoverItem(task: "task-nikiri", qty: 30, unit: "ml")])
        XCTAssertEqual(restoredStore.closeLoopSummary?.nextDayAdjustments.first?.adjusted, 180)
        XCTAssertEqual(restoredStore.latestLearningWasteRecords.map(\.exclude), [false, true])
        XCTAssertEqual(restoredStore.closeGateCompletedAt, "2026-06-11T23:12:00Z")
        XCTAssertEqual(restoredStore.closeNextDayPrepReservations.count(where: { $0.isReserved }), 3)

        _ = restoredStore.recordCloseBatch(restoredStore.closeLoopSummary?.records ?? [])
        _ = restoredStore.completeCloseGate(now: "2026-06-11T23:30:00Z")
        XCTAssertEqual(try database.rows(.wasteLog, tenantID: "tenant-local").count { $0.id.hasPrefix("waste-close-") }, 2)
        XCTAssertEqual(try database.rows(named: "carryover", tenantID: "tenant-local").count { $0.id.hasPrefix("carryover-task-nikiri-close-") }, 1)
        XCTAssertEqual(restoredStore.closeGateCompletedAt, "2026-06-11T23:12:00Z")
    }

    private func assertDirectAcceptCancelEvents(_ events: [String?]) {
        XCTAssertTrue(events.contains("direct_booking.accepted"))
        XCTAssertTrue(events.contains("direct_booking.accept_blocked"))
        XCTAssertTrue(events.contains("direct_booking.evaluate_skipped"))
        XCTAssertTrue(events.contains("direct_booking.cancelled"))
        XCTAssertTrue(events.contains("direct_booking.cancel_blocked"))
        XCTAssertEqual(events.count(where: { $0 == "reservation.diffed" }), 2)
    }

    private func assertDirectAcceptCancelStateRestores(_ database: PrepFlowDatabase) throws {
        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.latestDirectBooking?.id, "direct-b200")
        XCTAssertEqual(restoredStore.latestDirectBooking?.status, .cancelled)
        XCTAssertEqual(restoredStore.latestDirectDecision?.reason, "status_cancelled")
        XCTAssertEqual(restoredStore.service.omakaseCovers, 14)

        let duplicateCancel = restoredStore.cancelDirectBooking("direct-b200")
        XCTAssertEqual(duplicateCancel.cancelledCovers, 0)
        XCTAssertEqual(restoredStore.service.omakaseCovers, 14)
    }

    private func assertInvalidDirectCoversWereBlocked(_ database: PrepFlowDatabase) throws {
        XCTAssertFalse(try database.rows(named: "direct_booking", tenantID: "tenant-local").contains { $0.id.hasPrefix("direct-invalid-") })
        XCTAssertFalse(try database.rows(named: "waitlist_entry", tenantID: "tenant-local").contains { $0.id.hasPrefix("waitlist-direct-invalid-") })
        XCTAssertFalse(try database.rows(.reservation, tenantID: "tenant-local").contains { $0.id.hasPrefix("reservation-direct-direct-invalid-") })

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("direct_booking.accept_blocked"))
        XCTAssertTrue(eventTypes.contains("direct_booking.evaluate_blocked"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "direct_booking.accept_blocked" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "direct_booking.evaluate_blocked" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "direct_booking.accepted" }), 0)
        XCTAssertEqual(eventTypes.count(where: { $0 == "direct_booking.evaluated" }), 0)
    }

    private func assertServicePassIdempotencyEvents(_ eventTypes: [String], replayedCountAfterFlush: Int) {
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_sync.replayed" }), replayedCountAfterFlush)
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_pass.offline_flushed" }), 1)
        XCTAssertTrue(eventTypes.contains("service_pass.fire_accepted"))
        XCTAssertTrue(eventTypes.contains("service_pass.fire_accept_skipped"))
        XCTAssertTrue(eventTypes.contains("service_pass.fire_held"))
        XCTAssertTrue(eventTypes.contains("service_pass.fire_hold_skipped"))
        XCTAssertTrue(eventTypes.contains("service_pass.course_served"))
        XCTAssertTrue(eventTypes.contains("service_pass.course_serve_skipped"))
        XCTAssertTrue(eventTypes.contains("service_pass.offline_queued"))
        XCTAssertTrue(eventTypes.contains("service_pass.offline_queue_skipped"))
        XCTAssertTrue(eventTypes.contains("service_pass.offline_flushed"))
        XCTAssertTrue(eventTypes.contains("service_pass.offline_flush_skipped"))
        XCTAssertTrue(eventTypes.contains("service_sync.duplicate_ignored"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_pass.fire_accepted" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_pass.fire_held" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "service_pass.course_served" }), 1)
    }

    private func assertServicePassStateRestores(_ database: PrepFlowDatabase) throws {
        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.serviceSyncEventTimeline.count, 4)
        XCTAssertEqual(restoredStore.servicePassPendingOfflineCount, 0)
        XCTAssertEqual(restoredStore.serviceSyncState?.servedCovers, 6)
        XCTAssertEqual(restoredStore.serviceSyncState?.remainingCovers, 8)
        XCTAssertEqual(restoredStore.passState?.firedCovers, 4)
        XCTAssertEqual(restoredStore.servicePassLastAction, "未送信なし")

        let emptyFlush = restoredStore.flushOfflineServiceEvents()
        XCTAssertEqual(emptyFlush.pendingOfflineEvents, 0)
        XCTAssertEqual(restoredStore.servicePassLastAction, "未送信なし")
        XCTAssertEqual(try database.rows(named: "service_event", tenantID: "tenant-local").count, 4)
    }

    private func assertConfirmedDirectReevaluationIsStable(store: BoardStore, database: PrepFlowDatabase) throws {
        let direct = try XCTUnwrap(try database.rows(named: "direct_booking", tenantID: "tenant-local").first { $0.id == "direct-b200" })
        XCTAssertEqual(direct.values["status"], "confirmed")
        XCTAssertEqual(direct.values["stripe_checkout_id"], "stripe-direct-b200")
        XCTAssertEqual(direct.values["guest_note"], "English menu")

        let latestDirect = try XCTUnwrap(store.latestDirectBooking)
        let reevaluatedConfirmed = store.evaluateDirectAllotment(latestDirect, allottedCovers: 1)
        XCTAssertEqual(reevaluatedConfirmed.status, .confirmed)
        XCTAssertEqual(try database.rows(named: "direct_booking", tenantID: "tenant-local").first { $0.id == "direct-b200" }?.values["status"], "confirmed")
        XCTAssertFalse(try database.rows(named: "waitlist_entry", tenantID: "tenant-local").contains { $0.values["booking_id"] == "direct-b200" })

        let reservation = try XCTUnwrap(try database.rows(.reservation, tenantID: "tenant-local").first { $0.id == "reservation-direct-direct-b200" })
        XCTAssertEqual(reservation.values["source"], "direct")
        XCTAssertEqual(reservation.values["covers"], "2")
        XCTAssertEqual(reservation.values["dup_group"], "direct-b200")
    }

    private func assertPromotedDirectAndServiceBatchStateRestores(_ database: PrepFlowDatabase) throws {
        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.latestDirectBooking?.id, "direct-b300")
        XCTAssertEqual(restoredStore.latestDirectBooking?.status, .confirmed)
        XCTAssertEqual(restoredStore.latestWaitlistPromotion?.status, .confirmed)
        XCTAssertEqual(restoredStore.serviceSyncEventTimeline.map(\.id), ["service-event-fire-thick", "service-event-served-thick"])
        XCTAssertEqual(restoredStore.serviceSyncState?.remainingCovers, 8)
        XCTAssertEqual(restoredStore.multistoreSummary?.remainingCovers, 12)

        let duplicateReplay = restoredStore.replayServiceSyncBatch(thickServiceEventsWithDuplicate(), elapsedMinutes: 60, serviceMinutes: 120)
        XCTAssertEqual(duplicateReplay.ignoredDuplicateEventIDs, [
            "service-event-fire-thick",
            "service-event-fire-thick",
            "service-event-served-thick",
        ])
        XCTAssertEqual(try database.rows(named: "service_event", tenantID: "tenant-local").count, 2)
    }

    private func assertConnectorDuplicateReviewIsNoop(_ store: BoardStore) {
        let duplicateAccept = store.acceptConnectorDiff("source-tablecheck-kimura-2030-review")
        XCTAssertEqual(duplicateAccept.addedCovers, 0)
        XCTAssertEqual(duplicateAccept.cancelledCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 16)
        XCTAssertEqual(store.reservationPlanDiff?.added.count, 0)
        XCTAssertEqual(store.reservationPlanDiff?.reduced.count, 0)

        store.rejectConnectorDiff("source-tablecheck-suzuki-1800-review")
        XCTAssertEqual(store.service.omakaseCovers, 16)

        let replayedQueue = store.queueConnectorReservationDiffs()
        XCTAssertEqual(replayedQueue.count, 2)
        XCTAssertEqual(store.connectorDiffReviewItems.count { $0.state == "未処理" }, 0)
        XCTAssertTrue(store.connectorLastSyncSummary.contains("承認待ち 0件"))
    }

    private func p3ConnectorAddEvent() -> SourceReservationEvent {
        SourceReservationEvent(
            id: "source-tablecheck-r100",
            provider: .tablecheck,
            externalID: "r100",
            visitTime: "18:30",
            covers: 3,
            course: "course-omakase",
            partyName: "外部予約 山田様",
            allergyNote: "甲殻類NG",
            vipRank: "gold"
        )
    }

    private func p3ConnectorCancelEvent() -> SourceReservationEvent {
        SourceReservationEvent(
            id: "source-tablecheck-r100-cancelled",
            provider: .tablecheck,
            externalID: "r100",
            visitTime: "18:30",
            covers: 3,
            course: "course-omakase",
            partyName: "外部予約 山田様",
            status: "cancelled"
        )
    }

    private func assertConnectorReplayIsSkipped(
        _ store: BoardStore,
        event: SourceReservationEvent,
        expectedCovers: Int
    ) {
        let duplicate = store.replayConnectorReservation(event)
        XCTAssertEqual(duplicate.addedCovers, 0)
        XCTAssertEqual(duplicate.cancelledCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, expectedCovers)
        XCTAssertEqual(store.reservationPlanDiff?.added.count, 0)
        XCTAssertEqual(store.reservationPlanDiff?.reduced.count, 0)
        XCTAssertTrue(store.connectorLastSyncSummary.contains("スキップ"))
    }

    private func assertConnectorReviewOmotenashiPersistence(_ database: PrepFlowDatabase) throws {
        let acceptedEvent = try XCTUnwrap(
            try database.rows(named: "source_event", tenantID: "tenant-local")
                .first { $0.id == "source-tablecheck-kimura-2030-review" }
        )
        XCTAssertEqual(acceptedEvent.values["processed_at"], "2026-06-17T09:00:01Z")
        XCTAssertTrue(acceptedEvent.values["payload"]?.contains("\"review_state\":\"accepted\"") == true)

        let rejectedEvent = try XCTUnwrap(
            try database.rows(named: "source_event", tenantID: "tenant-local")
                .first { $0.id == "source-tablecheck-suzuki-1800-review" }
        )
        XCTAssertEqual(rejectedEvent.values["processed_at"], "2026-06-17T09:05:00Z")
        XCTAssertTrue(rejectedEvent.values["payload"]?.contains("\"review_state\":\"rejected\"") == true)

        let specialPrepRows = try database.rows(named: "special_prep", tenantID: "tenant-local")
        XCTAssertEqual(specialPrepRows.count, 2)
        let recheck = try XCTUnwrap(specialPrepRows.first { $0.id == "special-prep-recheck-reservation-tablecheck-kimura-2030" })
        XCTAssertEqual(recheck.values["status"], "done")
        XCTAssertEqual(try database.rows(named: "allergen_label", tenantID: "tenant-local").count, 1)
        let passFlags = try database.rows(named: "pass_seat_flag", tenantID: "tenant-local")
        XCTAssertTrue(passFlags.contains { $0.id == "pass-flag-recheck-reservation-tablecheck-kimura-2030" })
        XCTAssertEqual(passFlags.first?.values["seat_ref"], "卓5")
        XCTAssertEqual(try database.rows(named: "guest_message", tenantID: "tenant-local").first?.values["status"], "sent")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("connector.sync_replayed"))
        XCTAssertTrue(eventTypes.contains("connector.diff_accepted"))
        XCTAssertTrue(eventTypes.contains("connector.diff_accept_blocked"))
        XCTAssertTrue(eventTypes.contains("connector.diff_rejected"))
        XCTAssertTrue(eventTypes.contains("connector.diff_reject_blocked"))
        XCTAssertTrue(eventTypes.contains("connector.sync_event_skipped"))
        XCTAssertTrue(eventTypes.contains("connector.reservation_applied"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.diffed" }), 1)
        XCTAssertTrue(eventTypes.contains("guest_signals.replayed"))
        XCTAssertTrue(eventTypes.contains("guest_message.sent"))
        XCTAssertTrue(eventTypes.contains("guest_message.send_skipped"))
        XCTAssertTrue(eventTypes.contains("guest_message.reply_changed"))
        XCTAssertTrue(eventTypes.contains("guest_reply.recheck_requested"))
        XCTAssertTrue(eventTypes.contains("guest_reply.recheck_completed"))
        XCTAssertTrue(eventTypes.contains("allergen_label.printed"))
        XCTAssertTrue(eventTypes.contains("allergen_label.print_skipped"))
        XCTAssertTrue(eventTypes.contains("special_prep.completed"))
        XCTAssertTrue(eventTypes.contains("special_prep.complete_skipped"))
        XCTAssertTrue(eventTypes.contains("special_prep.complete_blocked"))
        XCTAssertTrue(eventTypes.contains("special_prep.skipped"))
        XCTAssertTrue(eventTypes.contains("special_prep.skip_skipped"))
        XCTAssertTrue(eventTypes.contains("special_prep.skip_blocked"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "special_prep.completed" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "special_prep.skipped" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "special_prep.complete_blocked" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "special_prep.skip_blocked" }), 2)
    }

    private func assertCompletedOmotenashiStateRestores(_ database: PrepFlowDatabase) throws {
        let restoredStore = BoardStore(database: database)
        XCTAssertTrue(restoredStore.specialPrepTasks.isEmpty)
        XCTAssertEqual(restoredStore.allergenLabels.count, 1)
        XCTAssertEqual(restoredStore.guestMessages.first?.status, "sent")
        XCTAssertEqual(restoredStore.allergenLabelPrintCount, 1)
        XCTAssertEqual(restoredStore.guestReplyRecheckCount, 0)
        XCTAssertFalse(restoredStore.guestReplyRequiresLabelReprint)
        XCTAssertTrue(restoredStore.passSeatFlags.contains { $0.kind == .special && $0.displayText.contains("返信変更") })
        XCTAssertEqual(restoredStore.guestReplyRecheckLastAction, "reservation-tablecheck-kimura-2030 再確認完了")
    }

    private func assertOpenGuestReplyStateRestores(_ database: PrepFlowDatabase) throws {
        let restoredStore = BoardStore(completed: ["sake"], database: database)
        XCTAssertEqual(restoredStore.specialPrepTasks.count { $0.id == "special-prep-recheck-reservation-tablecheck-vip" }, 1)
        XCTAssertEqual(restoredStore.allergenLabels.count, 1)
        XCTAssertEqual(restoredStore.guestReplyRecheckCount, 1)
        XCTAssertTrue(restoredStore.guestReplyRequiresLabelReprint)
        XCTAssertTrue(restoredStore.passSeatFlags.contains { $0.id == "pass-flag-recheck-reservation-tablecheck-vip" })
        XCTAssertFalse(restoredStore.lineGateStatus.canOpen)
        XCTAssertEqual(restoredStore.lineGateStatus.recheckCount, 1)
        XCTAssertTrue(restoredStore.lineGateStatus.labelReprintRequired)
    }

    private func assertTodayPrepImpactQueueRestores(
        _ database: PrepFlowDatabase,
        impactID: String,
        sourceLabel: String
    ) throws {
        let restoredStore = BoardStore(completed: ["sake"], database: database)
        let impact = try XCTUnwrap(restoredStore.todayPrepImpactItems.first { $0.id == impactID })
        XCTAssertEqual(impact.sourceLabel, sourceLabel)
        XCTAssertFalse(restoredStore.lineGateStatus.canOpen)
        XCTAssertEqual(restoredStore.lineGateStatus.unresolvedImpactCount, restoredStore.todayPrepImpactItems.count)
        XCTAssertTrue(restoredStore.todayPrepImpactLastAction.contains(sourceLabel))
    }

    private func assertAppliedTodayPrepImpactRestores(
        _ database: PrepFlowDatabase,
        impactID: String
    ) throws {
        let restoredStore = BoardStore(completed: ["sake"], database: database)
        XCTAssertFalse(restoredStore.todayPrepImpactItems.contains { $0.id == impactID })
        XCTAssertEqual(restoredStore.todayPrepImpactAppliedCount, 1)
        XCTAssertTrue(restoredStore.currentTodayPrepChecks.contains { $0.id == "check-\(impactID)" })
        XCTAssertTrue(restoredStore.todayPrepImpactLastAction.contains("Direct"))
    }

    private func assertTodayPrepImpactEvents(_ eventTypes: [String]) {
        XCTAssertTrue(eventTypes.contains("today_prep.impact_queued"))
        XCTAssertTrue(eventTypes.contains("today_prep.impact_applied"))
        XCTAssertTrue(eventTypes.contains("today_prep.impact_apply_skipped"))
        XCTAssertTrue(eventTypes.contains("today_prep.impact_apply_blocked"))
        XCTAssertTrue(eventTypes.contains("today_prep.impact_dismiss_skipped"))
        XCTAssertTrue(eventTypes.contains("today_prep.impact_dismiss_blocked"))
        XCTAssertTrue(eventTypes.contains("guest_reply.recheck_requested"))
        XCTAssertTrue(eventTypes.contains("service_sync.replayed"))
        XCTAssertEqual(eventTypes.count { $0 == "today_prep.impact_applied" }, 2)
    }

    private func assertSpecialPrepCompleteSkipIdempotency(_ store: BoardStore) throws {
        let prepIDs = store.specialPrepTasks
            .map(\.id)
            .filter { !$0.hasPrefix("special-prep-recheck-") }
        let completedPrepID = try XCTUnwrap(prepIDs.first)
        let skippedPrepID = try XCTUnwrap(prepIDs.dropFirst().first)

        store.completeSpecialPrepTask(completedPrepID)
        store.completeSpecialPrepTask(completedPrepID)
        store.skipSpecialPrepTask(completedPrepID)
        store.skipSpecialPrepTask(skippedPrepID)
        store.skipSpecialPrepTask(skippedPrepID)
        store.completeSpecialPrepTask(skippedPrepID)
        store.completeSpecialPrepTask("special-prep-missing")
        store.skipSpecialPrepTask("special-prep-missing")

        XCTAssertTrue(store.specialPrepLastAction.contains("見つかりません"))
    }

    private func assertServiceBatchReplayIdempotency(store: BoardStore, database: PrepFlowDatabase) throws {
        let replay = store.replayServiceSyncBatch(thickServiceEventsWithDuplicate(), elapsedMinutes: 60, serviceMinutes: 120)
        XCTAssertEqual(replay.acceptedEventIDs, ["service-event-fire-thick", "service-event-served-thick"])
        XCTAssertEqual(replay.ignoredDuplicateEventIDs, ["service-event-fire-thick"])
        XCTAssertEqual(replay.state.firedCovers, 3)
        XCTAssertEqual(replay.state.remainingCovers, 8)
        XCTAssertTrue(store.todayPrepImpactItems.contains { $0.sourceLabel == "残数同期" })
        XCTAssertEqual(try database.rows(named: "service_event", tenantID: "tenant-local").count, 2)
        let serviceImpactCount = store.todayPrepImpactItems.count { $0.sourceLabel == "残数同期" }

        let duplicateReplay = store.replayServiceSyncBatch(thickServiceEventsWithDuplicate(), elapsedMinutes: 60, serviceMinutes: 120)
        XCTAssertEqual(duplicateReplay.acceptedEventIDs, replay.acceptedEventIDs)
        XCTAssertEqual(duplicateReplay.ignoredDuplicateEventIDs, [
            "service-event-fire-thick",
            "service-event-fire-thick",
            "service-event-served-thick",
        ])
        XCTAssertEqual(store.todayPrepImpactItems.count { $0.sourceLabel == "残数同期" }, serviceImpactCount)
        XCTAssertEqual(try database.rows(named: "service_event", tenantID: "tenant-local").count, 2)
    }

    private func p35InboundDirectBooking() -> DirectBooking {
        DirectBooking(
            id: "direct-b300",
            visitTime: "18:00",
            covers: 4,
            course: "course-omakase",
            guestName: "Inbound Guest",
            guestNote: "special dessert",
            stripeCheckoutID: "stripe-direct-b300"
        )
    }

    private func p3VIPReservation() -> NormalizedReservation {
        NormalizedReservation(
            id: "reservation-tablecheck-vip",
            source: "tablecheck",
            externalID: "vip",
            visitTime: "18:00",
            covers: 2,
            course: "course-omakase",
            partyName: "VIP Guest",
            status: "confirmed",
            prepNote: "甲殻類NG / VIP:gold / 記念日"
        )
    }

    private func p4ServiceSyncEvents() -> [ServiceSyncEvent] {
        [
            ServiceSyncEvent(
                id: "service-event-fire-1",
                source: .kds,
                kind: .fire,
                covers: 6,
                reservationID: "reservation-sato",
                occurredAt: "2026-06-17T10:00:00Z"
            ),
            ServiceSyncEvent(
                id: "service-event-hold-1",
                source: .kds,
                kind: .hold,
                covers: 2,
                reservationID: "reservation-suzuki",
                occurredAt: "2026-06-17T10:05:00Z"
            ),
            ServiceSyncEvent(
                id: "service-event-served-1",
                source: .pos,
                kind: .served,
                covers: 4,
                reservationID: "reservation-sato",
                occurredAt: "2026-06-17T10:10:00Z"
            ),
            ServiceSyncEvent(
                id: "service-event-served-offline",
                source: .pos,
                kind: .served,
                covers: 3,
                reservationID: "reservation-takahashi",
                occurredAt: "2026-06-17T10:12:00Z",
                offlineSequence: 1
            ),
        ]
    }

    private func thickServiceEventsWithDuplicate() -> [ServiceSyncEvent] {
        [
            ServiceSyncEvent(
                id: "service-event-fire-thick",
                source: .kds,
                kind: .fire,
                covers: 3,
                occurredAt: "2026-06-17T10:00:00Z"
            ),
            ServiceSyncEvent(
                id: "service-event-fire-thick",
                source: .kds,
                kind: .fire,
                covers: 3,
                occurredAt: "2026-06-17T10:00:01Z"
            ),
            ServiceSyncEvent(
                id: "service-event-served-thick",
                source: .pos,
                kind: .served,
                covers: 10,
                occurredAt: "2026-06-17T10:10:00Z"
            ),
        ]
    }

    private func thickStoreSummaries() -> [StoreServiceSummary] {
        [
            StoreServiceSummary(
                id: "store-hayashi",
                restaurantName: "鮨 はやし",
                serviceDate: "2026-06-17",
                remainingCovers: 7,
                recommendation: "keep"
            ),
            StoreServiceSummary(
                id: "store-ao",
                restaurantName: "鮨 青",
                serviceDate: "2026-06-17",
                remainingCovers: 5,
                recommendation: "fire"
            ),
        ]
    }

    private func assertReservationHubIdempotencyEvents(_ database: PrepFlowDatabase) throws {
        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("connector.reservation_applied"))
        XCTAssertTrue(eventTypes.contains("reservation.apply_blocked"))
        XCTAssertTrue(eventTypes.contains("reservation.course_assigned"))
        XCTAssertTrue(eventTypes.contains("reservation.course_assignment_skipped"))
        XCTAssertTrue(eventTypes.contains("reservation.course_assignment_blocked"))
        XCTAssertTrue(eventTypes.contains("reservation.duplicate_kept"))
        XCTAssertTrue(eventTypes.contains("reservation.duplicate_keep_skipped"))
        XCTAssertTrue(eventTypes.contains("reservation.duplicate_merge_skipped"))
        XCTAssertTrue(eventTypes.contains("reservation.applied_to_prep"))
        XCTAssertTrue(eventTypes.contains("reservation.apply_skipped"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.diffed" }), 2)
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.course_assigned" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.duplicate_kept" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "reservation.applied_to_prep" }), 1)
    }

    private func assertInvalidServiceInputsAreClampedOrBlocked(_ store: BoardStore) {
        store.updateOmakaseCovers(-3)
        store.updateOtherCovers(-2)
        XCTAssertEqual(store.service.omakaseCovers, 0)
        XCTAssertEqual(store.service.otherCovers, 0)
        XCTAssertEqual(Int(store.nikiriQuantity.total), 0)

        store.updateOpenTime("25:90")
        store.updateOpenTime("invalid")
        XCTAssertEqual(store.service.openTime, "18:00")
        XCTAssertEqual(store.nikiriSchedule.start, "15:00")
    }

    private func assertPart2ServicePeriodPersists(_ database: PrepFlowDatabase) throws {
        let periodRows = try database.rows(named: "service_period", tenantID: "tenant-local")
        let part2 = try XCTUnwrap(periodRows.first { $0.id == "period-part2" })
        XCTAssertEqual(part2.values["open_time"], "20:30")
    }

    private func assertDailyOpsETARestores(_ database: PrepFlowDatabase) {
        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.eta.landing, "20:22")
        XCTAssertEqual(restoredStore.eta.shortfallMin, 0)
        restoredStore.recordETAInput(now: "20:00", remainingDurationsMin: [12, 10])
    }

    private func assertDailyOpsRailAndAggregateRestore(
        _ database: PrepFlowDatabase,
        aggregate: AggregatedQuantity
    ) {
        let restoredStore = BoardStore(database: database)
        XCTAssertEqual(restoredStore.dayrailItems.count, 5)
        XCTAssertEqual(restoredStore.sharedPrepAggregate, aggregate)
        restoredStore.prepareDayrail()
        XCTAssertEqual(restoredStore.aggregateSharedPrep(), aggregate)
    }

    private func assertInvalidLarderUseDoesNotConsume(store: BoardStore, database: PrepFlowDatabase) throws {
        let zeroPlan = store.applyPlannedLarderUse(requiredQty: 0, nowDate: "2026-06-12")
        XCTAssertEqual(zeroPlan.plannedQty, 0)
        XCTAssertEqual(zeroPlan.shortfallQty, 0)
        XCTAssertEqual(store.latestLarderUseSummary, "FIFO使用不可 / 必要量を確認")

        let negativePlan = store.applyPlannedLarderUse(requiredQty: -15, nowDate: "2026-06-12")
        XCTAssertEqual(negativePlan.plannedQty, 0)
        XCTAssertEqual(negativePlan.shortfallQty, 0)
        XCTAssertEqual(store.latestLarderUseSummary, "FIFO使用不可 / 必要量を確認")

        let larder = try XCTUnwrap(try database.rows(named: "larder_item", tenantID: "tenant-local").first { $0.id == "larder-label-instance-task-nikiri" })
        XCTAssertEqual(larder.values["qty"], "90")
        XCTAssertEqual(larder.values["status"], "available")
    }

    private func assertLabelIssueIdempotencyEvents(_ database: PrepFlowDatabase) throws {
        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("label.printed"))
        XCTAssertTrue(eventTypes.contains("label.issue_skipped"))
        XCTAssertTrue(eventTypes.contains("label.issue_blocked"))
        XCTAssertTrue(eventTypes.contains("label.scan_blocked"))
        XCTAssertTrue(eventTypes.contains("label.scan_blocked_skipped"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "label.printed" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label.scanned" }), 3)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label.scan_blocked" }), 1)
    }

    private func assertLabelOutputIdempotencyEvents(_ database: PrepFlowDatabase) throws {
        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("label_printer.default_selected"))
        XCTAssertTrue(eventTypes.contains("label_printer.default_select_skipped"))
        XCTAssertTrue(eventTypes.contains("label_printer.default_select_blocked"))
        XCTAssertTrue(eventTypes.contains("label_printer.paper_selected"))
        XCTAssertTrue(eventTypes.contains("label_printer.paper_select_skipped"))
        XCTAssertTrue(eventTypes.contains("label_pdf.exported"))
        XCTAssertTrue(eventTypes.contains("label_pdf.export_skipped"))
        XCTAssertTrue(eventTypes.contains("label_print.tested"))
        XCTAssertTrue(eventTypes.contains("label_print.test_skipped"))
        XCTAssertTrue(eventTypes.contains("label_qr.opened"))
        XCTAssertTrue(eventTypes.contains("label_qr.open_skipped"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "label_printer.default_selected" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label_printer.default_select_blocked" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label_printer.paper_selected" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label_pdf.exported" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label_print.tested" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label_qr.opened" }), 1)
    }

    private func assertLabelMissingOutputIdempotencyEvents(_ database: PrepFlowDatabase) throws {
        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").compactMap { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("label_print.blocked"))
        XCTAssertTrue(eventTypes.contains("label_print.blocked_skipped"))
        XCTAssertTrue(eventTypes.contains("label_pdf.blocked"))
        XCTAssertTrue(eventTypes.contains("label_pdf.blocked_skipped"))
        XCTAssertTrue(eventTypes.contains("label_qr.blocked"))
        XCTAssertTrue(eventTypes.contains("label_qr.blocked_skipped"))
        XCTAssertTrue(eventTypes.contains("label.scan_blocked"))
        XCTAssertTrue(eventTypes.contains("label.scan_blocked_skipped"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "label_print.blocked" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label_pdf.blocked" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label_qr.blocked" }), 1)
        XCTAssertEqual(eventTypes.count(where: { $0 == "label.scan_blocked" }), 1)
    }

    private func assertExportSnapshotIncludesStagingReadiness(_ store: BoardStore) {
        let export = store.exportSnapshotJSON()
        XCTAssertTrue(export.contains("\"service_period_id\":\"period-part2\"") && export.contains("\"settings_lock\":\"unlocked\""))
        XCTAssertTrue(export.contains("\"auth_readiness\":\"SQLite 起動可\""))
        XCTAssertTrue(export.contains("\"p0_flow_status\":\"settings_exported\""))
        XCTAssertEqual(store.latestExportSummary, "JSON / SQLite 起動可")
        let partialAuthExport = store.exportSnapshotJSON(authReadinessLabel: "不足: APPLE_SERVICES_ID")
        XCTAssertTrue(partialAuthExport.contains("\"auth_readiness\":\"不足: APPLE_SERVICES_ID\""))
        XCTAssertEqual(store.latestExportSummary, "JSON / 不足: APPLE_SERVICES_ID")
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
