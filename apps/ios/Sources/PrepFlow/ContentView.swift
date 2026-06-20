// 正本: design/p0-wireframe-board-liquidglass.png
// 正本: design/p1-wireframe-board-eta-liquidglass.png
// 正本: design/p1-wireframe-view-dishes-liquidglass.png
// 正本: design/p1-wireframe-view-staff-liquidglass.png
// swiftlint:disable file_length
import DesignTokens
import Engine
import SwiftUI

enum BoardMode: String, CaseIterable {
    case now = "今これ"
    case dishes = "皿ごと"
    case staff = "担当"
}

// 正本: design/flow-vertical-slice.png
struct ContentView: View {
    var body: some View {
        AuthenticatedRootView()
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
// 正本: design/p1-wireframe-view-dishes-liquidglass.png
// 正本: design/p1-wireframe-view-staff-liquidglass.png
struct PrepFlowBoardView: View {
    @State private var selectedMode: BoardMode = .now
    @State private var isGuidancePresented = false
    @State private var isLabelOpsPresented = false
    @StateObject private var store: BoardStore
    private let openSettings: (() -> Void)?

    init(initialMode: BoardMode, store: BoardStore = BoardStore(), openSettings: (() -> Void)? = nil) {
        _selectedMode = State(initialValue: initialMode)
        _store = StateObject(wrappedValue: store)
        self.openSettings = openSettings
    }

    var body: some View {
        BoardSurface {
            switch selectedMode {
            case .now:
                NowBoardContent(
                    quantity: store.nikiriQuantity,
                    scheduled: store.nikiriSchedule,
                    eta: store.eta,
                    completed: store.completed,
                    progress: store.todayPrepProgress,
                    activeStartedAt: store.todayPrepStartedAt[store.todayPrepProgress.nextStepID ?? ""],
                    readiness: store.currentTodayPrepReadiness,
                    activeHold: store.todayPrepActiveHold,
                    completionBlockReason: store.todayPrepCompletionBlockReason,
                    assistProposal: store.todayPrepAssistProposal,
                    assistAppliedSummary: store.todayPrepAssistAppliedSummary,
                    assistETAAfterApply: store.todayPrepAssistETAAfterApply,
                    impactItems: store.todayPrepImpactItems,
                    impactLastAction: store.todayPrepImpactLastAction
                ) { id in
                    store.handleTodayPrepBoardStepTap(id)
                } completedBy: { id in
                    store.todayPrepCompletionDisplay(for: id)
                } startNext: {
                    store.startNextTodayStep()
                } pause: {
                    store.pauseTodayPrep(reason: "火入れ待ち")
                } resume: {
                    store.resumeTodayPrep()
                } completeChecks: {
                    store.completeCurrentTodayPrepChecks()
                } completeNext: {
                    store.completeNextTodayStep()
                } applyAssist: {
                    store.applyTodayPrepAssist()
                } applyImpact: { id in
                    store.applyTodayPrepImpact(id)
                } dismissImpact: { id in
                    store.dismissTodayPrepImpact(id)
                }
            case .dishes:
                DishBoardContent(completed: store.completed, impactItems: store.todayPrepImpactItems) { id in
                    store.toggleDishBoardTask(id)
                } applyImpact: { id in
                    store.applyTodayPrepImpact(id)
                } dismissImpact: { id in
                    store.dismissTodayPrepImpact(id)
                }
            case .staff:
                StaffBoardContent(completed: store.completed, impactItems: store.todayPrepImpactItems) { id in
                    store.toggleStaffBoardTask(id)
                } applyImpact: { id in
                    store.applyTodayPrepImpact(id)
                } dismissImpact: { id in
                    store.dismissTodayPrepImpact(id)
                }
            }
        } topBar: {
            BoardTopBar(
                selectedMode: $selectedMode,
                covers: store.covers,
                serviceTime: store.serviceTime,
                impactCount: store.todayPrepImpactItems.count,
                urgentImpactCount: store.todayPrepImpactItems.count(where: \.isUrgent),
                openSettings: openSettings
            )
        } bottomBar: {
            if selectedMode == .now {
                BoardBottomBar(status: store.lineGateStatus) {
                    store.startNowGuidance()
                    isGuidancePresented = true
                } markAllDone: {
                    let status = store.requestLineGateFromBoard()
                    if status.canOpen {
                        isLabelOpsPresented = true
                    } else {
                        store.startNowGuidance()
                        isGuidancePresented = true
                    }
                }
            } else if selectedMode == .dishes {
                LineGateBar(status: store.lineGateStatus)
            }
        }
        .sheet(isPresented: $isGuidancePresented) {
            NowGuidanceSheet(
                title: store.nowGuidanceTitle,
                bodyText: store.nowGuidanceBody,
                progress: store.todayPrepProgress,
                operators: store.todayPrepOperators,
                selectedOperatorID: store.selectedTodayPrepOperatorID,
                assistProposal: store.todayPrepAssistProposal,
                activeStartedAt: store.todayPrepStartedAt[store.todayPrepProgress.nextStepID ?? ""],
                actuals: store.todayPrepActuals,
                activeChecks: store.currentTodayPrepChecks,
                completedCheckIDs: store.todayPrepCompletedCheckIDs,
                readiness: store.currentTodayPrepReadiness,
                completionBlockReason: store.todayPrepCompletionBlockReason,
                activeHold: store.todayPrepActiveHold,
                holdHistory: store.todayPrepHoldHistory,
                impactItems: store.todayPrepImpactItems,
                impactLastAction: store.todayPrepImpactLastAction,
                canUndo: store.lastTodayPrepUndo != nil
            ) {
                store.completeNextTodayStep()
            } undo: {
                store.undoLastTodayPrepAction()
            } selectOperator: { id in
                store.selectTodayPrepOperator(id)
            } startNext: {
                store.startNextTodayStep()
            } toggleCheck: { id in
                store.toggleTodayPrepCheck(id)
            } completeChecks: {
                store.completeCurrentTodayPrepChecks()
            } requestAssist: {
                store.requestTodayPrepAssist()
            } applyAssist: {
                store.applyTodayPrepAssist()
            } pause: { reason in
                store.pauseTodayPrep(reason: reason)
            } resume: {
                store.resumeTodayPrep()
            } adjustActual: { stepID, delta in
                store.adjustTodayPrepActualMinutes(stepID: stepID, delta: delta)
            } applyImpact: { id in
                store.applyTodayPrepImpact(id)
            } dismissImpact: { id in
                store.dismissTodayPrepImpact(id)
            }
        }
        .sheet(isPresented: $isLabelOpsPresented) {
            LabelOpsSheet(store: store) {
                isLabelOpsPresented = false
            }
        }
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct BoardSurface<Content: View, TopBar: View, BottomBar: View>: View {
    @ViewBuilder let content: Content
    @ViewBuilder let topBar: TopBar
    @ViewBuilder let bottomBar: BottomBar

    var body: some View {
        ZStack {
            PrepFlowColor.g5.ignoresSafeArea()

            content
                .padding(.top, PrepFlowMetric.topInset)
                .padding(.bottom, PrepFlowMetric.bottomInset)

            VStack(spacing: PrepFlowSpacing.md) {
                topBar
                Spacer()
                bottomBar
            }
            .padding(PrepFlowSpacing.md)
        }
        .foregroundStyle(PrepFlowColor.ink)
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct BoardTopBar: View {
    @Binding var selectedMode: BoardMode
    let covers: Int
    let serviceTime: String
    let impactCount: Int
    let urgentImpactCount: Int
    let openSettings: (() -> Void)?

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.lg) {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("本日の仕込み")
                        .font(PrepFlowFont.topTitle)
                    Text("鮨 はやし ・ 6/11(木) 夜 ・ \(covers)名")
                        .font(PrepFlowFont.topSubtitle)
                        .foregroundStyle(PrepFlowColor.g2)
                }

                Spacer(minLength: PrepFlowSpacing.lg)

                BoardSegmentedControl(selectedMode: $selectedMode)

                Spacer(minLength: PrepFlowSpacing.lg)

                HStack(spacing: PrepFlowSpacing.sm) {
                    if impactCount > 0 {
                        BoardImpactBadge(count: impactCount, urgentCount: urgentImpactCount)
                    }
                    Text("5 / \(covers)")
                        .font(PrepFlowFont.chip)
                        .foregroundStyle(PrepFlowColor.g2)
                    CountdownIsland(serviceTime: serviceTime)
                    if let openSettings {
                        Button("設定", action: openSettings)
                            .buttonStyle(BoardGlassActionButtonStyle())
                    }
                }
            }
            .padding(.leading, PrepFlowSpacing.lg)
            .padding(.trailing, PrepFlowSpacing.md)
            .frame(height: PrepFlowMetric.topBarHeight)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous)
                    .stroke(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke), lineWidth: PrepFlowMetric.lineWidth)
            }
            .shadow(color: PrepFlowColor.ink.opacity(PrepFlowOpacity.glassShadow), radius: PrepFlowSpacing.lg, y: PrepFlowSpacing.sm)
            .glassEffect()
        }
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct BoardImpactBadge: View {
    let count: Int
    let urgentCount: Int

    var body: some View {
        HStack(spacing: PrepFlowSpacing.xs) {
            Text("外部変化")
                .font(PrepFlowFont.countdownLabel)
            Text("\(count)")
                .font(PrepFlowFont.smallBold)
                .monospacedDigit()
        }
        .foregroundStyle(urgentCount > 0 ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: unresolved urgent board impact
        .padding(.horizontal, PrepFlowSpacing.sm)
        .frame(height: PrepFlowMetric.catalogFieldHeight)
        .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                .stroke(
                    urgentCount > 0
                        ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) // time-use: urgent board impact badge stroke
                        : PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke),
                    lineWidth: PrepFlowMetric.lineWidth
                )
        }
        .glassEffect()
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct BoardSegmentedControl: View {
    @Binding var selectedMode: BoardMode

    var body: some View {
        HStack(spacing: PrepFlowSpacing.xxs) {
            ForEach(BoardMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: PrepFlowMotion.response, dampingFraction: PrepFlowMotion.dampingFraction)) {
                        selectedMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(PrepFlowFont.segment)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundStyle(selectedMode == mode ? PrepFlowColor.ink : PrepFlowColor.g2)
                        .padding(.horizontal, PrepFlowSpacing.lg)
                        .padding(.vertical, PrepFlowSpacing.sm)
                        .background(selectedMode == mode ? PrepFlowColor.white : PrepFlowColor.clear)
                        .clipShape(Capsule(style: .continuous))
                        .shadow(
                            color: selectedMode == mode ? PrepFlowColor.ink.opacity(PrepFlowOpacity.glassShadow) : PrepFlowColor.clear,
                            radius: PrepFlowSpacing.xs,
                            y: PrepFlowSpacing.xxs
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(PrepFlowSpacing.xxs)
        .background(PrepFlowColor.ink.opacity(PrepFlowOpacity.selection))
        .clipShape(Capsule(style: .continuous))
        .glassEffect()
    }
}

private struct BoardGlassActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.ink)
            .padding(.horizontal, PrepFlowSpacing.md)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .background(configuration.isPressed ? PrepFlowColor.g4 : PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct CountdownIsland: View {
    let serviceTime: String

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            ZStack {
                Circle()
                    .stroke(PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke), lineWidth: PrepFlowMetric.heavyLineWidth) // time-use: countdown ring base
                Circle()
                    .trim(from: PrepFlowSpacing.none, to: PrepFlowProgress.countdown)
                    .stroke(PrepFlowColor.time, style: StrokeStyle(lineWidth: PrepFlowMetric.heavyLineWidth, lineCap: .round)) // time-use: T countdown ring
                    .rotationEffect(PrepFlowAngle.countdownStart)
                Circle()
                    .fill(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
                    .frame(width: PrepFlowMetric.countdownRingInner, height: PrepFlowMetric.countdownRingInner)
            }
            .frame(width: PrepFlowMetric.countdownRing, height: PrepFlowMetric.countdownRing)

            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text("SERVICE \(serviceTime)")
                    .font(PrepFlowFont.countdownLabel)
                    .lineLimit(1)
                    .foregroundStyle(PrepFlowColor.time) // time-use: service time label
                Text("T−2:48")
                    .font(PrepFlowFont.countdownValue)
                    .lineLimit(1)
                    .foregroundStyle(PrepFlowColor.time) // time-use: T countdown value
                    .monospacedDigit()
            }
        }
        .frame(minWidth: PrepFlowMetric.countdownIslandWidth)
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, PrepFlowSpacing.md)
        .padding(.vertical, PrepFlowSpacing.xs)
        .background(PrepFlowColor.time.opacity(PrepFlowOpacity.timeGlass)) // time-use: countdown glass island tint
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke), lineWidth: PrepFlowMetric.lineWidth) // time-use: countdown island stroke
        }
        .glassEffect()
    }
}

