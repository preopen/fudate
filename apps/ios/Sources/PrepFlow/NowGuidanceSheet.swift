// 正本: design/p0-wireframe-board-liquidglass.png
import DesignTokens
import Engine
import SwiftUI

// 正本: design/p0-wireframe-board-liquidglass.png
struct NowGuidanceSheet: View {
    let title: String
    let bodyText: String
    let progress: TodayPrepProgress
    let operators: [TodayPrepOperator]
    let selectedOperatorID: String
    let assistProposal: TodayPrepAssistProposal?
    let activeStartedAt: String?
    let actuals: [String: TodayPrepActual]
    let activeChecks: [TodayPrepCheck]
    let completedCheckIDs: Set<String>
    let readiness: TodayPrepReadiness
    let completionBlockReason: String
    let activeHold: TodayPrepHold?
    let holdHistory: [TodayPrepHold]
    let impactItems: [TodayPrepImpactItem]
    let impactLastAction: String
    let canUndo: Bool
    let completeNext: () -> Void
    let undo: () -> Void
    let selectOperator: (String) -> Void
    let startNext: () -> Void
    let toggleCheck: (String) -> Void
    let completeChecks: () -> Void
    let requestAssist: () -> Void
    let applyAssist: () -> Void
    let pause: (String) -> Void
    let resume: () -> Void
    let adjustActual: (String, Int) -> Void
    let applyImpact: (String) -> Void
    let dismissImpact: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.lg) {
            Capsule(style: .continuous)
                .fill(PrepFlowColor.g4)
                .frame(width: PrepFlowMetric.actionButtonHeight, height: PrepFlowMetric.lineWidth)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                Text("手順・動画")
                    .font(PrepFlowFont.sectionTitle)
                    .foregroundStyle(PrepFlowColor.g2)
                Text(title)
                    .font(PrepFlowFont.focusTitle)
                    .foregroundStyle(PrepFlowColor.ink)
                Text(bodyText)
                    .font(PrepFlowFont.body)
                    .foregroundStyle(PrepFlowColor.g2)
            }

            HStack(spacing: PrepFlowSpacing.sm) {
                GuidanceChip(text: "\(progress.completedCount) / \(progress.totalCount)", isPrimary: true)
                GuidanceChip(text: "残り \(progress.remainingMinutes)分", isPrimary: false)
                GuidanceChip(text: "着地 \(progress.eta.landing)", isPrimary: false)
                if let activeStartedAt {
                    GuidanceChip(text: "着手 \(activeStartedAt)", isPrimary: false)
                }
            }

            GuidanceWorkStatePanel(
                progress: progress,
                activeHold: activeHold,
                holdHistory: holdHistory,
                pause: pause,
                resume: resume
            )

            if !impactItems.isEmpty || impactLastAction != "外部変化なし" {
                TodayPrepImpactPanel(
                    items: impactItems,
                    lastAction: impactLastAction,
                    apply: applyImpact,
                    dismiss: dismissImpact
                )
            }

            VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                Text("完了者")
                    .font(PrepFlowFont.sectionTitle)
                    .foregroundStyle(PrepFlowColor.g2)
                HStack(spacing: PrepFlowSpacing.sm) {
                    ForEach(operators) { operatorModel in
                        Button {
                            selectOperator(operatorModel.id)
                        } label: {
                            OperatorChip(
                                name: operatorModel.displayName,
                                section: operatorModel.sectionName,
                                isSelected: operatorModel.id == selectedOperatorID
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !activeChecks.isEmpty {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                    HStack {
                        Text("確認項目")
                            .font(PrepFlowFont.sectionTitle)
                            .foregroundStyle(PrepFlowColor.g2)
                        Spacer()
                        Text("\(readiness.completedCount) / \(readiness.requiredCount)")
                            .font(PrepFlowFont.countdownLabel)
                            .foregroundStyle(PrepFlowColor.g2)
                            .monospacedDigit()
                    }

                    HStack(spacing: PrepFlowSpacing.sm) {
                        ForEach(activeChecks) { check in
                            Button {
                                toggleCheck(check.id)
                            } label: {
                                GuidanceCheckRow(
                                    check: check,
                                    isDone: completedCheckIDs.contains(check.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    GuidanceReadinessGate(
                        readiness: readiness,
                        blockReason: completionBlockReason,
                        completeChecks: completeChecks
                    )
                }
            }

            VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
                ForEach(progress.steps) { step in
                    GuidanceStepRow(
                        step: step,
                        actual: actuals[step.id],
                        adjustActual: { delta in
                            adjustActual(step.id, delta)
                        }
                    )
                }
            }

            if let assistProposal {
                AssistProposalCard(proposal: assistProposal, applyAssist: applyAssist)
            }

            HStack(spacing: PrepFlowSpacing.md) {
                Button("取り消す", action: undo)
                    .buttonStyle(SheetSecondaryButtonStyle(isEnabled: canUndo))
                    .disabled(!canUndo)
                Button(activeStartedAt == nil ? "着手" : "着手中", action: startNext)
                    .buttonStyle(SheetSecondaryButtonStyle(isEnabled: activeStartedAt == nil && !progress.isComplete))
                    .disabled(activeStartedAt != nil || progress.isComplete)
                Button("遅れ確認", action: requestAssist)
                    .buttonStyle(SheetSecondaryButtonStyle(isEnabled: !progress.isComplete))
                    .disabled(progress.isComplete)
                Button(progress.isComplete ? "ライン点検へ" : "次を完了", action: completeNext)
                    .buttonStyle(SheetPrimaryButtonStyle(isComplete: progress.isComplete, isEnabled: readiness.canComplete))
                    .disabled(progress.isComplete || !readiness.canComplete)
            }
        }
        .padding(PrepFlowSpacing.xl)
        .background(PrepFlowColor.g5)
        .presentationDetents([.medium])
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct TodayPrepImpactPanel: View {
    let items: [TodayPrepImpactItem]
    let lastAction: String
    let apply: (String) -> Void
    let dismiss: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("外部変化")
                        .font(PrepFlowFont.sectionTitle)
                        .foregroundStyle(PrepFlowColor.g2)
                    Text(lastAction)
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(items.contains(where: \.isUrgent) ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: urgent prep impact before service
                }
                Spacer()
                Text("\(items.count)")
                    .font(PrepFlowFont.railTitle)
                    .foregroundStyle(items.isEmpty ? PrepFlowColor.ink : PrepFlowColor.time) // time-use: unresolved prep impact count
                    .monospacedDigit()
            }

            ForEach(items.prefix(PrepFlowLayout.impactPreviewLimit)) { item in
                TodayPrepImpactRow(item: item, apply: apply, dismiss: dismiss)
            }
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(
                    items.isEmpty ? PrepFlowColor.g4 : PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke), // time-use: unresolved impact panel border
                    lineWidth: PrepFlowMetric.lineWidth
                ) // time-use: unresolved impact panel border
        }
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct TodayPrepImpactRow: View {
    let item: TodayPrepImpactItem
    let apply: (String) -> Void
    let dismiss: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack(spacing: PrepFlowSpacing.sm) {
                Text(item.sourceLabel)
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(item.isUrgent ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: urgent impact source
                    .padding(.horizontal, PrepFlowSpacing.sm)
                    .padding(.vertical, PrepFlowSpacing.xxs)
                    .background(item.isUrgent ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeNow) : PrepFlowColor.g5) // time-use: urgent impact row background
                    .clipShape(Capsule(style: .continuous))
                Text(item.title)
                    .font(PrepFlowFont.smallBold)
                Spacer()
            }

            Text(item.detail)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
                .lineLimit(2)

            HStack(spacing: PrepFlowSpacing.xs) {
                Button("後で") {
                    dismiss(item.id)
                }
                .buttonStyle(MiniImpactButtonStyle(isPrimary: false))
                Button(item.actionLabel) {
                    apply(item.id)
                }
                .buttonStyle(MiniImpactButtonStyle(isPrimary: true))
            }
        }
        .padding(PrepFlowSpacing.xs)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

private struct MiniImpactButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.countdownLabel)
            .foregroundStyle(isPrimary ? PrepFlowColor.white : PrepFlowColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: PrepFlowMetric.smallControlHeight)
            .background(isPrimary ? PrepFlowColor.ink : PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous)
                    .stroke(isPrimary ? PrepFlowColor.ink : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct OperatorChip: View {
    let name: String
    let section: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
            Text(name)
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(isSelected ? PrepFlowColor.white : PrepFlowColor.ink)
            Text(section)
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(isSelected ? PrepFlowColor.g4 : PrepFlowColor.g2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PrepFlowSpacing.md)
        .padding(.vertical, PrepFlowSpacing.sm)
        .background(isSelected ? PrepFlowColor.ink : PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(isSelected ? PrepFlowColor.ink : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct AssistProposalCard: View {
    let proposal: TodayPrepAssistProposal
    let applyAssist: () -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.md) {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                Text(proposal.title)
                    .font(PrepFlowFont.bodyBold)
                    .foregroundStyle(PrepFlowColor.ink)
                Text(proposal.detail)
                    .font(PrepFlowFont.small)
                    .foregroundStyle(PrepFlowColor.g2)
                Text("+\(proposal.shortfallMinutes)分見込み")
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.time) // time-use: assist delay shortfall
                    .monospacedDigit()
            }
            Spacer()
            Button(proposal.actionLabel, action: applyAssist)
                .buttonStyle(AssistApplyButtonStyle())
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

private struct AssistApplyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.white)
            .padding(.horizontal, PrepFlowSpacing.md)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .background(PrepFlowColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct GuidanceWorkStatePanel: View {
    let progress: TodayPrepProgress
    let activeHold: TodayPrepHold?
    let holdHistory: [TodayPrepHold]
    let pause: (String) -> Void
    let resume: () -> Void

    private let reasons = ["材料待ち", "火入れ待ち", "応援待ち"]

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("作業状態")
                        .font(PrepFlowFont.sectionTitle)
                        .foregroundStyle(PrepFlowColor.g2)
                    Text(statusText)
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(activeHold == nil ? PrepFlowColor.ink : PrepFlowColor.time) // time-use: active work hold blocks deadline
                }
                Spacer()
                if let activeHold {
                    Text("停止 \(activeHold.pausedAt)")
                        .font(PrepFlowFont.countdownLabel)
                        .foregroundStyle(PrepFlowColor.time) // time-use: active hold start time
                        .monospacedDigit()
                } else if let last = holdHistory.last {
                    Text("再開 \(last.resumedAt ?? last.pausedAt)")
                        .font(PrepFlowFont.countdownLabel)
                        .foregroundStyle(PrepFlowColor.g2)
                        .monospacedDigit()
                }
            }

            HStack(spacing: PrepFlowSpacing.sm) {
                if activeHold == nil {
                    ForEach(reasons, id: \.self) { reason in
                        Button(reason) {
                            pause(reason)
                        }
                        .buttonStyle(SmallControlButtonStyle(isPrimary: false, isEnabled: !progress.isComplete))
                        .disabled(progress.isComplete)
                    }
                } else {
                    Button("再開") {
                        resume()
                    }
                    .buttonStyle(SmallControlButtonStyle(isPrimary: true, isEnabled: true))
                }
            }
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(holdBorder, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private var holdBorder: Color {
        activeHold == nil ? PrepFlowColor.g4 : PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) // time-use: active hold border
    }

    private var statusText: String {
        if let activeHold {
            return "\(activeHold.reason)で停止中"
        }
        guard let nextStepTitle = progress.nextStepTitle else {
            return "仕込み完了"
        }
        return "\(nextStepTitle)を進行中"
    }
}

private struct SmallControlButtonStyle: ButtonStyle {
    let isPrimary: Bool
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(isPrimary ? PrepFlowColor.white : PrepFlowColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .background(isEnabled ? (isPrimary ? PrepFlowColor.ink : PrepFlowColor.g5) : PrepFlowColor.g4)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(isPrimary ? PrepFlowColor.ink : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct GuidanceReadinessGate: View {
    let readiness: TodayPrepReadiness
    let blockReason: String
    let completeChecks: () -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(readiness.canComplete ? "完了できます" : blockReason)
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.ink)
                    .lineLimit(2)
                Text(detailText)
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.g2)
                    .lineLimit(2)
            }
            Spacer()
            Button("まとめて確認", action: completeChecks)
                .buttonStyle(SmallControlButtonStyle(isPrimary: true, isEnabled: !readiness.canComplete))
                .disabled(readiness.canComplete)
                .frame(width: PrepFlowMetric.guidanceBatchButtonWidth)
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(readiness.canComplete ? PrepFlowColor.ink : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private var detailText: String {
        if readiness.canComplete {
            return "次を完了できます"
        }
        return readiness.remainingTitles.joined(separator: " / ")
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct GuidanceCheckRow: View {
    let check: TodayPrepCheck
    let isDone: Bool

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            GuidanceCheckCircle(isDone: isDone)
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(check.title)
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(isDone ? PrepFlowColor.g2 : PrepFlowColor.ink)
                Text(check.detail)
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            Spacer(minLength: PrepFlowSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PrepFlowSpacing.sm)
        .background(isDone ? PrepFlowColor.g5 : PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(isDone ? PrepFlowColor.ink : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct GuidanceStepRow: View {
    let step: TodayPrepStep
    let actual: TodayPrepActual?
    let adjustActual: (Int) -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.md) {
            GuidanceCheckCircle(isDone: step.isDone)
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(step.title)
                    .font(PrepFlowFont.rowTitle)
                    .foregroundStyle(step.isDone ? PrepFlowColor.g3 : PrepFlowColor.ink)
                if let actual {
                    Text("実績 \(actual.actualMinutes)分 / 予定 \(actual.plannedMinutes)分")
                        .font(PrepFlowFont.small)
                        .foregroundStyle(PrepFlowColor.g2)
                        .monospacedDigit()
                    HStack(spacing: PrepFlowSpacing.xs) {
                        Button("-1分") {
                            adjustActual(-1)
                        }
                        .buttonStyle(MiniAdjustButtonStyle())
                        Button("+1分") {
                            adjustActual(1)
                        }
                        .buttonStyle(MiniAdjustButtonStyle())
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: PrepFlowSpacing.xxs) {
                Text("\(step.durationMin)分")
                    .font(PrepFlowFont.rowMeta)
                    .foregroundStyle(PrepFlowColor.g2)
                    .monospacedDigit()
                if let actual {
                    Text(varianceText(actual.varianceMinutes))
                        .font(PrepFlowFont.countdownLabel)
                        .foregroundStyle(actual.varianceMinutes > 0 ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: actual delay variance
                        .monospacedDigit()
                }
            }
        }
        .padding(PrepFlowSpacing.md)
        .background(step.isDone ? PrepFlowColor.g5 : PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private func varianceText(_ value: Int) -> String {
        if value > 0 {
            return "+\(value)分"
        }
        return "\(value)分"
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct GuidanceChip: View {
    let text: String
    let isPrimary: Bool

    var body: some View {
        Text(text)
            .font(PrepFlowFont.chip)
            .foregroundStyle(isPrimary ? PrepFlowColor.white : PrepFlowColor.ink)
            .monospacedDigit()
            .padding(.horizontal, PrepFlowSpacing.md)
            .padding(.vertical, PrepFlowSpacing.xs)
            .background(isPrimary ? PrepFlowColor.ink : PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous)
                    .stroke(isPrimary ? PrepFlowColor.ink : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
    }
}

private struct MiniAdjustButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.countdownLabel)
            .foregroundStyle(PrepFlowColor.ink)
            .padding(.horizontal, PrepFlowSpacing.sm)
            .frame(height: PrepFlowMetric.smallControlHeight)
            .background(PrepFlowColor.g5)
            .clipShape(Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct GuidanceCheckCircle: View {
    let isDone: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isDone ? PrepFlowColor.ink : PrepFlowColor.white)
            Circle()
                .stroke(isDone ? PrepFlowColor.ink : PrepFlowColor.g3, lineWidth: PrepFlowMetric.heavyLineWidth)
            if isDone {
                Image(systemName: "checkmark")
                    .font(PrepFlowFont.icon)
                    .foregroundStyle(PrepFlowColor.white)
            }
        }
        .frame(width: PrepFlowMetric.checkSize, height: PrepFlowMetric.checkSize)
    }
}

private struct SheetPrimaryButtonStyle: ButtonStyle {
    let isComplete: Bool
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.action)
            .foregroundStyle(PrepFlowColor.white)
            .frame(maxWidth: .infinity, minHeight: PrepFlowMetric.actionButtonHeight)
            .background(isComplete || !isEnabled ? PrepFlowColor.g3 : PrepFlowColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct SheetSecondaryButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.action)
            .foregroundStyle(isEnabled ? PrepFlowColor.ink : PrepFlowColor.g3)
            .frame(maxWidth: .infinity, minHeight: PrepFlowMetric.actionButtonHeight)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}
