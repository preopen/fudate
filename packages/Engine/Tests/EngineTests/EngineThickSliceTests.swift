import Engine
import XCTest

final class EngineThickSliceTests: XCTestCase {
    func testReservationImpactKeepsAddedAndCancelledEffects() {
        let task = PrepTask(
            id: "task-nikiri",
            scaleMode: .perCover,
            coeffPerCover: 14,
            roundStep: 10,
            unit: "ml",
            status: .done
        )
        let impact = reservationImpactPlan(
            task: task,
            previousCovers: 14,
            madeTotal: 200,
            diff: ReservationDiffSummary(
                addedCovers: 3,
                cancelledCovers: 2,
                changedReservationIDs: ["reservation-a", "reservation-b"]
            )
        )

        XCTAssertEqual(impact.added.first?.task, "task-nikiri")
        XCTAssertEqual(impact.added.first?.qty, 42)
        XCTAssertEqual(impact.reduced.first?.newCovers, 12)
        XCTAssertEqual(impact.reduced.first?.newTotal, 170)
        XCTAssertEqual(impact.reduced.first?.carryoverCandidate, true)
    }

    func testPromoteWaitlistAndOrderLarderFIFO() {
        let booking = DirectBooking(
            id: "direct-b300",
            visitTime: "18:00",
            covers: 2,
            course: "course-omakase",
            guestName: "Inbound Guest"
        )
        let blocked = promoteDirectWaitlist(
            booking,
            allotment: DirectAllotment(id: "allotment-1", serviceDayID: "service-1", slot: "18:00", allottedCovers: 6, bookedCovers: 5)
        )
        XCTAssertEqual(blocked.status, .request)
        XCTAssertEqual(blocked.reason, "insufficient_allotment")

        let promoted = promoteDirectWaitlist(
            booking,
            allotment: DirectAllotment(id: "allotment-2", serviceDayID: "service-1", slot: "18:00", allottedCovers: 6, bookedCovers: 4)
        )
        XCTAssertEqual(promoted.status, .confirmed)
        XCTAssertEqual(promoted.remainingAllotment, 0)

        let alerts = fifoLarder(thickLarderItems(), nowDate: "2026-06-12", alertWithinDays: 1)
        XCTAssertEqual(alerts.map(\.labelID), ["label-old", "label-due", "label-ok"])
        XCTAssertEqual(alerts.map(\.level), ["expired", "due", "ok"])
    }

    func testPlanLarderConsumptionUsesOldestValidLabelsAndReportsShortfall() {
        let plan = planLarderConsumption(
            thickLarderItems(),
            requiredQty: 130,
            unit: "ml",
            nowDate: "2026-06-12"
        )

        XCTAssertEqual(plan.uses.map(\.labelID), ["label-due", "label-ok"])
        XCTAssertEqual(plan.uses.map(\.qty), [40, 80])
        XCTAssertEqual(plan.plannedQty, 120)
        XCTAssertEqual(plan.shortfallQty, 10)
    }