// 正本: design/p1-wireframe-board-eta-liquidglass.png
private struct ETACompact: View {
    let eta: ETA

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            Text("着地 \(eta.landing)")
                .font(PrepFlowFont.countdownValue)
                .foregroundStyle(PrepFlowColor.time) // time-use: ETA delay landing
                .monospacedDigit()
            Text("+\(eta.shortfallMin)分 見込み")
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(PrepFlowColor.g2)
        }
        .padding(.horizontal, PrepFlowSpacing.md)
        .padding(.vertical, PrepFlowSpacing.xs)
        .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .glassEffect()
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct NowBoardContent: View {
    let quantity: Quantity
    let scheduled: Scheduled
    let eta: ETA
    let completed: Set<String>
    let progress: TodayPrepProgress
    let activeStartedAt: String?
    let readiness: TodayPrepReadiness
    let activeHold: TodayPrepHold?
    let completionBlockReason: String
    let assistProposal: TodayPrepAssistProposal?
    let assistAppliedSummary: String?
    let assistETAAfterApply: ETA?
    let impactItems: [TodayPrepImpactItem]
    let impactLastAction: String
    let onToggle: (String) -> Void
    let completedBy: (String) -> String?
    let startNext: () -> Void
    let pause: () -> Void
    let resume: () -> Void
    let completeChecks: () -> Void
    let completeNext: () -> Void
    let applyAssist: () -> Void
    let applyImpact: (String) -> Void
    let dismissImpact: (String) -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.none) {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.md) {
                Text("● NOW ・ \(scheduled.start) ／ T−3:00")
                    .font(PrepFlowFont.nowLabel)
                    .foregroundStyle(PrepFlowColor.time) // time-use: NOW timestamp
                    .padding(.horizontal, PrepFlowSpacing.md)
                    .padding(.vertical, PrepFlowSpacing.xs)
                    .background(PrepFlowColor.time.opacity(PrepFlowOpacity.timeSoft)) // time-use: NOW chip background
                    .clipShape(Capsule(style: .continuous))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke), lineWidth: PrepFlowMetric.lineWidth) // time-use: NOW chip stroke
                    }

                Text("煮切り仕込み")
                    .font(PrepFlowFont.focusTitle)

                HStack(spacing: PrepFlowSpacing.sm) {
                    FocusChip(text: "\(Int(quantity.total))\(quantity.unit) ・ 14名分", isPrimary: true)
                    FocusChip(text: "\(nikiriDuration)分", isPrimary: false)
                    FocusChip(text: "親方", isPrimary: false)
                }

                if showsBoardWorkStatePanel {
                    BoardWorkStatePanel(
                        progress: progress,
                        activeStartedAt: activeStartedAt,
                        readiness: readiness,
                        activeHold: activeHold,
                        blockReason: completionBlockReason,
                        startNext: startNext,
                        pause: pause,
                        resume: resume,
                        completeChecks: completeChecks,
                        completeNext: completeNext
                    )
                }

                VStack(spacing: PrepFlowSpacing.sm) {
                    FocusTaskRow(
                        id: "sake",
                        title: "酒・みりんを煮切る",
                        duration: "10分",
                        completedBy: completedBy("sake"),
                        isDone: completed.contains("sake")
                    ) {
                        toggle("sake")
                    }
                    FocusTaskRow(
                        id: "tare",
                        title: "たまり・濃口を合わせ ひと煮立ち",
                        duration: "15分",
                        completedBy: completedBy("tare"),
                        isDone: completed.contains("tare")
                    ) {
                        toggle("tare")
                    }
                    FocusTaskRow(
                        id: "rest",
                        title: "味見基準を確認し 冷暗所へ",
                        duration: "15分",
                        completedBy: completedBy("rest"),
                        isDone: completed.contains("rest")
                    ) {
                        toggle("rest")
                    }
                }
            }
            .padding(.horizontal, PrepFlowMetric.boardHorizontalPadding)
            .padding(.top, PrepFlowSpacing.xs)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityLabel("着地 \(eta.landing) \(eta.shortfallMin)分見込み")

            TimelineRail(
                eta: eta,
                assistProposal: assistProposal,
                assistAppliedSummary: assistAppliedSummary,
                assistETAAfterApply: assistETAAfterApply,
                impactItems: impactItems,
                impactLastAction: impactLastAction,
                applyAssist: applyAssist,
                applyImpact: applyImpact,
                dismissImpact: dismissImpact
            )
            .frame(width: PrepFlowMetric.railWidth)
        }
    }

    private var nikiriDuration: Int {
        40
    }

    private var showsBoardWorkStatePanel: Bool {
        activeStartedAt != nil
            || activeHold != nil
            || readiness.completedCount > 0
            || completionBlockReason.hasPrefix("未完:")
    }

    private func toggle(_ id: String) {
        withAnimation(.spring(response: PrepFlowMotion.response, dampingFraction: PrepFlowMotion.dampingFraction)) {
            onToggle(id)
        }
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct FocusChip: View {
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

// 正本: design/p0-wireframe-board-liquidglass.png
private struct BoardWorkStatePanel: View {
    let progress: TodayPrepProgress
    let activeStartedAt: String?
    let readiness: TodayPrepReadiness
    let activeHold: TodayPrepHold?
    let blockReason: String
    let startNext: () -> Void
    let pause: () -> Void
    let resume: () -> Void
    let completeChecks: () -> Void
    let completeNext: () -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.md) {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                HStack(spacing: PrepFlowSpacing.sm) {
                    Text(stateTitle)
                        .font(PrepFlowFont.bodyBold)
                        .foregroundStyle(activeHold == nil ? PrepFlowColor.ink : PrepFlowColor.time) // time-use: active hold blocks open deadline
                    Text("\(readiness.completedCount)/\(readiness.requiredCount)")
                        .font(PrepFlowFont.countdownLabel)
                        .foregroundStyle(PrepFlowColor.g2)
                        .monospacedDigit()
                }
                Text(stateDetail)
                    .font(PrepFlowFont.small)
                    .foregroundStyle(PrepFlowColor.g2)
                    .lineLimit(2)
            }

            Spacer(minLength: PrepFlowSpacing.md)

            HStack(spacing: PrepFlowSpacing.xs) {
                Button(activeStartedAt == nil ? "着手" : "着手中", action: startNext)
                    .buttonStyle(BoardWorkButtonStyle(isPrimary: false, isEnabled: activeStartedAt == nil && !progress.isComplete))
                    .disabled(activeStartedAt != nil || progress.isComplete)
                Button(activeHold == nil ? "停止" : "再開") {
                    if activeHold == nil {
                        pause()
                    } else {
                        resume()
                    }
                }
                .buttonStyle(BoardWorkButtonStyle(isPrimary: false, isEnabled: !progress.isComplete))
                .disabled(progress.isComplete)
                Button("確認まとめ", action: completeChecks)
                    .buttonStyle(BoardWorkButtonStyle(isPrimary: false, isEnabled: !readiness.canComplete && !progress.isComplete))
                    .disabled(readiness.canComplete || progress.isComplete)
                Button(progress.isComplete ? "点検待ち" : "次完了", action: completeNext)
                    .buttonStyle(BoardWorkButtonStyle(isPrimary: true, isEnabled: readiness.canComplete && activeHold == nil && !progress.isComplete))
                    .disabled(!readiness.canComplete || activeHold != nil || progress.isComplete)
            }
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(borderColor, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private var stateTitle: String {
        if let activeHold {
            return "\(activeHold.reason)で停止"
        }
        if progress.isComplete {
            return "ライン点検へ"
        }
        return progress.nextStepTitle ?? "次工程なし"
    }

    private var stateDetail: String {
        if let activeHold {
            return "停止 \(activeHold.pausedAt)。再開してから完了できます"
        }
        if readiness.canComplete {
            return activeStartedAt == nil ? "着手後に次を完了できます" : "確認項目OK。次を完了できます"
        }
        return blockReason
    }

    private var borderColor: Color {
        activeHold == nil ? PrepFlowColor.g4 : PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) // time-use: active hold card border
    }
}

private struct BoardWorkButtonStyle: ButtonStyle {
    let isPrimary: Bool
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.countdownLabel)
            .foregroundStyle(isEnabled ? (isPrimary ? PrepFlowColor.white : PrepFlowColor.ink) : PrepFlowColor.g3)
            .frame(minWidth: PrepFlowMetric.boardWorkButtonWidth)
            .frame(height: PrepFlowMetric.smallControlHeight)
            .background(isEnabled ? (isPrimary ? PrepFlowColor.ink : PrepFlowColor.g5) : PrepFlowColor.g4)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous)
                    .stroke(isPrimary && isEnabled ? PrepFlowColor.ink : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct FocusTaskRow: View {
    let id: String
    let title: String
    let duration: String
    let completedBy: String?
    let isDone: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PrepFlowSpacing.md) {
                CheckCircle(isDone: isDone)
                Text(title)
                    .font(PrepFlowFont.rowTitle)
                    .foregroundStyle(isDone ? PrepFlowColor.g3 : PrepFlowColor.ink)
                    .strikethrough(isDone, color: PrepFlowColor.g3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: PrepFlowSpacing.xxs) {
                    Text(duration)
                        .font(PrepFlowFont.rowMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                        .monospacedDigit()
                    if let completedBy, isDone {
                        Text(completedBy)
                            .font(PrepFlowFont.smallBold)
                            .foregroundStyle(PrepFlowColor.ink)
                            .padding(.horizontal, PrepFlowSpacing.sm)
                            .padding(.vertical, PrepFlowSpacing.xxs)
                            .background(PrepFlowColor.ink.opacity(PrepFlowOpacity.selection))
                            .clipShape(Capsule(style: .continuous))
                    }
                }
            }
            .padding(.horizontal, PrepFlowSpacing.md)
            .padding(.vertical, PrepFlowSpacing.md)
            .frame(minHeight: PrepFlowMetric.taskRowMinHeight)
            .background(isDone ? PrepFlowColor.g5 : PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct CheckCircle: View {
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

// 正本: design/p0-wireframe-board-liquidglass.png
private struct TimelineRail: View {
    let eta: ETA
    let assistProposal: TodayPrepAssistProposal?
    let assistAppliedSummary: String?
    let assistETAAfterApply: ETA?
    let impactItems: [TodayPrepImpactItem]
    let impactLastAction: String
    let applyAssist: () -> Void
    let applyImpact: (String) -> Void
    let dismissImpact: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            if !impactItems.isEmpty {
                BoardImpactRailCard(
                    items: impactItems,
                    lastAction: impactLastAction,
                    apply: applyImpact,
                    dismiss: dismissImpact
                )
            }

            if assistProposal != nil || assistAppliedSummary != nil || !impactItems.isEmpty {
                BoardLandingForecastCard(
                    eta: eta,
                    proposal: assistProposal,
                    appliedSummary: assistAppliedSummary,
                    etaAfterApply: assistETAAfterApply,
                    impactCount: impactItems.count,
                    applyAssist: applyAssist
                )
            }

            HStack {
                Text("逆算スケジュール")
                    .font(PrepFlowFont.sectionTitle)
                Spacer()
                Text("T = 18:00")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }

            ProgressBar(progress: PrepFlowProgress.schedule)

            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                RailItem(title: "ネタの仕込み", time: "13:30 ・ T−4:30", state: .done)
                RailItem(title: "シャリを炊く", time: "14:00 ・ T−4:00", state: .done)
                RailItem(title: "煮切り仕込み", time: "15:00 ・ T−3:00 ・ NOW", state: .now)
                RailItem(title: "ソースを炊く", time: "16:00 ・ T−2:00", state: .pending)
                RailItem(title: "盛り付けの準備", time: "16:30 ・ T−1:30", state: .pending)
                RailItem(title: "吸地を引く", time: "17:00 ・ T−1:00", state: .pending)
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(PrepFlowColor.ink.opacity(PrepFlowOpacity.rule))
                    .frame(width: PrepFlowMetric.timelineRuleWidth)
                    .padding(.leading, PrepFlowSpacing.xs)
                    .padding(.vertical, PrepFlowSpacing.sm)
                    .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, PrepFlowSpacing.lg)
        .padding(.top, PrepFlowSpacing.xs)
        .frame(maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(PrepFlowColor.ink.opacity(PrepFlowOpacity.rule))
                .frame(width: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
// 正本: design/p1-wireframe-board-eta-liquidglass.png
private struct BoardImpactRailCard: View {
    let items: [TodayPrepImpactItem]
    let lastAction: String
    let apply: (String) -> Void
    let dismiss: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("外部変化")
                        .font(PrepFlowFont.sectionTitle)
                        .foregroundStyle(PrepFlowColor.g2)
                    Text(lastAction)
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(items.contains(where: \.isUrgent) ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: urgent board impact
                        .lineLimit(1)
                }
                Spacer()
                Text("\(items.count)")
                    .font(PrepFlowFont.railTitle)
                    .foregroundStyle(PrepFlowColor.time) // time-use: unresolved board impact count
                    .monospacedDigit()
            }

            ForEach(items.prefix(PrepFlowLayout.impactPreviewLimit)) { item in
                BoardImpactMiniRow(item: item, apply: apply, dismiss: dismiss)
            }
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke), lineWidth: PrepFlowMetric.lineWidth) // time-use: urgent impact rail border
        }
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct BoardImpactMiniRow: View {
    let item: TodayPrepImpactItem
    let apply: (String) -> Void
    let dismiss: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack(spacing: PrepFlowSpacing.xs) {
                Text(item.sourceLabel)
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(item.isUrgent ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: urgent impact source
                    .lineLimit(1)
                Spacer()
                Text(item.title)
                    .font(PrepFlowFont.smallBold)
                    .lineLimit(1)
            }
            Text(item.detail)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
                .lineLimit(2)
            HStack(spacing: PrepFlowSpacing.xs) {
                Button("後で") {
                    dismiss(item.id)
                }
                .buttonStyle(BoardImpactButtonStyle(isPrimary: false))
                Button(item.actionLabel) {
                    apply(item.id)
                }
                .buttonStyle(BoardImpactButtonStyle(isPrimary: true))
            }
        }
        .padding(PrepFlowSpacing.xs)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

private struct BoardImpactButtonStyle: ButtonStyle {
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

// 正本: design/p1-wireframe-board-eta-liquidglass.png
private struct BoardLandingForecastCard: View {
    let eta: ETA
    let proposal: TodayPrepAssistProposal?
    let appliedSummary: String?
    let etaAfterApply: ETA?
    let impactCount: Int
    let applyAssist: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            HStack(alignment: .top, spacing: PrepFlowSpacing.sm) {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("着地予測")
                        .font(PrepFlowFont.sectionTitle)
                        .foregroundStyle(PrepFlowColor.g2)
                    Text("着地 \(displayETA.landing)")
                        .font(PrepFlowFont.iconLarge)
                        .foregroundStyle(displayETA.shortfallMin > 0 ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: ETA landing/delay
                        .monospacedDigit()
                }
                Spacer()
                Text(displayETA.shortfallMin > 0 ? "+\(displayETA.shortfallMin)分" : "定刻内")
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(displayETA.shortfallMin > 0 ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: ETA shortfall
                    .padding(.horizontal, PrepFlowSpacing.sm)
                    .padding(.vertical, PrepFlowSpacing.xxs)
                    .background(
                        displayETA.shortfallMin > 0
                            ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeNow) // time-use: delay badge tint
                            : PrepFlowColor.ink.opacity(PrepFlowOpacity.selection)
                    ) // time-use: delay badge tint
                    .clipShape(Capsule(style: .continuous))
            }

            Text(statusText)
                .font(PrepFlowFont.small)
                .foregroundStyle(PrepFlowColor.g2)
                .fixedSize(horizontal: false, vertical: true)

            if let proposal, appliedSummary == nil {
                HStack(spacing: PrepFlowSpacing.sm) {
                    Text("−\(proposal.savesMinutes)分")
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(PrepFlowColor.ok)
                        .monospacedDigit()
                    Spacer()
                    Button(proposal.actionLabel, action: applyAssist)
                        .buttonStyle(BoardAssistApplyButtonStyle())
                }
            }
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(displayETA.shortfallMin > 0 ? PrepFlowColor.time : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth) // time-use: ETA risk card stroke
        }
    }

    private var displayETA: ETA {
        etaAfterApply ?? eta
    }

    private var statusText: String {
        if let appliedSummary {
            return appliedSummary
        }
        if let proposal {
            return proposal.detail
        }
        if impactCount > 0 {
            return "外部変化 \(impactCount)件が未反映です。手順へ追加すると着地を再確認します。"
        }
        return "残タスクから着地を再計算しています。"
    }
}

private struct BoardAssistApplyButtonStyle: ButtonStyle {
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

private enum RailState {
    case done
    case now
    case pending
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct RailItem: View {
    let title: String
    let time: String
    let state: RailState

    var body: some View {
        HStack(alignment: .top, spacing: PrepFlowSpacing.sm) {
            Circle()
                .fill(dotFill)
                .overlay {
                    Circle()
                        .stroke(dotStroke, lineWidth: PrepFlowMetric.heavyLineWidth)
                }
                .shadow(color: state == .now ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) : PrepFlowColor.clear, radius: PrepFlowSpacing.xs) // time-use: NOW rail halo
                .frame(width: PrepFlowMetric.timelineDot, height: PrepFlowMetric.timelineDot)
                .padding(.top, PrepFlowSpacing.xs)

            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(title)
                    .font(PrepFlowFont.railTitle)
                    .foregroundStyle(state == .done ? PrepFlowColor.g3 : PrepFlowColor.ink)
                    .strikethrough(state == .done, color: PrepFlowColor.g3)
                Text(time)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(state == .now ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: NOW rail timestamp
                    .monospacedDigit()
            }
            Spacer()
        }
        .padding(.horizontal, PrepFlowSpacing.sm)
        .padding(.vertical, PrepFlowSpacing.xs)
        .background(state == .now ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeNow) : PrepFlowColor.clear) // time-use: NOW rail row
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))
    }

    private var dotFill: Color {
        switch state {
        case .done:
            PrepFlowColor.ink
        case .now:
            PrepFlowColor.time // time-use: NOW rail dot
        case .pending:
            PrepFlowColor.white
        }
    }

    private var dotStroke: Color {
        switch state {
        case .done:
            PrepFlowColor.ink
        case .now:
            PrepFlowColor.time // time-use: NOW rail dot stroke
        case .pending:
            PrepFlowColor.g3
        }
    }
}

// 正本: design/p1-wireframe-view-dishes-liquidglass.png
private struct DishBoardContent: View {
    let completed: Set<String>
    let impactItems: [TodayPrepImpactItem]
    let toggle: (String) -> Void
    let applyImpact: (String) -> Void
    let dismissImpact: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: PrepFlowSpacing.md) {
                DishCard(title: "先付け", window: "T−4:00 窓", done: 1, total: 1, rows: [
                    DishTask(id: "dish-sakizuke-kobachi", title: "小鉢の仕込み", quantity: "14客", time: "14:00 ・ T−4:00", isDone: true, isNow: false, section: "ガルド"),
                ], impacts: [], toggle: toggle, applyImpact: applyImpact, dismissImpact: dismissImpact)
                DishCard(title: "おまかせ握り", window: "T−4:30 〜 T−2:30", done: completed.intersection(["shari", "nikiri", "neta"]).count, total: 3, rows: [
                    DishTask(
                        id: "dish-omakase-shari",
                        title: "シャリ — 米を炊く・赤酢",
                        quantity: "米 2.0升",
                        time: "14:00 ・ T−4:00",
                        isDone: completed.contains("shari"),
                        isNow: false,
                        section: "シャリ場"
                    ),
                    DishTask(
                        id: "dish-omakase-nikiri",
                        title: "煮切り仕込み",
                        quantity: "200ml",
                        time: "15:00 ・ T−3:00",
                        isDone: completed.contains("nikiri"),
                        isNow: true,
                        section: "親方"
                    ),
                    DishTask(id: "dish-omakase-neta", title: "ネタの仕込み", quantity: "各14貫", time: "13:30 ・ T−4:30", isDone: completed.contains("neta"), isNow: false, section: "親方"),
                ], impacts: impactItems, toggle: toggle, applyImpact: applyImpact, dismissImpact: dismissImpact)
                DishCard(title: "椀物", window: "T−1:30 〜 T−1:00", done: completed.intersection(["suiji", "wandane"]).count, total: 2, rows: [
                    DishTask(id: "dish-wan-suiji", title: "吸地を引く", quantity: "14杯", time: "17:00 ・ T−1:00", isDone: completed.contains("suiji"), isNow: false, section: "親方"),
                    DishTask(id: "dish-wan-wandane", title: "椀種の準備", quantity: "14客", time: "16:30 ・ T−1:30", isDone: completed.contains("wandane"), isNow: false, section: "ガルド"),
                ], impacts: [], toggle: toggle, applyImpact: applyImpact, dismissImpact: dismissImpact)
            }
            .padding(.horizontal, PrepFlowSpacing.xl)
            .padding(.bottom, PrepFlowSpacing.lg)
        }
    }
}

