import Engine
import Foundation
import XCTest

final class EngineGoldenTests: XCTestCase {
    func testCalcQtyGoldenCases() throws {
        for testCase in try goldenCases("calc_qty") {
            var input = try XCTUnwrap(testCase["input"] as? [String: Any])
            let covers = try int(input.removeValue(forKey: "covers"))
            input["id"] = try string(testCase["name"])
            let task = try decode(PrepTask.self, from: input)
            let quantity = calcQty(task, covers: covers)
            let expect = try XCTUnwrap(testCase["expect"] as? [String: Any])

            if let raw = expect["raw"] {
                try assertEqual(quantity.raw, raw, accuracy: 1e-6)
            }
            try assertEqual(quantity.total, expect["total"], accuracy: 1e-6)
            XCTAssertEqual(quantity.batches, expect["batches"] as? Int)
            XCTAssertEqual(quantity.unit, try string(expect["unit"]))
        }
    }

    func testAggregateSubrecipesGoldenCases() throws {
        for testCase in try goldenCases("aggregate_subrecipes") {
            let input = try XCTUnwrap(testCase["input"] as? [String: Any])
            let subrecipe = try decode(PrepTask.self, from: XCTUnwrap(input["subrecipe"] as? [String: Any]))
            let references = try (XCTUnwrap(input["references"] as? [[String: Any]])).map {
                try (course: string($0["course"]), covers: int($0["covers"]))
            }
            let result = aggregateSubrecipes(subrecipe, references: references)
            let expect = try XCTUnwrap(testCase["expect"] as? [String: Any])

            XCTAssertEqual(result.task, try string(expect["task"]))
            XCTAssertEqual(result.totalCovers, try int(expect["total_covers"]))
            if let raw = expect["raw"] {
                try assertEqual(result.quantity.raw, raw, accuracy: 1e-6)
            }
            try assertEqual(result.quantity.total, expect["total"], accuracy: 1e-6)
            XCTAssertEqual(result.quantity.batches, expect["batches"] as? Int)
            XCTAssertEqual(result.quantity.unit, try string(expect["unit"]))
            XCTAssertEqual(result.sources, try XCTUnwrap(expect["sources"] as? [String]))
        }
    }

    func testDiffPlanGoldenCases() throws {
        for testCase in try goldenCases("diff_plan") {
            let input = try XCTUnwrap(testCase["input"] as? [String: Any])
            let taskInput = try XCTUnwrap(input["task"] as? [String: Any])
            let task = try decode(PrepTask.self, from: taskInput)
            let changeInput = try XCTUnwrap(input["change"] as? [String: Any])
            let change = try decodePlanChange(changeInput)
            let madeTotal = try optionalDouble(input["made_total"] ?? taskInput["made_total"])
            let diff = diffPlan(
                task: task,
                currentCovers: input["current_covers"] as? Int,
                madeTotal: madeTotal,
                change: change
            )
            let expect = try XCTUnwrap(testCase["expect"] as? [String: Any])

            let expectedAdded = try XCTUnwrap(expect["added"] as? [[String: Any]])
            let expectedReduced = try XCTUnwrap(expect["reduced"] as? [[String: Any]])
            XCTAssertEqual(diff.added.count, expectedAdded.count)
            XCTAssertEqual(diff.reduced.count, expectedReduced.count)

            for (actual, expected) in zip(diff.added, expectedAdded) {
                XCTAssertEqual(actual.task, try string(expected["task"]))
                if let qty = expected["qty"] {
                    try assertEqual(XCTUnwrap(actual.qty), qty, accuracy: 1e-6)
                }
                XCTAssertEqual(actual.reason.rawValue, try string(expected["reason"]))
                XCTAssertEqual(actual.belowThreshold, expected["below_threshold"] as? Bool)
            }

            for (actual, expected) in zip(diff.reduced, expectedReduced) {
                XCTAssertEqual(actual.task, try string(expected["task"]))
                try assertEqual(actual.rawDelta, expected["raw_delta"], accuracy: 1e-6)
                XCTAssertEqual(actual.newCovers, try int(expected["new_covers"]))
                try assertEqual(actual.newTotal, expected["new_total"], accuracy: 1e-6)
                XCTAssertEqual(actual.carryoverCandidate, try bool(expected["carryover_candidate"]))
            }
        }
    }

