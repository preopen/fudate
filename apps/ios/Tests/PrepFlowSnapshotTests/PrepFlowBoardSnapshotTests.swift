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

    func testP1DailyOpsPersistServicePeriodAssignmentETACarryoverAndExport() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.selectServicePeriod("period-part2")
        XCTAssertEqual(store.service.openTime, "20:30")
        XCTAssertEqual(store.service.selectedPeriodID, "period-part2")

        let periodRows = try database.rows(named: "service_period", tenantID: "tenant-local")
        let part2 = try XCTUnwrap(periodRows.first { $0.id == "period-part2" })
        XCTAssertEqual(part2.values["open_time"], "20:30")

        store.assignNikiri(toSectionName: "ガルド")
        store.generateBoardFromService()
        let taskRows = try database.rows(.prepTask, tenantID: "tenant-local")
        let nikiriTask = try XCTUnwrap(taskRows.first { $0.id == "task-nikiri" })
        XCTAssertEqual(nikiriTask.values["section_id"], "section-garde")

        let instanceRows = try database.rows(.taskInstance, tenantID: "tenant-local")
        let nikiriInstance = try XCTUnwrap(instanceRows.first { $0.id == "instance-task-nikiri" })
        XCTAssertEqual(nikiriInstance.values["assignee_section_id"], "section-garde")

        store.recordETAInput(now: "20:00", remainingDurationsMin: [12, 10])
        XCTAssertEqual(store.eta.landing, "20:22")
        XCTAssertEqual(store.eta.shortfallMin, 0)

        store.recordNikiriCarryover(qty: 36)
        let carryoverRows = try database.rows(named: "carryover", tenantID: "tenant-local")
        let carryover = try XCTUnwrap(carryoverRows.first)
        XCTAssertEqual(carryover.values["prep_task_id"], "task-nikiri")
        XCTAssertEqual(carryover.values["qty"], "36")
        XCTAssertEqual(carryover.values["status"], "available")

        store.toggleSettingsLock()
        XCTAssertFalse(store.settingsLocked)
        let export = store.exportSnapshotJSON()
        XCTAssertTrue(export.contains("\"service_period_id\":\"period-part2\""))
        XCTAssertTrue(export.contains("\"settings_lock\":\"unlocked\""))

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("service_period.selected"))
        XCTAssertTrue(eventTypes.contains("task.assigned"))
        XCTAssertTrue(eventTypes.contains("eta.recorded"))
        XCTAssertTrue(eventTypes.contains("carryover.created"))
        XCTAssertTrue(eventTypes.contains("data.exported"))
    }

    func testP15DayrailAndSubrecipeAggregatePersistAndRollUp() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.generateBoardFromService()
        store.prepareDayrail()

        XCTAssertEqual(store.dayrailItems.count, 5)
        XCTAssertEqual(Set(store.dayrailItems.map(\.kind)), [.prep, .service, .close])
        let dayrailRows = try database.rows(named: "dayrail_item", tenantID: "tenant-local")
        XCTAssertEqual(dayrailRows.count, 5)
        XCTAssertEqual(Set(dayrailRows.compactMap { $0.values["sort"] }), ["0", "1", "2", "3", "4"])

        store.updateOtherCovers(2)
        let aggregate = store.aggregateSharedPrep()
        XCTAssertEqual(aggregate.totalCovers, 16)
        XCTAssertEqual(Int(aggregate.quantity.total), 220)
        XCTAssertEqual(aggregate.sources, ["omakase:14", "walkin:2"])

        let instanceRows = try database.rows(.taskInstance, tenantID: "tenant-local")
        XCTAssertEqual(instanceRows.count(where: { $0.values["prep_task_id"] == "task-nikiri" }), 1)

        let aggregateRows = try database.rows(named: "subrecipe_aggregate", tenantID: "tenant-local")
        let aggregateRow = try XCTUnwrap(aggregateRows.first)
        XCTAssertEqual(aggregateRow.values["prep_task_id"], "task-nikiri")
        XCTAssertEqual(aggregateRow.values["total_covers"], "16")
        XCTAssertEqual(aggregateRow.values["total_qty"], "220")
        XCTAssertEqual(aggregateRow.values["status"], "in_progress")

        store.completeSharedPrepAggregate()
        let completedAggregate = try XCTUnwrap(try database.rows(named: "subrecipe_aggregate", tenantID: "tenant-local").first)
        XCTAssertEqual(completedAggregate.values["status"], "done")

        let references = try database.rows(named: "subrecipe_reference", tenantID: "tenant-local")
        XCTAssertEqual(references.compactMap { $0.values["course_key"] }.sorted(), ["omakase", "walkin"])
        XCTAssertTrue(references.allSatisfy { $0.values["rollup_status"] == "done" })

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("dayrail.planned"))
        XCTAssertTrue(eventTypes.contains("subrecipe.aggregated"))
        XCTAssertTrue(eventTypes.contains("subrecipe.rollup_completed"))
    }

    func testP2CloseLoopCarryoverAndReservationDiffPersistLocally() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.generateBoardFromService()
        let close = store.recordCloseLoop(madeQty: 240, leftoverQty: 40, wasteReason: .overmade, carryoverToNext: true)

        XCTAssertEqual(close.carryovers, [CarryoverItem(task: "task-nikiri", qty: 40, unit: "ml")])
        XCTAssertEqual(close.nextDayAdjustments.first?.adjusted, 160)
        let waste = try XCTUnwrap(try database.rows(.wasteLog, tenantID: "tenant-local").first { $0.id == "waste-close-task-nikiri-1" })
        XCTAssertEqual(waste.values["waste_reason"], "overmade")
        XCTAssertEqual(waste.values["carryover_to_next"], "1")
        XCTAssertEqual(waste.values["leftover_qty"], "40")

        let carryover = try XCTUnwrap(try database.rows(named: "carryover", tenantID: "tenant-local").first { $0.id == "carryover-task-nikiri-close-1" })
        XCTAssertEqual(carryover.values["qty"], "40")
        XCTAssertEqual(carryover.values["status"], "available")

        store.markAllNowDone()
        let diff = store.previewReservationCancellation("reservation-sato")

        XCTAssertEqual(diff.cancelledCovers, 2)
        XCTAssertEqual(diff.changedReservationIDs, ["reservation-sato"])
        XCTAssertEqual(store.reservationPlanDiff?.reduced.first?.newCovers, 12)
        XCTAssertEqual(Int(store.reservationPlanDiff?.reduced.first?.newTotal ?? 0), 170)
        XCTAssertEqual(store.reservationPlanDiff?.reduced.first?.carryoverCandidate, true)

        let activeReservations = try database.rows(.reservation, tenantID: "tenant-local")
        XCTAssertFalse(activeReservations.contains { $0.id == "reservation-sato" })

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("close.completed"))
        XCTAssertTrue(eventTypes.contains("nextday.previewed"))
        XCTAssertTrue(eventTypes.contains("reservation.diffed"))
        XCTAssertTrue(eventTypes.contains("reservation.carryover_candidate"))
    }

    func testP25LabelQRFlowPersistsLarderCarryoverAndWaste() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        store.generateBoardFromService()
        let label = store.issueNikiriPrepLabel()

        XCTAssertEqual(label.id, "label-instance-task-nikiri")
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

        let remainingLabel = try XCTUnwrap(try database.rows(named: "label", tenantID: "tenant-local").first { $0.id == label.id })
        XCTAssertEqual(remainingLabel.values["status"], "remaining")
        XCTAssertEqual(remainingLabel.values["remaining_qty"], "65")

        let carryover = try XCTUnwrap(try database.rows(named: "carryover", tenantID: "tenant-local").first { $0.id == "carryover-task-nikiri-\(label.id)" })
        XCTAssertEqual(carryover.values["qty"], "65")
        XCTAssertEqual(carryover.values["expire_at"], "2026-06-12T23:59:00Z")

        let wasted = store.scanLatestLabelWaste(qty: 12, reason: .quality)
        XCTAssertEqual(wasted.label.status, .wasted)
        XCTAssertEqual(wasted.wasteRecord?.wasteReason, .quality)

        let wastedLarder = try XCTUnwrap(try database.rows(named: "larder_item", tenantID: "tenant-local").first { $0.id == "larder-\(label.id)" })
        XCTAssertEqual(wastedLarder.values["status"], "wasted")
        XCTAssertEqual(wastedLarder.values["qty"], "0")

        let waste = try XCTUnwrap(try database.rows(.wasteLog, tenantID: "tenant-local").first { $0.values["recorded_by"] == "label-qr" })
        XCTAssertEqual(waste.values["waste_reason"], "quality")
        XCTAssertEqual(waste.values["leftover_qty"], "12")
        XCTAssertEqual(waste.values["carryover_to_next"], "0")

        let eventTypes = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        XCTAssertTrue(eventTypes.contains("label.printed"))
        XCTAssertEqual(eventTypes.count(where: { $0 == "label.scanned" }), 2)
    }

    func testP3ConnectorReservationReplayPersistsSourceEventAndPrepImpact() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)

        let added = store.replayConnectorReservation(SourceReservationEvent(
            id: "source-tablecheck-r100",
            provider: .tablecheck,
            externalID: "r100",
            visitTime: "18:30",
            covers: 3,
            course: "course-omakase",
            partyName: "外部予約 山田様",
            allergyNote: "甲殻類NG",
            vipRank: "gold"
        ))

        XCTAssertEqual(added.addedCovers, 3)
        XCTAssertEqual(added.cancelledCovers, 0)
        XCTAssertEqual(store.service.omakaseCovers, 17)
        XCTAssertEqual(Int(store.reservationPlanDiff?.added.first?.qty ?? 0), 42)

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

        let cancelled = store.replayConnectorReservation(SourceReservationEvent(
            id: "source-tablecheck-r100-cancelled",
            provider: .tablecheck,
            externalID: "r100",
            visitTime: "18:30",
            covers: 3,
            course: "course-omakase",
            partyName: "外部予約 山田様",
            status: "cancelled"
        ))

        XCTAssertEqual(cancelled.addedCovers, 0)
        XCTAssertEqual(cancelled.cancelledCovers, 3)
        XCTAssertEqual(store.service.omakaseCovers, 14)
        XCTAssertEqual(Int(store.reservationPlanDiff?.reduced.first?.newTotal ?? 0), 200)

        let activeReservations = try database.rows(.reservation, tenantID: "tenant-local")
        XCTAssertFalse(activeReservations.contains { $0.id == "reservation-tablecheck-r100" })

        let events = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        XCTAssertTrue(events.contains("connector.reservation_applied"))
        XCTAssertEqual(events.count(where: { $0 == "reservation.diffed" }), 2)
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

        let direct = try XCTUnwrap(try database.rows(named: "direct_booking", tenantID: "tenant-local").first { $0.id == "direct-b200" })
        XCTAssertEqual(direct.values["status"], "confirmed")
        XCTAssertEqual(direct.values["stripe_checkout_id"], "stripe-direct-b200")
        XCTAssertEqual(direct.values["guest_note"], "English menu")

        let reservation = try XCTUnwrap(try database.rows(.reservation, tenantID: "tenant-local").first { $0.id == "reservation-direct-direct-b200" })
        XCTAssertEqual(reservation.values["source"], "direct")
        XCTAssertEqual(reservation.values["covers"], "2")
        XCTAssertEqual(reservation.values["dup_group"], "direct-b200")

        let cancelled = store.cancelDirectBooking("direct-b200")

        XCTAssertEqual(cancelled.addedCovers, 0)
        XCTAssertEqual(cancelled.cancelledCovers, 2)
        XCTAssertEqual(store.service.omakaseCovers, 14)
        XCTAssertEqual(Int(store.reservationPlanDiff?.reduced.first?.newTotal ?? 0), 200)

        let cancelledDirect = try XCTUnwrap(try database.rows(named: "direct_booking", tenantID: "tenant-local").first { $0.id == "direct-b200" })
        XCTAssertEqual(cancelledDirect.values["status"], "cancelled")
        let activeReservations = try database.rows(.reservation, tenantID: "tenant-local")
        XCTAssertFalse(activeReservations.contains { $0.id == "reservation-direct-direct-b200" })

        let events = try database.rows(.eventLog, tenantID: "tenant-local").map { $0.values["type"] }
        XCTAssertTrue(events.contains("direct_booking.accepted"))
        XCTAssertTrue(events.contains("direct_booking.cancelled"))
        XCTAssertEqual(events.count(where: { $0 == "reservation.diffed" }), 2)
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

    func testForwardSliceCompletionPersistsDirectSignalsPassAndMultistore() throws {
        let database = try PrepFlowDatabase()
        let store = BoardStore(database: database)
        let booking = p35InboundDirectBooking()

        let decision = store.evaluateDirectAllotment(booking, allottedCovers: 1)
        XCTAssertEqual(decision.status, .request)
        XCTAssertEqual(decision.waitlistCovers, 4)
        let waitlist = try XCTUnwrap(try database.rows(named: "waitlist_entry", tenantID: "tenant-local").first { $0.id == "waitlist-direct-b300" })
        XCTAssertEqual(waitlist.values["status"], "waiting")

        let settlement = store.recordDirectNoShow(booking, forfeitsDeposit: true)
        XCTAssertEqual(settlement.status, .noshow)
        XCTAssertEqual(try database.rows(named: "direct_booking", tenantID: "tenant-local").first { $0.id == booking.id }?.values["status"], "noshow")

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