private struct DishTask: Identifiable {
    let id: String
    let title: String
    let quantity: String
    let time: String
    let isDone: Bool
    let isNow: Bool
    let section: String
}

// 正本: design/p1-wireframe-view-dishes-liquidglass.png
private struct DishCard: View {
    let title: String
    let window: String
    let done: Int
    let total: Int
    let rows: [DishTask]
    let impacts: [TodayPrepImpactItem]
    let toggle: (String) -> Void
    let applyImpact: (String) -> Void
    let dismissImpact: (String) -> Void

    var body: some View {
        VStack(spacing: PrepFlowSpacing.none) {
            HStack(spacing: PrepFlowSpacing.md) {
                ZStack {
                    Circle()
                        .fill(done == total ? PrepFlowColor.white : PrepFlowColor.white)
                    Text(done == total ? "✓" : "▾")
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(done == total ? PrepFlowColor.ink : PrepFlowColor.g2)
                }
                .frame(width: PrepFlowSpacing.xl, height: PrepFlowSpacing.xl)

                Text(title)
                    .font(PrepFlowFont.topTitle)
                    .foregroundStyle(done == total ? PrepFlowColor.white : PrepFlowColor.ink)
                Spacer()
                Text(window)
                    .font(PrepFlowFont.small)
                    .foregroundStyle(done == total ? PrepFlowColor.g3 : PrepFlowColor.g2)
                Text(done == total ? "仕込み完了" : "\(done) / \(total)")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(done == total ? PrepFlowColor.white : PrepFlowColor.ink)
                    .padding(.horizontal, PrepFlowSpacing.md)
                    .padding(.vertical, PrepFlowSpacing.xs)
                    .background(done == total ? PrepFlowColor.clear : PrepFlowColor.white)
                    .clipShape(Capsule(style: .continuous))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(done == total ? PrepFlowColor.g2 : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
                    }
            }
            .padding(PrepFlowSpacing.md)
            .background(done == total ? PrepFlowColor.ink : PrepFlowColor.white.opacity(PrepFlowOpacity.contentHeader))

            ProgressBar(progress: total == 0 ? 0 : Double(done) / Double(total))

            ForEach(impacts.prefix(PrepFlowLayout.impactPreviewLimit)) { impact in
                DishImpactRow(item: impact, apply: applyImpact, dismiss: dismissImpact)
            }

            ForEach(rows) { row in
                DishTaskRow(task: row) {
                    toggle(row.id)
                }
            }
        }
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.xl, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p1-wireframe-view-dishes-liquidglass.png
private struct DishImpactRow: View {
    let item: TodayPrepImpactItem
    let apply: (String) -> Void
    let dismiss: (String) -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.md) {
            Text(item.sourceLabel)
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(item.isUrgent ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: urgent dish impact source
                .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .leading)
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(item.title)
                    .font(PrepFlowFont.bodyBold)
                Text(item.detail)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
                    .lineLimit(1)
            }
            Spacer()
            Button("後で") {
                dismiss(item.id)
            }
            .buttonStyle(BoardImpactButtonStyle(isPrimary: false))
            .frame(width: PrepFlowMetric.actionButtonHeight)
            Button(item.actionLabel) {
                apply(item.id)
            }
            .buttonStyle(BoardImpactButtonStyle(isPrimary: true))
            .frame(width: PrepFlowMetric.countdownIslandWidth)
        }
        .padding(.horizontal, PrepFlowSpacing.md)
        .padding(.vertical, PrepFlowSpacing.sm)
        .background(item.isUrgent ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeSoft) : PrepFlowColor.g5) // time-use: urgent dish impact row
        .overlay(alignment: .top) {
            Rectangle()
                .fill(item.isUrgent ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) : PrepFlowColor.g4) // time-use: urgent dish impact divider
                .frame(height: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p1-wireframe-view-dishes-liquidglass.png
private struct DishTaskRow: View {
    let task: DishTask
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PrepFlowSpacing.md) {
                CheckCircle(isDone: task.isDone)
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                    Text(task.title)
                        .font(PrepFlowFont.bodyBold)
                        .foregroundStyle(task.isDone ? PrepFlowColor.g3 : PrepFlowColor.ink)
                        .strikethrough(task.isDone, color: PrepFlowColor.g3)
                    HStack(spacing: PrepFlowSpacing.xs) {
                        Text(task.quantity)
                            .font(PrepFlowFont.smallBold)
                            .foregroundStyle(PrepFlowColor.white)
                            .padding(.horizontal, PrepFlowSpacing.sm)
                            .padding(.vertical, PrepFlowSpacing.xxs)
                            .background(task.isDone ? PrepFlowColor.g4 : PrepFlowColor.ink)
                            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))
                        Text(task.time)
                            .font(PrepFlowFont.small)
                            .foregroundStyle(task.isNow ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: task timing
                            .monospacedDigit()
                        if task.isNow {
                            Text("NOW")
                                .font(PrepFlowFont.countdownLabel)
                                .foregroundStyle(PrepFlowColor.white)
                                .padding(.horizontal, PrepFlowSpacing.sm)
                                .padding(.vertical, PrepFlowSpacing.xxs)
                                .background(PrepFlowColor.time) // time-use: NOW flag
                                .clipShape(Capsule(style: .continuous))
                        }
                    }
                }
                Spacer()
                Text(task.section)
                    .font(PrepFlowFont.small)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            .padding(.horizontal, PrepFlowSpacing.md)
            .padding(.vertical, PrepFlowSpacing.sm)
            .background(task.isNow ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeNow) : PrepFlowColor.white) // time-use: NOW row
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(PrepFlowColor.g4)
                    .frame(height: PrepFlowMetric.lineWidth)
            }
        }
        .buttonStyle(.plain)
    }
}