    func testScheduleGoldenCases() throws {
        for testCase in try goldenCases("schedule") {
            let input = try XCTUnwrap(testCase["input"] as? [String: Any])
            let task = try decode(PrepTask.self, from: XCTUnwrap(input["task"] as? [String: Any]))
            let calendar = input["calendar"] as? [String: Any]
            let closedDates = Set(calendar?["closed_dates"] as? [String] ?? [])
            let result = try schedule(
                task: task,
                serviceDate: string(input["service_date"]),
                t0: string(input["T0"]),
                closedDates: closedDates
            )
            let expect = try XCTUnwrap(testCase["expect"] as? [String: Any])

            XCTAssertEqual(result.prepDayOffset, try int(expect["prep_day_offset"]))
            XCTAssertEqual(result.prepDate, expect["prep_date"] as? String)
            XCTAssertEqual(result.start, try string(expect["start"]))
            XCTAssertEqual(result.finish, try string(expect["finish"]))
            XCTAssertEqual(result.skipped, expect["skipped"] as? [String] ?? [])
        }
    }

    func testRollupGoldenCases() throws {
        for testCase in try goldenCases("rollup") {
            let input = try XCTUnwrap(testCase["input"] as? [String: Any])
            let tree = try decode(TaskNode.self, from: XCTUnwrap(input["tree"] as? [String: Any]))
            let result = rollup(tree)
            let statuses = flattenStatuses(result)
            let expect = try XCTUnwrap(testCase["expect"] as? [String: String])
            for (id, status) in expect {
                XCTAssertEqual(statuses[id]?.goldenRawValue, status)
            }
        }
    }

    func testETAProjectionGoldenCases() throws {
        for testCase in try goldenCases("eta_projection") {
            let input = try XCTUnwrap(testCase["input"] as? [String: Any])
            let remainingTasks = try XCTUnwrap(input["remaining_tasks"] as? [[String: Any]])
            let durations = try remainingTasks.map { try int($0["duration_min"]) }
            let result = try etaProjection(now: string(input["now"]), t0: string(input["T0"]), remainingDurationsMin: durations)
            let expect = try XCTUnwrap(testCase["expect"] as? [String: Any])

            XCTAssertEqual(result.landing, try string(expect["landing"]))
            XCTAssertEqual(result.delayMin, try int(expect["delay_min"]))
            XCTAssertEqual(result.timeToOpenMin, try int(expect["time_to_open_min"]))
            XCTAssertEqual(result.shortfallMin, try int(expect["shortfall_min"]))
            XCTAssertEqual(result.status.rawValue, try string(expect["status"]))
        }
    }

    func testSelfCorrectGoldenCases() throws {
        for testCase in try goldenCases("self_correct") {
            let input = try XCTUnwrap(testCase["input"] as? [String: Any])
            let history = try decode([WasteRecord].self, from: XCTUnwrap(input["history"] as? [[String: Any]]))
            let config = try XCTUnwrap(input["config"] as? [String: Any])
            let result = try selfCorrect(
                taskId: string(input["task_id"]),
                currentCoeffPerCover: double(input["current_coeff_per_cover"]),
                history: history,
                lookback: int(config["lookback"])
            )
            let expect = try XCTUnwrap(testCase["expect"] as? [String: Any])

            XCTAssertEqual(result.taskId, try string(input["task_id"]))
            try assertEqual(result.current, expect["current_coeff_per_cover"], accuracy: 1e-6)
            try assertEqual(result.suggested, expect["suggested_coeff_per_cover"], accuracy: 1e-6)
            XCTAssertEqual(result.samplesUsed, try int(expect["samples_used"]))
        }
    }

