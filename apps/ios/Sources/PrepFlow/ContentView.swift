// 正本: design/p0-wireframe-board-liquidglass.png
// 正本: design/p1-wireframe-board-eta-liquidglass.png
// 正本: design/p1-wireframe-view-dishes-liquidglass.png
// 正本: design/p1-wireframe-view-staff-liquidglass.png
import DesignTokens
import Engine
import SwiftUI

enum BoardMode: String, CaseIterable {
    case now = "今これ"
    case dishes = "皿ごと"
    case staff = "担当"
}

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
                NowBoardContent(quantity: store.nikiriQuantity, scheduled: store.nikiriSchedule, eta: store.eta, completed: store.completed) { id in
                    store.toggle(id)
                }
            case .dishes:
                DishBoardContent(completed: store.completed)
            case .staff:
                StaffBoardContent(completed: store.completed) { id in
                    store.toggle(id)
                }
            }
        } topBar: {
            BoardTopBar(selectedMode: $selectedMode, covers: store.covers, serviceTime: store.serviceTime, openSettings: openSettings)
        } bottomBar: {
            if selectedMode == .now {
                BoardBottomBar {
                    store.markAllNowDone()
                }
            } else if selectedMode == .dishes {
                LineGateBar()
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
    let onToggle: (String) -> Void

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

                VStack(spacing: PrepFlowSpacing.sm) {
                    FocusTaskRow(id: "sake", title: "酒・みりんを煮切る", duration: "10分", isDone: completed.contains("sake")) {
                        toggle("sake")
                    }
                    FocusTaskRow(id: "tare", title: "たまり・濃口を合わせ ひと煮立ち", duration: "15分", isDone: completed.contains("tare")) {
                        toggle("tare")
                    }
                    FocusTaskRow(id: "rest", title: "味見基準を確認し 冷暗所へ", duration: "15分", isDone: completed.contains("rest")) {
                        toggle("rest")
                    }
                }
            }
            .padding(.horizontal, PrepFlowMetric.boardHorizontalPadding)
            .padding(.top, PrepFlowSpacing.xs)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityLabel("着地 \(eta.landing) \(eta.shortfallMin)分見込み")

            TimelineRail()
                .frame(width: PrepFlowMetric.railWidth)
        }
    }

    private var nikiriDuration: Int {
        40
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
private struct FocusTaskRow: View {
    let id: String
    let title: String
    let duration: String
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
                Text(duration)
                    .font(PrepFlowFont.rowMeta)
                    .foregroundStyle(PrepFlowColor.g2)
                    .monospacedDigit()
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
    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
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

    var body: some View {
        ScrollView {
            VStack(spacing: PrepFlowSpacing.md) {
                DishCard(title: "先付け", window: "T−4:00 窓", done: 1, total: 1, rows: [
                    DishTask(id: "dish-sakizuke-kobachi", title: "小鉢の仕込み", quantity: "14客", time: "14:00 ・ T−4:00", isDone: true, isNow: false, section: "ガルド"),
                ])
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
                ])
                DishCard(title: "椀物", window: "T−1:30 〜 T−1:00", done: 0, total: 2, rows: [
                    DishTask(id: "dish-wan-suiji", title: "吸地を引く", quantity: "14杯", time: "17:00 ・ T−1:00", isDone: false, isNow: false, section: "親方"),
                    DishTask(id: "dish-wan-wandane", title: "椀種の準備", quantity: "14客", time: "16:30 ・ T−1:30", isDone: false, isNow: false, section: "ガルド"),
                ])
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

            ForEach(rows) { row in
                DishTaskRow(task: row)
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
private struct DishTaskRow: View {
    let task: DishTask

    var body: some View {
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
}

// 正本: design/p1-wireframe-view-staff-liquidglass.png
private struct StaffBoardContent: View {
    let completed: Set<String>
    let toggle: (String) -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.none) {
            StaffColumn(initial: "シ", name: "シャリ場", done: 1, total: 1, tasks: [
                StaffTask(id: "staff-shari-rice", dish: "おまかせ握り", title: "米を炊く・赤酢", quantity: "米 2.0升", time: "T−4:00", isDone: true, isNow: false),
            ])
            StaffColumn(initial: "親", name: "親方", done: completed.intersection(["nikiri", "neta"]).count, total: 3, tasks: [
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
                StaffTask(id: "staff-chef-suiji", dish: "椀物", title: "吸地を引く", quantity: "14杯", time: "17:00 ・ T−1:00", isDone: false, isNow: false),
            ], toggle: toggle)
            StaffColumn(initial: "ガ", name: "ガルド", done: 0, total: 2, tasks: [
                StaffTask(id: "staff-garde-wandane", dish: "椀物", title: "椀種の準備", quantity: "14客", time: "16:30 ・ T−1:30", isDone: false, isNow: false),
                StaffTask(id: "staff-garde-sauce", dish: "水菓子", title: "ソースを炊く", quantity: "300ml", time: "16:00 ・ T−2:00", isDone: false, isNow: false),
            ])
            StaffColumn(initial: "長", name: "シェフ", done: 0, total: 1, tasks: [
                StaffTask(id: "staff-chef-line-check", dish: "全体", title: "ライン点検（全皿確認）", quantity: "", time: "17:30 ・ T−0:30", isDone: false, isNow: false),
            ])
        }
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
    var toggle: ((String) -> Void)?

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
                    ForEach(tasks) { task in
                        StaffTaskCard(task: task) {
                            toggle?(task.id.replacingOccurrences(of: "staff-chef-", with: ""))
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