// 正本: design/p1-wireframe-view-staff-liquidglass.png
private struct StaffBoardContent: View {
    let completed: Set<String>
    let impactItems: [TodayPrepImpactItem]
    let toggle: (String) -> Void
    let applyImpact: (String) -> Void
    let dismissImpact: (String) -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.none) {
            StaffColumn(initial: "シ", name: "シャリ場", done: shariDone ? 1 : 0, total: 1, tasks: [
                StaffTask(
                    id: "staff-shari-rice",
                    dish: "おまかせ握り",
                    title: "米を炊く・赤酢",
                    quantity: "米 2.0升",
                    time: "T−4:00",
                    isDone: shariDone,
                    isNow: false
                ),
            ], impacts: [], toggle: toggle, applyImpact: applyImpact, dismissImpact: dismissImpact)
            StaffColumn(initial: "親", name: "親方", done: completed.intersection(["nikiri", "neta", "suiji"]).count, total: 3, tasks: [
                StaffTask(
                    id: "staff-chef-nikiri",
                    dish: "おまかせ握り",
                    title: "煮切り仕込み",
                    quantity: "200ml",
                    time: "15:00 ・ T−3:00 ・ NOW",
                    isDone: completed.contains("nikiri"),
                    isNow: true
                ),
                StaffTask(id: "staff-chef-neta", dish: "おまかせ握り", title: "ネタの仕込み", quantity: "各14貫", time: "T−4:30", isDone: completed.contains("neta"), isNow: false),
                StaffTask(id: "staff-chef-suiji", dish: "椀物", title: "吸地を引く", quantity: "14杯", time: "17:00 ・ T−1:00", isDone: completed.contains("suiji"), isNow: false),
            ], impacts: impactItems, toggle: toggle, applyImpact: applyImpact, dismissImpact: dismissImpact)
            StaffColumn(initial: "ガ", name: "ガルド", done: completed.intersection(["wandane", "sauce"]).count, total: 2, tasks: [
                StaffTask(id: "staff-garde-wandane", dish: "椀物", title: "椀種の準備", quantity: "14客", time: "16:30 ・ T−1:30", isDone: completed.contains("wandane"), isNow: false),
                StaffTask(id: "staff-garde-sauce", dish: "水菓子", title: "ソースを炊く", quantity: "300ml", time: "16:00 ・ T−2:00", isDone: completed.contains("sauce"), isNow: false),
            ], impacts: [], toggle: toggle, applyImpact: applyImpact, dismissImpact: dismissImpact)
            StaffColumn(initial: "長", name: "シェフ", done: completed.contains("line-check") ? 1 : 0, total: 1, tasks: [
                StaffTask(id: "line-check", dish: "全体", title: "ライン点検（全皿確認）", quantity: "", time: "17:30 ・ T−0:30", isDone: completed.contains("line-check"), isNow: false),
            ], impacts: [], toggle: toggle, applyImpact: applyImpact, dismissImpact: dismissImpact)
        }
    }

    private var shariDone: Bool {
        completed.contains("rice") || completed.contains("shari")
    }
}

