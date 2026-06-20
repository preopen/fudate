// 正本: design/p0-wireframe-simulation-liquidglass.png
// 正本: design/p0-wireframe-activation-liquidglass.png
import DesignTokens
import Engine
import SwiftUI

// 正本: design/p0-wireframe-simulation-liquidglass.png
struct SimulationView: View {
    @StateObject private var store: BoardStore
    @State private var isCloseLoopPresented = false
    @State private var isReservationHubPresented = false
    @State private var closeMadeQty = 240
    @State private var closeLeftoverQty = 40
    @State private var closeReason = WasteReason.overmade
    @State private var closeCarriesOver = true
    private let openBoard: (() -> Void)?
    private let adjustNumbers: (() -> Void)?

    init(store: BoardStore = BoardStore(), openBoard: (() -> Void)? = nil, adjustNumbers: (() -> Void)? = nil) {
        _store = StateObject(wrappedValue: store)
        self.openBoard = openBoard
        self.adjustNumbers = adjustNumbers
    }

    var body: some View {
        ZStack(alignment: .top) {
            PrepFlowColor.g5.ignoresSafeArea()

            VStack(spacing: PrepFlowSpacing.md) {
                SimulationKPIGrid(summary: store.simulation, periodDays: store.simulationPeriodDays)

                HStack(spacing: PrepFlowSpacing.none) {
                    SimulationItemList(summary: store.simulation, periodDays: store.simulationPeriodDays)
                    SimulationResultPanel(
                        summary: store.simulation,
                        periodDays: store.simulationPeriodDays,
                        adjustmentSummary: store.simulationLastAdjustmentSummary,
                        appliedCount: store.simulationAppliedCount,
                        appliedAt: store.simulationAppliedAt,
                        boardImpactSummary: store.simulationBoardImpactSummary
                    ) {
                        store.applySimulationAdjustment()
                        adjustNumbers?()
                    } apply: {
                        store.applySimulationCoefficients()
                        store.recordNikiriWaste()
                        isCloseLoopPresented = true
                    }
                    .frame(width: PrepFlowMetric.railWidth)
                }
            }
            .padding(.top, PrepFlowMetric.topInset)

            SimulationTopBar(
                periodDays: store.simulationPeriodDays,
                dateRange: store.simulationDateRange,
                changePeriod: {
                    store.changeSimulationPeriod()
                },
                apply: {
                    store.applySimulationCoefficients()
                    store.recordNikiriWaste()
                    isCloseLoopPresented = true
                }
            )
            .padding(PrepFlowSpacing.md)
        }
        .foregroundStyle(PrepFlowColor.ink)
        .sheet(isPresented: $isCloseLoopPresented) {
            CloseLoopSheet(
                madeQty: $closeMadeQty,
                leftoverQty: $closeLeftoverQty,
                reason: $closeReason,
                carriesOver: $closeCarriesOver,
                batchRecords: store.closeGateRecords,
                learningRecords: store.latestLearningWasteRecords,
                summary: store.closeLoopSummary,
                commitCount: store.closeLoopCommitCount,
                canCommit: store.canCommitCloseLoop(
                    madeQty: Double(closeMadeQty),
                    leftoverQty: Double(closeLeftoverQty)
                ),
                nextDayReservations: store.closeNextDayPrepReservations,
                gateCompletedAt: store.closeGateCompletedAt,
                commit: {
                    store.recordCloseLoop(
                        madeQty: Double(closeMadeQty),
                        leftoverQty: Double(closeLeftoverQty),
                        wasteReason: closeReason,
                        carryoverToNext: closeCarriesOver
                    )
                },
                commitBatch: {
                    store.recordDefaultCloseGateBatch()
                },
                toggleNextDayReservation: { id in
                    store.toggleCloseNextDayPrepReservation(id)
                },
                completeGate: {
                    store.completeCloseGate()
                },
                openBoard: {
                    isCloseLoopPresented = false
                    openBoard?()
                },
                openReservationHub: {
                    isCloseLoopPresented = false
                    isReservationHubPresented = true
                }
            )
        }
        .sheet(isPresented: $isReservationHubPresented) {
            ReservationHubSheet(store: store) {
                isReservationHubPresented = false
                openBoard?()
            }
        }
    }
}

// 正本: design/p0-wireframe-activation-liquidglass.png
struct ActivationSummaryView: View {
    @StateObject private var store: BoardStore
    private let adjustNumbers: (() -> Void)?
    private let startFirstBoard: (() -> Void)?