    func testApplyCarryoverGoldenCases() throws {
        for testCase in try goldenCases("apply_carryover") {
            let input = try XCTUnwrap(testCase["input"] as? [String: Any])
            let plan = try (XCTUnwrap(input["plan"] as? [[String: Any]])).map {
                try (task: string($0["task"]), base: double($0["base_recommended"]), unit: string($0["unit"]))
            }
            let leftovers = try (XCTUnwrap(input["leftovers"] as? [[String: Any]])).map {
                try (task: string($0["task"]), qty: double($0["qty"]), expired: bool($0["expired"]))
            }
            let result = applyCarryover(plan: plan, leftovers: leftovers)
            let expected = try XCTUnwrap(try (XCTUnwrap(testCase["expect"] as? [String: Any]))["adjusted"] as? [[String: Any]])

            XCTAssertEqual(result.count, expected.count)
            for (actual, expectedItem) in zip(result, expected) {
                XCTAssertEqual(actual.task, try string(expectedItem["task"]))
                try assertEqual(actual.adjusted, expectedItem["adjusted_recommended"], accuracy: 1e-6)
                XCTAssertEqual(actual.unit, try string(expectedItem["unit"]))
            }
        }
    }
}

private func goldenCases(_ name: String) throws -> [[String: Any]] {
    let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "golden"))
    let data = try Data(contentsOf: url)
    let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    return try XCTUnwrap(root["cases"] as? [[String: Any]])
}

private func decode<T: Decodable>(_: T.Type, from object: Any) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: object)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(T.self, from: data)
}

private func decodePlanChange(_ input: [String: Any]) throws -> PlanChange {
    let type = try string(input["type"])
    switch type {
    case "reservation_added":
        return try .reservationAdded(deltaCovers: int(input["delta_covers"]), course: string(input["course"]))
    case "reservation_cancelled":
        return try .reservationCancelled(deltaCovers: int(input["delta_covers"]), course: string(input["course"]))
    case "par_depleted":
        return try .parDepleted(remainingQty: double(input["remaining_qty"]), thresholdPct: double(input["threshold_pct"]))
    default:
        throw NSError(domain: "EngineGoldenTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown change type \(type)"])
    }
}

private func flattenStatuses(_ node: TaskNode) -> [String: TaskStatus] {
    var result: [String: TaskStatus] = [node.id: node.status ?? .notStarted]
    for child in node.children {
        result.merge(flattenStatuses(child)) { current, _ in current }
    }
    return result
}

private extension TaskStatus {
    var goldenRawValue: String {
        switch self {
        case .notStarted:
            "not_started"
        case .inProgress:
            "in_progress"
        case .done:
            "done"
        }
    }
}

private func assertEqual(_ actual: Double, _ expected: Any?, accuracy: Double, file: StaticString = #filePath, line: UInt = #line) throws {
    XCTAssertEqual(actual, try double(expected), accuracy: accuracy, file: file, line: line)
}

private func string(_ value: Any?, file: StaticString = #filePath, line: UInt = #line) throws -> String {
    try XCTUnwrap(value as? String, file: file, line: line)
}

private func int(_ value: Any?, file: StaticString = #filePath, line: UInt = #line) throws -> Int {
    if let value = value as? Int {
        return value
    }
    if let value = value as? NSNumber {
        return value.intValue
    }
    return try XCTUnwrap(nil, "Expected Int", file: file, line: line)
}

private func double(_ value: Any?, file: StaticString = #filePath, line: UInt = #line) throws -> Double {
    if let value = value as? Double {
        return value
    }
    if let value = value as? Int {
        return Double(value)
    }
    if let value = value as? NSNumber {
        return value.doubleValue
    }
    return try XCTUnwrap(nil, "Expected Double", file: file, line: line)
}

private func optionalDouble(_ value: Any?) throws -> Double? {
    guard let value else { return nil }
    return try double(value)
}

private func bool(_ value: Any?, file: StaticString = #filePath, line: UInt = #line) throws -> Bool {
    if let value = value as? Bool {
        return value
    }
    if let value = value as? NSNumber {
        return value.boolValue
    }
    return try XCTUnwrap(nil, "Expected Bool", file: file, line: line)
}