private struct StaffTask: Identifiable {
    let id: String
    let dish: String
    let title: String
    let quantity: String
    let time: String
    let isDone: Bool
    let isNow: Bool
}

// 正本: design/p1-wireframe-view-staff-liquidglass.png
private struct StaffColumn: View {
    let initial: String
    let name: String
    let done: Int
    let total: Int
    let tasks: [StaffTask]
    let impacts: [TodayPrepImpactItem]
    var toggle: ((String) -> Void)?
    let applyImpact: (String) -> Void
    let dismissImpact: (String) -> Void

    var body: some View {
        VStack(spacing: PrepFlowSpacing.xs) {
            HStack(spacing: PrepFlowSpacing.sm) {
                Text(initial)
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.white)
                    .frame(width: PrepFlowSpacing.xxl, height: PrepFlowSpacing.xxl)
                    .background(PrepFlowColor.ink)
                    .clipShape(Circle())
                Text(name)
                    .font(PrepFlowFont.bodyBold)
                Spacer()
                Text("\(done)/\(total)")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.g2)
                    .padding(.horizontal, PrepFlowSpacing.sm)
                    .padding(.vertical, PrepFlowSpacing.xxs)
                    .background(PrepFlowColor.ink.opacity(PrepFlowOpacity.selection))
                    .clipShape(Capsule(style: .continuous))
            }
            .padding(.horizontal, PrepFlowSpacing.md)
            ProgressBar(progress: total == 0 ? 0 : Double(done) / Double(total))
                .padding(.horizontal, PrepFlowSpacing.md)
            ScrollView {
                VStack(spacing: PrepFlowSpacing.sm) {
                    ForEach(impacts.prefix(PrepFlowLayout.impactPreviewLimit)) { impact in
                        StaffImpactCard(item: impact, apply: applyImpact, dismiss: dismissImpact)
                    }
                    ForEach(tasks) { task in
                        StaffTaskCard(task: task) {
                            toggle?(task.id)
                        }
                    }
                }
                .padding(PrepFlowSpacing.md)
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(PrepFlowColor.ink.opacity(PrepFlowOpacity.rule))
                .frame(width: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p1-wireframe-view-staff-liquidglass.png
private struct StaffImpactCard: View {
    let item: TodayPrepImpactItem
    let apply: (String) -> Void
    let dismiss: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack {
                Text(item.sourceLabel)
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(item.isUrgent ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: urgent staff impact source
                Spacer()
                Text("未解決")
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(item.isUrgent ? PrepFlowColor.time : PrepFlowColor.ink) // time-use: urgent unresolved staff impact
            }
            Text(item.title)
                .font(PrepFlowFont.bodyBold)
            Text(item.detail)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
                .lineLimit(2)
            HStack(spacing: PrepFlowSpacing.xs) {
                Button("後で") {
                    dismiss(item.id)
                }
                .buttonStyle(BoardImpactButtonStyle(isPrimary: false))
                Button(item.actionLabel) {
                    apply(item.id)
                }
                .buttonStyle(BoardImpactButtonStyle(isPrimary: true))
            }
        }
        .padding(PrepFlowSpacing.md)
        .background(item.isUrgent ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeSoft) : PrepFlowColor.white) // time-use: urgent staff impact row
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(
                    item.isUrgent ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) : PrepFlowColor.g4, // time-use: urgent staff impact stroke
                    lineWidth: PrepFlowMetric.lineWidth
                ) // time-use: urgent staff impact stroke
        }
    }
}