    init(store: BoardStore = BoardStore(), adjustNumbers: (() -> Void)? = nil, startFirstBoard: (() -> Void)? = nil) {
        _store = StateObject(wrappedValue: store)
        self.adjustNumbers = adjustNumbers
        self.startFirstBoard = startFirstBoard
    }

    var body: some View {
        ZStack {
            PrepFlowColor.g5.ignoresSafeArea()

            ScrollView {
                VStack(spacing: PrepFlowSpacing.md) {
                    HStack(spacing: PrepFlowSpacing.xs) {
                        Image(systemName: "checkmark")
                            .font(PrepFlowFont.smallBold)
                        Text("あなたの過去2週間の予約・仕込みから試算しました")
                            .font(PrepFlowFont.smallBold)
                    }
                    .foregroundStyle(PrepFlowColor.ok)
                    .padding(.horizontal, PrepFlowSpacing.md)
                    .padding(.vertical, PrepFlowSpacing.xs)
                    .background(PrepFlowColor.ok.opacity(PrepFlowOpacity.timeNow))
                    .clipShape(Capsule(style: .continuous))

                    Text("PrepFlow なら、これだけ減らせます")
                        .font(PrepFlowFont.focusTitle)
                        .multilineTextAlignment(.center)

                    Text("業態テンプレを自店の数字で初期化。下の係数でそのまま運用を開始でき、以降は実績から自動補正で育ちます。")
                        .font(PrepFlowFont.body)
                        .foregroundStyle(PrepFlowColor.g2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: PrepFlowMetric.railWidth + PrepFlowMetric.catalogPreviewWidth)

                    ActivationNumbers(summary: store.simulation)
                    ActivationBars(items: Array(store.simulation.items.prefix(3)))
                }
                .padding(.horizontal, PrepFlowSpacing.xxl)
                .padding(.top, PrepFlowMetric.topInset)
                .padding(.bottom, PrepFlowMetric.bottomInset)
            }

            VStack(spacing: PrepFlowSpacing.md) {
                ActivationTopBar()
                Spacer()
                ActivationBottomBar(
                    adjustNumbers: {
                        adjustNumbers?()
                    },
                    apply: {
                        store.applySimulationCoefficients()
                        store.recordNikiriWaste()
                        startFirstBoard?()
                    }
                )
            }
            .padding(PrepFlowSpacing.md)
        }
        .foregroundStyle(PrepFlowColor.ink)
    }
}

// 正本: design/p0-wireframe-simulation-liquidglass.png
private struct SimulationTopBar: View {
    let periodDays: Int
    let dateRange: String
    let changePeriod: () -> Void
    let apply: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.md) {
                Text("SIMULATION ・ \(periodDays)日間")
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.g2)
                    .padding(.horizontal, PrepFlowSpacing.sm)
                    .padding(.vertical, PrepFlowSpacing.xs)
                    .background(PrepFlowColor.ink.opacity(PrepFlowOpacity.selection))
                    .clipShape(Capsule(style: .continuous))

                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("実績 vs 推奨")
                        .font(PrepFlowFont.topTitle)
                    Text("鮨 はやし ・ \(dateRange)（過去予約\(periodDays)日分で試算）")
                        .font(PrepFlowFont.topSubtitle)
                        .foregroundStyle(PrepFlowColor.g2)
                }

                Spacer()

                Button("期間を変更", action: changePeriod)
                    .buttonStyle(SimulationGlassButtonStyle())
                Button("本適用する", action: apply)
                    .buttonStyle(SimulationPrimaryButtonStyle())
            }
            .padding(.horizontal, PrepFlowSpacing.lg)
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

// 正本: design/p0-wireframe-simulation-liquidglass.png
private struct SimulationKPIGrid: View {
    let summary: SimulationSummary
    let periodDays: Int

    var body: some View {
        HStack(spacing: PrepFlowSpacing.md) {
            KPIBox(title: "推奨で減らせた食材量", value: summary.reductionText, detail: "過剰仕込みの平均", state: .ok)
            KPIBox(title: "推定の食材ロス削減", value: summary.lossSavingText, detail: "\(periodDays)日換算", state: .ok)
            KPIBox(title: "品切れリスク", value: "\(summary.stockoutRisks)件", detail: "要・安全係数の上乗せ", state: .time)
            KPIBox(title: "推奨の的中率", value: "\(summary.hitRatePercent)%", detail: "±10%以内", state: .neutral)
        }
        .padding(.horizontal, PrepFlowSpacing.lg)
    }
}

private enum KPIState {
    case ok
    case time
    case neutral
}

