import Foundation
@testable import SyncSpike
import XCTest

final class SyncSpikeTests: XCTestCase {
    private let tenantID = "tenant-hayashi"
    private let taskID = "task-nikiri"

    func testTwoReplicasExchangeCheckoffWithinTwoSeconds() async throws {
        let hub = SyncHub()
        let deviceA = try makeReplica("ipad-a")
        let deviceB = try makeReplica("ipad-b")
        try await seed([deviceA, deviceB], hub: hub)

        let clock = ContinuousClock()
        let elapsed = try await clock.measure {
            try deviceA.markDone(taskID: taskID, at: 1000)
            try await deviceA.sync(with: hub, at: 1001)
            try await deviceB.sync(with: hub, at: 1002)
        }

        XCTAssertEqual(try deviceB.taskStatus(taskID: taskID), .done)
        XCTAssertLessThan(elapsed, .seconds(2))
    }

    func testOfflineThirtyMinutesThenReconnectMergesWithoutLoss() async throws {
        let hub = SyncHub()
        let offlineDevice = try makeReplica("ipad-offline")
        let onlineDevice = try makeReplica("ipad-online")
        try await seed([offlineDevice, onlineDevice], hub: hub)

        try offlineDevice.markDone(taskID: taskID, at: 2000)
        try offlineDevice.setMadeQuantity(taskID: taskID, madeQty: 190, at: 2000)
        XCTAssertEqual(try offlineDevice.taskStatus(taskID: taskID), .done)
        XCTAssertEqual(try offlineDevice.pendingOutboxCount(), 2)

        try onlineDevice.setMadeQuantity(taskID: taskID, madeQty: 180, at: 2100)
        try await onlineDevice.sync(with: hub, at: 2101)

        let reconnectAfterThirtyMinutes = Int64(2000 + 30 * 60)
        try offlineDevice.setMadeQuantity(taskID: taskID, madeQty: 205, at: reconnectAfterThirtyMinutes)
        try await offlineDevice.sync(with: hub, at: reconnectAfterThirtyMinutes + 1)
        try await onlineDevice.sync(with: hub, at: reconnectAfterThirtyMinutes + 2)

        XCTAssertEqual(try onlineDevice.taskStatus(taskID: taskID), .done)
        XCTAssertEqual(try offlineDevice.pendingOutboxCount(), 0)
        XCTAssertEqual(try onlineDevice.quantity(taskID: taskID)?.madeQty, 205)
        XCTAssertEqual(try onlineDevice.quantityHistoryCount(taskID: taskID), 3)
    }

    func testDuplicateCheckoffIsIdempotent() async throws {
        let hub = SyncHub()
        let device = try makeReplica("ipad-a")
        try await seed([device], hub: hub)

        try device.markDone(taskID: taskID, at: 3000)
        try device.markDone(taskID: taskID, at: 3000)
        try await device.sync(with: hub, at: 3001)

        XCTAssertEqual(try device.taskStatus(taskID: taskID), .done)
        XCTAssertEqual(try device.pendingOutboxCount(), 0)
    }

    func testLocalBoardWritesStayImmediateOffline() throws {
        let device = try makeReplica("ipad-legacy")
        try device.seed(taskID: taskID, at: 4000)

        let clock = ContinuousClock()
        let elapsed = try clock.measure {
            for index in 0 ..< 100 {
                try device.markDone(taskID: "\(taskID)-\(index)", at: Int64(4000 + index))
            }
        }

        XCTAssertEqual(try device.taskStatus(taskID: "\(taskID)-99"), .done)
        XCTAssertLessThan(elapsed, .seconds(1))
    }

    private func seed(_ replicas: [LocalReplica], hub: SyncHub) async throws {
        let task = TaskSnapshot(
            id: taskID,
            tenantID: tenantID,
            status: .notStarted,
            checkedAt: nil,
            updatedAt: 1,
            updatedBy: "seed"
        )

        await hub.seed(task: task)
        for replica in replicas {
            try replica.seed(taskID: taskID, at: 1)
        }
    }

    private func makeReplica(_ deviceID: String) throws -> LocalReplica {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("prepflow-sync-spike-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try LocalReplica(
            path: directory.appendingPathComponent("replica.sqlite").path,
            tenantID: tenantID,
            deviceID: deviceID
        )
    }
}