// 正本: design/p1-wireframe-view-staff-liquidglass.png
private struct StaffTaskCard: View {
    let task: StaffTask
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            Text(task.dish)
                .font(PrepFlowFont.small)
                .foregroundStyle(PrepFlowColor.g2)
            Text(task.title)
                .font(PrepFlowFont.bodyBold)
                .foregroundStyle(task.isDone ? PrepFlowColor.g3 : PrepFlowColor.ink)
                .strikethrough(task.isDone, color: PrepFlowColor.g3)
            HStack(spacing: PrepFlowSpacing.xs) {
                if !task.quantity.isEmpty {
                    Text(task.quantity)
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(PrepFlowColor.white)
                        .padding(.horizontal, PrepFlowSpacing.sm)
                        .padding(.vertical, PrepFlowSpacing.xxs)
                        .background(task.isDone ? PrepFlowColor.g4 : PrepFlowColor.ink)
                        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous))
                }
                Text(task.time)
                    .font(PrepFlowFont.small)
                    .foregroundStyle(task.isNow ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: staff task timing
                    .monospacedDigit()
            }
            Button(action: action) {
                Text(task.isDone ? "完了" : "タップで完了")
                    .font(PrepFlowFont.smallBold)
                    .frame(maxWidth: .infinity)
                    .frame(height: PrepFlowMetric.checkSize)
                    .foregroundStyle(task.isDone ? PrepFlowColor.white : PrepFlowColor.ink)
                    .background(task.isDone ? PrepFlowColor.ink : PrepFlowColor.white)
                    .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                            .stroke(PrepFlowColor.ink, lineWidth: PrepFlowMetric.heavyLineWidth)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(PrepFlowSpacing.md)
        .background(task.isNow ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeNow) : PrepFlowColor.white) // time-use: staff NOW card
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(task.isNow ? PrepFlowColor.time : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth) // time-use: staff NOW stroke
        }
    }
}

// 正本: design/p1-wireframe-view-dishes-liquidglass.png
// 正本: design/p1-wireframe-view-staff-liquidglass.png
private struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(PrepFlowColor.ink.opacity(PrepFlowOpacity.rule))
                Capsule(style: .continuous)
                    .fill(PrepFlowColor.ink)
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: PrepFlowSpacing.xxs)
    }
}
