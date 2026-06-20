public func todayPrepProgress(steps: [TodayPrepStep], completedIDs: Set<String>, now: String, t0: String) -> TodayPrepProgress {
    let resolved = steps.map { step in
        TodayPrepStep(
            id: step.id,
            title: step.title,
            durationMin: step.durationMin,
            isDone: completedIDs.contains(step.id)
        )
    }
    let remaining = resolved.filter { !$0.isDone }
    let eta = etaProjection(now: now, t0: t0, remainingDurationsMin: remaining.map(\.durationMin))
    return TodayPrepProgress(
        steps: resolved,
        completedCount: resolved.count { $0.isDone },
        totalCount: resolved.count,
        nextStepID: remaining.first?.id,
        nextStepTitle: remaining.first?.title,
        remainingMinutes: remaining.reduce(0) { $0 + $1.durationMin },
        eta: eta
    )
}

public func todayPrepUndo(action: String, previousCompletedIDs: Set<String>, nextCompletedIDs: Set<String>) -> TodayPrepUndo {
    TodayPrepUndo(
        id: "undo-\(action)",
        action: action,
        previousCompletedIDs: previousCompletedIDs.sorted(),
        nextCompletedIDs: nextCompletedIDs.sorted(),
        message: "\(action) を取り消せます"
    )
}

public func todayPrepCompletion(
    taskID: String,
    completedBy operatorName: String,
    checkedAt: String,
    previousCompletedIDs: Set<String>
) -> TodayPrepCompletion {
    var completedIDs = previousCompletedIDs
    completedIDs.insert(taskID)
    return TodayPrepCompletion(
        taskID: taskID,
        completedBy: operatorName,
        checkedAt: checkedAt,
        completedIDs: completedIDs.sorted()
    )
}

public func todayPrepOperatorWorkload(
    operators: [TodayPrepOperator],
    steps: [TodayPrepStep],
    completedIDs: Set<String>,
    stepAssignments: [String: String],
    activeStepID: String? = nil
) -> [TodayPrepOperatorWorkload] {
    operators.map { operatorValue in
        let assignedSteps = steps.filter { stepAssignments[$0.id] == operatorValue.id }
        let remainingSteps = assignedSteps.filter { !completedIDs.contains($0.id) }
        let activeStep = activeStepID.flatMap { id in
            assignedSteps.first { $0.id == id && !completedIDs.contains($0.id) }
        }
        let nextStep = remainingSteps.first
        let completedCount = assignedSteps.count - remainingSteps.count
        let remainingMinutes = remainingSteps.reduce(0) { $0 + max(0, $1.durationMin) }
        let statusText = if let activeStep {
            "作業中: \(activeStep.title)"
        } else if let nextStep {
            "次: \(nextStep.title)"
        } else if assignedSteps.isEmpty {
            "割当なし"
        } else {
            "担当分完了"
        }

        return TodayPrepOperatorWorkload(
            id: "workload-\(operatorValue.id)",
            operatorID: operatorValue.id,
            displayName: operatorValue.displayName,
            sectionName: operatorValue.sectionName,
            assignedCount: assignedSteps.count,
            completedCount: completedCount,
            remainingMinutes: remainingMinutes,
            nextStepID: nextStep?.id,
            nextStepTitle: nextStep?.title,
            activeStepID: activeStep?.id,
            activeStepTitle: activeStep?.title,
            statusText: statusText
        )
    }
}

public func todayPrepActual(taskID: String, plannedMinutes: Int, startedAt: String, checkedAt: String) -> TodayPrepActual {
    let actualMinutes = max(0, minutes(fromHHMM: checkedAt) - minutes(fromHHMM: startedAt))
    return TodayPrepActual(
        id: "actual-\(taskID)",
        taskID: taskID,
        plannedMinutes: plannedMinutes,
        actualMinutes: actualMinutes,
        varianceMinutes: actualMinutes - plannedMinutes,
        startedAt: startedAt,
        checkedAt: checkedAt
    )
}

public func todayPrepActualOverride(taskID: String, plannedMinutes: Int, actualMinutes: Int, startedAt: String, checkedAt: String) -> TodayPrepActual {
    let resolvedActual = max(0, actualMinutes)
    return TodayPrepActual(
        id: "actual-\(taskID)",
        taskID: taskID,
        plannedMinutes: plannedMinutes,
        actualMinutes: resolvedActual,
        varianceMinutes: resolvedActual - plannedMinutes,
        startedAt: startedAt,
        checkedAt: checkedAt
    )
}

public func todayPrepHold(stepID: String, reason: String, pausedAt: String) -> TodayPrepHold {
    TodayPrepHold(
        id: "hold-\(stepID)-\(pausedAt)",
        stepID: stepID,
        reason: reason,
        pausedAt: pausedAt
    )
}

public func todayPrepResume(_ hold: TodayPrepHold, resumedAt: String) -> TodayPrepHold {
    TodayPrepHold(
        id: hold.id,
        stepID: hold.stepID,
        reason: hold.reason,
        pausedAt: hold.pausedAt,
        resumedAt: resumedAt
    )
}

public func todayPrepReadiness(checks: [TodayPrepCheck], completedCheckIDs: Set<String>) -> TodayPrepReadiness {
    let remaining = checks.filter { !completedCheckIDs.contains($0.id) }
    return TodayPrepReadiness(
        stepID: checks.first?.stepID,
        requiredCount: checks.count,
        completedCount: checks.count - remaining.count,
        remainingTitles: remaining.map(\.title)
    )
}

public func todayPrepAssistProposal(progress: TodayPrepProgress, operators: [TodayPrepOperator]) -> TodayPrepAssistProposal? {
    guard !progress.isComplete, progress.eta.shortfallMin > 0 else {
        return nil
    }

    let helper = operators.dropFirst().first ?? operators.first
    let savesMinutes = min(max(progress.eta.shortfallMin, 5), 10)
    let helperName = helper?.displayName ?? "手空き担当"
    let nextStep = progress.nextStepTitle ?? "次工程"
    return TodayPrepAssistProposal(
        id: "assist-\(progress.nextStepID ?? "next")",
        title: "応援を呼ぶ",
        detail: "\(nextStep)を\(helperName)へ渡すと約\(savesMinutes)分短縮できます。",
        actionLabel: "\(helperName)へ割当",
        suggestedOperatorID: helper?.id,
        suggestedOperatorName: helperName,
        savesMinutes: savesMinutes,
        shortfallMinutes: progress.eta.shortfallMin
    )
}