// 正本: design/p0-wireframe-simulation-liquidglass.png
private struct KPIBox: View {
    let title: String
    let value: String
    let detail: String
    let state: KPIState

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            Text(title)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Text(value)
                .font(PrepFlowFont.iconLarge)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(PrepFlowMetric.textMinimumScale)
            Text(detail)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(detailColor)
        }
        .padding(PrepFlowSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private var valueColor: Color {
        state == .time ? PrepFlowColor.time : PrepFlowColor.ink // time-use: stockout risk count
    }

    private var detailColor: Color {
        switch state {
        case .ok:
            PrepFlowColor.ok
        case .time:
            PrepFlowColor.time // time-use: urgent stockout risk detail
        case .neutral:
            PrepFlowColor.g2
        }
    }
}

// 正本: design/p0-wireframe-simulation-liquidglass.png
private struct SimulationItemList: View {
    let summary: SimulationSummary
    let periodDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            HStack {
                Text("仕込みアイテム別（\(periodDays)日平均・1営業あたり）")
                    .font(PrepFlowFont.sectionTitle)
                Spacer()
                Text("実績")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
                Text("推奨")
                    .font(PrepFlowFont.railMeta)
            }

            ForEach(summary.items) { item in
                SimulationItemRow(item: item)
            }
        }
        .padding(.horizontal, PrepFlowSpacing.lg)
        .padding(.bottom, PrepFlowSpacing.lg)
    }
}

// 正本: design/p0-wireframe-simulation-liquidglass.png
private struct SimulationItemRow: View {
    let item: SimulationItem

    var body: some View {
        HStack(spacing: PrepFlowSpacing.md) {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(item.name)
                    .font(PrepFlowFont.bodyBold)
                Text(item.note)
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            .frame(width: PrepFlowMetric.catalogPreviewWidth / 2, alignment: .leading)

            VStack(spacing: PrepFlowSpacing.xs) {
                SimulationBar(label: "実績", ratio: item.actualRatio, value: valueText(item.actual), unit: item.unit, isRecommended: false)
                SimulationBar(label: "推奨", ratio: item.recommendedRatio, value: valueText(item.recommended), unit: item.unit, isRecommended: true)
            }

            Text(item.deltaLabel)
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(deltaColor)
                .monospacedDigit()
                .frame(width: PrepFlowMetric.actionButtonHeight + PrepFlowSpacing.xl, alignment: .trailing)
        }
        .padding(.vertical, PrepFlowSpacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(height: PrepFlowMetric.lineWidth)
        }
    }

    private var deltaColor: Color {
        switch item.outcome {
        case .save:
            PrepFlowColor.ok
        case .risk:
            PrepFlowColor.time // time-use: stockout risk delta
        case .neutral:
            PrepFlowColor.g2
        }
    }

    private func valueText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 1)))
    }
}

// 正本: design/p0-wireframe-simulation-liquidglass.png
private struct SimulationBar: View {
    let label: String
    let ratio: Double
    let value: String
    let unit: String
    let isRecommended: Bool

    var body: some View {
        HStack(spacing: PrepFlowSpacing.xs) {
            Text(label)
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(PrepFlowColor.g2)
                .frame(width: PrepFlowSpacing.xxl, alignment: .leading)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous)
                        .fill(PrepFlowColor.g5)
                    RoundedRectangle(cornerRadius: PrepFlowRadius.sm, style: .continuous)
                        .fill(isRecommended ? PrepFlowColor.ink : PrepFlowColor.g3)
                        .frame(width: proxy.size.width * min(max(ratio, 0), 1))
                }
            }
            .frame(height: PrepFlowSpacing.md)

            Text("\(value)\(unit)")
                .font(PrepFlowFont.railMeta)
                .monospacedDigit()
                .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .trailing)
        }
    }
}