    func testLearningWasteRecordsExcludeNonOvermadeReasons() {
        let records = [
            CloseTaskRecord(
                task: "task-nikiri",
                plannedQty: 200,
                madeQty: 240,
                leftoverQty: 40,
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
        ]

        let learning = learningWasteRecords(records: records, serviceDate: "2026-06-17", covers: 14)
        XCTAssertEqual(learning.map(\.exclude), [false, true])
        XCTAssertEqual(learning.map(\.leftover), [40, 2])
    }

    func testTodayPrepProgressPicksNextStepAndETA() {
        let progress = todayPrepProgress(
            steps: thickTodayPrepSteps(),
            completedIDs: ["sake"],
            now: "17:25",
            t0: "18:00"
        )

        XCTAssertEqual(progress.completedCount, 1)
        XCTAssertEqual(progress.totalCount, 3)
        XCTAssertEqual(progress.nextStepID, "tare")
        XCTAssertEqual(progress.remainingMinutes, 30)
        XCTAssertEqual(progress.eta.landing, "17:55")
        XCTAssertEqual(progress.eta.shortfallMin, 0)
    }

    func testTodayPrepUndoCapturesPreviousAndNextState() {
        let undo = todayPrepUndo(
            action: "toggle-tare",
            previousCompletedIDs: ["sake"],
            nextCompletedIDs: ["sake", "tare"]
        )

        XCTAssertEqual(undo.previousCompletedIDs, ["sake"])
        XCTAssertEqual(undo.nextCompletedIDs, ["sake", "tare"])
        XCTAssertEqual(undo.message, "toggle-tare を取り消せます")
    }

    func testTodayPrepCompletionCapturesOperatorAndCompletedIDs() {
        let completion = todayPrepCompletion(
            taskID: "tare",
            completedBy: "ガルド",
            checkedAt: "2026-06-17T17:25:00Z",
            previousCompletedIDs: ["sake"]
        )

        XCTAssertEqual(completion.taskID, "tare")
        XCTAssertEqual(completion.completedBy, "ガルド")
        XCTAssertEqual(completion.checkedAt, "2026-06-17T17:25:00Z")
        XCTAssertEqual(completion.completedIDs, ["sake", "tare"])
    }

    func testTodayPrepOperatorWorkloadSummarizesAssignmentsAndActiveStep() {
        let workload = todayPrepOperatorWorkload(
            operators: thickTodayPrepOperators(),
            steps: thickTodayPrepSteps(),
            completedIDs: ["sake"],
            stepAssignments: [
                "sake": "operator-oyakata",
                "tare": "operator-oyakata",
                "rest": "operator-garde",
            ],
            activeStepID: "tare"
        )

        XCTAssertEqual(workload.map(\.operatorID), ["operator-oyakata", "operator-garde"])
        XCTAssertEqual(workload[0].assignedCount, 2)
        XCTAssertEqual(workload[0].completedCount, 1)
        XCTAssertEqual(workload[0].remainingMinutes, 15)
        XCTAssertEqual(workload[0].nextStepID, "tare")
        XCTAssertEqual(workload[0].activeStepID, "tare")
        XCTAssertEqual(workload[0].statusText, "作業中: たまり・濃口を合わせる")
        XCTAssertEqual(workload[1].remainingMinutes, 15)
        XCTAssertEqual(workload[1].statusText, "次: 味見基準を確認")
    }

    func testTodayPrepActualCapturesElapsedMinutesAndVariance() {
        let actual = todayPrepActual(
            taskID: "tare",
            plannedMinutes: 15,
            startedAt: "17:25",
            checkedAt: "17:42"
        )

        XCTAssertEqual(actual.taskID, "tare")
        XCTAssertEqual(actual.plannedMinutes, 15)
        XCTAssertEqual(actual.actualMinutes, 17)
        XCTAssertEqual(actual.varianceMinutes, 2)
        XCTAssertEqual(actual.startedAt, "17:25")
        XCTAssertEqual(actual.checkedAt, "17:42")
    }

    func testTodayPrepActualOverrideAndHoldResume() {
        let adjusted = todayPrepActualOverride(
            taskID: "tare",
            plannedMinutes: 15,
            actualMinutes: 13,
            startedAt: "17:25",
            checkedAt: "17:42"
        )
        XCTAssertEqual(adjusted.actualMinutes, 13)
        XCTAssertEqual(adjusted.varianceMinutes, -2)

        let hold = todayPrepHold(stepID: "tare", reason: "火入れ待ち", pausedAt: "17:31")
        XCTAssertTrue(hold.isActive)
        XCTAssertEqual(hold.reason, "火入れ待ち")

        let resumed = todayPrepResume(hold, resumedAt: "17:36")
        XCTAssertFalse(resumed.isActive)
        XCTAssertEqual(resumed.pausedAt, "17:31")
        XCTAssertEqual(resumed.resumedAt, "17:36")
    }

    func testTodayPrepReadinessRequiresAllChecks() {
        let checks = [
            TodayPrepCheck(id: "check-tare-boil", stepID: "tare", title: "ひと煮立ち", detail: "沸いたら火を落とす"),
            TodayPrepCheck(id: "check-tare-clear", stepID: "tare", title: "濁りなし", detail: "泡を取る"),
        ]
        let partial = todayPrepReadiness(checks: checks, completedCheckIDs: ["check-tare-boil"])

        XCTAssertEqual(partial.stepID, "tare")
        XCTAssertEqual(partial.requiredCount, 2)
        XCTAssertEqual(partial.completedCount, 1)
        XCTAssertEqual(partial.remainingTitles, ["濁りなし"])
        XCTAssertFalse(partial.canComplete)

        let ready = todayPrepReadiness(
            checks: checks,
            completedCheckIDs: ["check-tare-boil", "check-tare-clear"]
        )
        XCTAssertTrue(ready.canComplete)
    }

    func testTodayPrepAssistProposalAppearsOnlyWhenLate() {
        let onTrack = todayPrepProgress(
            steps: thickTodayPrepSteps(),
            completedIDs: ["sake"],
            now: "17:25",
            t0: "18:00"
        )
        XCTAssertNil(todayPrepAssistProposal(progress: onTrack, operators: thickTodayPrepOperators()))

        let late = todayPrepProgress(
            steps: thickTodayPrepSteps(),
            completedIDs: ["sake"],
            now: "17:45",
            t0: "18:00"
        )
        let proposal = todayPrepAssistProposal(progress: late, operators: thickTodayPrepOperators())

        XCTAssertEqual(proposal?.title, "応援を呼ぶ")
        XCTAssertEqual(proposal?.suggestedOperatorID, "operator-garde")
        XCTAssertEqual(proposal?.shortfallMinutes, 15)
        XCTAssertEqual(proposal?.savesMinutes, 10)
    }

    func testDedupeServiceReplayAndAggregateStores() {
        let replay = replayServiceEvents(
            plannedCovers: 18,
            events: [
                ServiceSyncEvent(id: "svc-fire", source: .kds, kind: .fire, covers: 4, occurredAt: "2026-06-17T10:00:00Z"),
                ServiceSyncEvent(id: "svc-fire", source: .kds, kind: .fire, covers: 4, occurredAt: "2026-06-17T10:00:01Z"),
                ServiceSyncEvent(id: "svc-served", source: .pos, kind: .served, covers: 8, occurredAt: "2026-06-17T10:10:00Z"),
            ],
            elapsedMinutes: 60,
            serviceMinutes: 120
        )

        XCTAssertEqual(replay.acceptedEventIDs, ["svc-fire", "svc-served"])
        XCTAssertEqual(replay.ignoredDuplicateEventIDs, ["svc-fire"])
        XCTAssertEqual(replay.state.firedCovers, 4)
        XCTAssertEqual(replay.state.servedCovers, 8)
        XCTAssertEqual(replay.state.remainingCovers, 10)

        let summary = multistoreServiceSummary([
            StoreServiceSummary(id: "store-a", restaurantName: "鮨 はやし", serviceDate: "2026-06-17", remainingCovers: 10, recommendation: "keep"),
            StoreServiceSummary(id: "store-b", restaurantName: "鮨 青", serviceDate: "2026-06-17", remainingCovers: 6, recommendation: "fire"),
        ])
        XCTAssertEqual(summary.remainingCovers, 16)
        XCTAssertEqual(summary.recommendation, "fire")
    }
}

private func thickTodayPrepOperators() -> [TodayPrepOperator] {
    [
        TodayPrepOperator(id: "operator-oyakata", displayName: "親方", sectionName: "親方"),
        TodayPrepOperator(id: "operator-garde", displayName: "ガルド", sectionName: "ガルド"),
    ]
}

private func thickTodayPrepSteps() -> [TodayPrepStep] {
    [
        TodayPrepStep(id: "sake", title: "酒・みりんを煮切る", durationMin: 10),
        TodayPrepStep(id: "tare", title: "たまり・濃口を合わせる", durationMin: 15),
        TodayPrepStep(id: "rest", title: "味見基準を確認", durationMin: 15),
    ]
}

private func thickLarderItems() -> [PrepLarderItem] {
    [
        PrepLarderItem(
            id: "larder-ok",
            labelID: "label-ok",
            prepTaskID: "task-nikiri",
            qty: 80,
            unit: "ml",
            expireAt: "2026-06-15T23:59:00Z",
            status: .available
        ),
        PrepLarderItem(
            id: "larder-old",
            labelID: "label-old",
            prepTaskID: "task-nikiri",
            qty: 20,
            unit: "ml",
            expireAt: "2026-06-11T23:59:00Z",
            status: .available
        ),
        PrepLarderItem(
            id: "larder-used",
            labelID: "label-used",
            prepTaskID: "task-nikiri",
            qty: 30,
            unit: "ml",
            expireAt: "2026-06-10T23:59:00Z",
            status: .used
        ),
        PrepLarderItem(
            id: "larder-due",
            labelID: "label-due",
            prepTaskID: "task-nikiri",
            qty: 40,
            unit: "ml",
            expireAt: "2026-06-13T23:59:00Z",
            status: .available
        ),
    ]
}