// 正本: design/p0-wireframe-simulation-liquidglass.png
private struct SimulationResultPanel: View {
    let summary: SimulationSummary
    let periodDays: Int
    let adjustmentSummary: String?
    let appliedCount: Int
    let appliedAt: String?
    let boardImpactSummary: String?
    let adjust: () -> Void
    let apply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.md) {
            Text("結果サマリー")
                .font(PrepFlowFont.sectionTitle)
            Text("\(periodDays)日間の予約実績に対して、推奨量を当てたときの差。")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)

            VStack(spacing: PrepFlowSpacing.xs) {
                Text(summary.reductionText)
                    .font(PrepFlowFont.focusTitle)
                    .monospacedDigit()
                Text("過剰仕込みの平均削減")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
                Text("＝ 食材ロス 約\(summary.lossSavingText)／14日")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.ok)
            }
            .padding(PrepFlowSpacing.md)
            .frame(maxWidth: .infinity)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                    .stroke(PrepFlowColor.ink, lineWidth: PrepFlowMetric.heavyLineWidth)
            }

            SummaryMiniRow(title: "推奨が的中（±10%）", value: "\(summary.hitRatePercent)%")
            SummaryMiniRow(title: "作りすぎを削減", value: "11品")
            SummaryMiniRow(title: "品切れリスク", value: "\(summary.stockoutRisks)品")

            Text("品切れリスクの2品は安全係数を+10%して本適用。各係数はこの\(periodDays)日で初期化されます。")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)

            if let adjustmentSummary {
                SimulationStatusBox(
                    title: "調整履歴",
                    bodyText: adjustmentSummary,
                    detail: "数字を調整すると推奨量とリスク件数を即時更新します。"
                )
            }

            if let boardImpactSummary {
                SimulationStatusBox(
                    title: "本適用済み",
                    bodyText: boardImpactSummary,
                    detail: "適用 \(appliedCount)回\(appliedAt.map { " ・ \($0)" } ?? "")"
                )
            }

            Spacer()

            if adjustmentSummary != nil {
                Button("数字を再調整", action: adjust)
                    .buttonStyle(SimulationSecondaryWideButtonStyle())
            }
            Button("この係数で本適用する", action: apply)
                .buttonStyle(SimulationPrimaryWideButtonStyle())
            Text("本適用後も実績から自動補正が続きます（FR-09）")
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(PrepFlowSpacing.lg)
        .background(PrepFlowColor.white.opacity(PrepFlowOpacity.contentHeader))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(width: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p0-wireframe-simulation-liquidglass.png
private struct SimulationStatusBox: View {
    let title: String
    let bodyText: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            Text(title)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Text(bodyText)
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(PrepFlowColor.ink)
            Text(detail)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
        }
        .padding(PrepFlowSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p0-wireframe-simulation-liquidglass.png
private struct SummaryMiniRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(PrepFlowFont.small)
                .foregroundStyle(PrepFlowColor.g2)
            Spacer()
            Text(value)
                .font(PrepFlowFont.smallBold)
                .monospacedDigit()
        }
        .padding(.vertical, PrepFlowSpacing.xs)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(height: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p0-wireframe-activation-liquidglass.png
private struct ActivationTopBar: View {
    var body: some View {
        GlassEffectContainer {
            HStack {
                Text("セットアップ")
                    .font(PrepFlowFont.topTitle)
                Spacer()
                HStack(spacing: PrepFlowSpacing.sm) {
                    ActivationStep(title: "業態を選ぶ", mark: "✓", state: .done)
                    ActivationStepSeparator()
                    ActivationStep(title: "削減を見る", mark: "2", state: .current)
                    ActivationStepSeparator()
                    ActivationStep(title: "初回ボード", mark: "3", state: .pending)
                }
            }
            .padding(.horizontal, PrepFlowSpacing.lg)
            .frame(height: PrepFlowMetric.topBarHeight)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous)
                    .stroke(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke), lineWidth: PrepFlowMetric.lineWidth)
            }
            .glassEffect()
        }
    }
}

private enum ActivationStepState {
    case done
    case current
    case pending
}

// 正本: design/p0-wireframe-activation-liquidglass.png
private struct ActivationStep: View {
    let title: String
    let mark: String
    let state: ActivationStepState

    var body: some View {
        HStack(spacing: PrepFlowSpacing.xs) {
            Text(mark)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(markColor)
                .frame(width: PrepFlowSpacing.lg, height: PrepFlowSpacing.lg)
                .background(dotColor)
                .clipShape(Circle())
            Text(title)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(titleColor)
        }
    }

    private var dotColor: Color {
        switch state {
        case .done:
            PrepFlowColor.ok
        case .current:
            PrepFlowColor.ink
        case .pending:
            PrepFlowColor.ink.opacity(PrepFlowOpacity.selection)
        }
    }

    private var markColor: Color {
        state == .pending ? PrepFlowColor.g2 : PrepFlowColor.white
    }

    private var titleColor: Color {
        switch state {
        case .done:
            PrepFlowColor.ok
        case .current:
            PrepFlowColor.ink
        case .pending:
            PrepFlowColor.g2
        }
    }
}

// 正本: design/p0-wireframe-activation-liquidglass.png
private struct ActivationStepSeparator: View {
    var body: some View {
        Rectangle()
            .fill(PrepFlowColor.ink.opacity(PrepFlowOpacity.selection))
            .frame(width: PrepFlowSpacing.lg, height: PrepFlowMetric.timelineRuleWidth)
    }
}

// 正本: design/p0-wireframe-activation-liquidglass.png
private struct ActivationNumbers: View {
    let summary: SimulationSummary

    var body: some View {
        HStack(spacing: PrepFlowSpacing.md) {
            ActivationNumber(title: "過剰仕込みの平均削減", value: summary.reductionText, detail: "作りすぎを抑制", isHero: true)
            ActivationNumber(title: "推定の食材ロス削減", value: summary.lossSavingText, detail: "14日換算（参考・概算）")
            ActivationNumber(title: "推奨の的中率", value: "\(summary.hitRatePercent)%", detail: "±10%以内")
        }
        .frame(maxWidth: PrepFlowMetric.railWidth + PrepFlowMetric.catalogTreeWidth)
    }
}

// 正本: design/p0-wireframe-activation-liquidglass.png
private struct ActivationNumber: View {
    let title: String
    let value: String
    let detail: String
    var isHero = false

    var body: some View {
        VStack(spacing: PrepFlowSpacing.xs) {
            Text(title)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Text(value)
                .font(PrepFlowFont.focusTitle)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(PrepFlowMetric.textMinimumScale)
            Text(detail)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(isHero ? PrepFlowColor.ok : PrepFlowColor.g2)
        }
        .padding(PrepFlowSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.xl, style: .continuous)
                .stroke(isHero ? PrepFlowColor.ink : PrepFlowColor.g4, lineWidth: isHero ? PrepFlowMetric.heavyLineWidth : PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p0-wireframe-activation-liquidglass.png
private struct ActivationBars: View {
    let items: [SimulationItem]

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            Text("アイテム別：実際に作った量 vs PrepFlow推奨")
                .font(PrepFlowFont.sectionTitle)
            ForEach(items) { item in
                HStack {
                    Text(item.name)
                        .font(PrepFlowFont.smallBold)
                        .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .leading)
                    VStack(spacing: PrepFlowSpacing.xs) {
                        SimulationBar(label: "実績", ratio: item.actualRatio, value: "", unit: "", isRecommended: false)
                        SimulationBar(label: "推奨", ratio: item.recommendedRatio, value: "", unit: "", isRecommended: true)
                    }
                    Text(item.deltaLabel)
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(PrepFlowColor.ok)
                        .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .trailing)
                }
            }
        }
        .padding(PrepFlowSpacing.md)
        .frame(maxWidth: PrepFlowMetric.railWidth + PrepFlowMetric.catalogTreeWidth)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p0-wireframe-activation-liquidglass.png
private struct ActivationBottomBar: View {
    let adjustNumbers: () -> Void
    let apply: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack {
                HStack(spacing: PrepFlowSpacing.none) {
                    Text("残り ")
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(PrepFlowColor.g2)
                    Text("あと約8分")
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(PrepFlowColor.ink)
                    Text(" で初回ボード生成 ・ ステップ 2/3")
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(PrepFlowColor.g2)
                }
                Spacer()
                Button("数字を調整", action: adjustNumbers)
                    .buttonStyle(SimulationGlassButtonStyle())
                Button("この係数で始める → 初回ボード", action: apply)
                    .buttonStyle(SimulationPrimaryButtonStyle())
            }
            .padding(.horizontal, PrepFlowSpacing.lg)
            .frame(height: PrepFlowMetric.bottomBarHeight)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous)
                    .stroke(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke), lineWidth: PrepFlowMetric.lineWidth)
            }
            .glassEffect()
        }
    }
}

private struct SimulationGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.ink)
            .padding(.horizontal, PrepFlowSpacing.md)
            .padding(.vertical, PrepFlowSpacing.sm)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke), lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : 1)
            .glassEffect()
    }
}

private struct SimulationPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.white)
            .padding(.horizontal, PrepFlowSpacing.lg)
            .padding(.vertical, PrepFlowSpacing.sm)
            .background(PrepFlowColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : 1)
    }
}

private struct SimulationPrimaryWideButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.action)
            .foregroundStyle(PrepFlowColor.white)
            .frame(maxWidth: .infinity, minHeight: PrepFlowMetric.actionButtonHeight)
            .background(PrepFlowColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .shadow(color: PrepFlowColor.ink.opacity(PrepFlowOpacity.glassShadow), radius: PrepFlowSpacing.md, y: PrepFlowSpacing.xs)
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : 1)
    }
}

private struct SimulationSecondaryWideButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.ink)
            .frame(maxWidth: .infinity, minHeight: PrepFlowMetric.catalogFieldHeight)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : 1)
    }
}
