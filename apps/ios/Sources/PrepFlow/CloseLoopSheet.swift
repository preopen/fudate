// 正本: design/p2-wireframe-close-flow-liquidglass.png
import DesignTokens
import Engine
import SwiftUI

// 正本: design/p2-wireframe-close-flow-liquidglass.png
struct CloseLoopSheet: View {
    @Binding var madeQty: Int
    @Binding var leftoverQty: Int
    @Binding var reason: WasteReason
    @Binding var carriesOver: Bool
    let batchRecords: [CloseTaskRecord]
    let learningRecords: [WasteRecord]
    let summary: CloseLoopSummary?
    let commitCount: Int
    let canCommit: Bool
    let nextDayReservations: [CloseNextDayPrepReservation]
    let gateCompletedAt: String?
    let commit: () -> Void
    let commitBatch: () -> Void
    let toggleNextDayReservation: (String) -> Void
    let completeGate: () -> Void
    let openBoard: () -> Void
    let openReservationHub: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.lg) {
                Capsule(style: .continuous)
                    .fill(PrepFlowColor.g4)
                    .frame(width: PrepFlowMetric.actionButtonHeight, height: PrepFlowMetric.lineWidth)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                    Text("締め → 翌日")
                        .font(PrepFlowFont.sectionTitle)
                        .foregroundStyle(PrepFlowColor.g2)
                    Text("本日のパー・廃棄記録")
                        .font(PrepFlowFont.focusTitle)
                    Text("予約 → 作った → 余ったを記録し、余りを繰越か廃棄に振り分けます。")
                        .font(PrepFlowFont.body)
                        .foregroundStyle(PrepFlowColor.g2)
                }

                HStack(alignment: .top, spacing: PrepFlowSpacing.md) {
                    VStack(spacing: PrepFlowSpacing.md) {
                        HStack(spacing: PrepFlowSpacing.md) {
                            CloseLoopQtyStepper(title: "作った", value: $madeQty, unit: "ml", step: CloseLoopInputStep.made)
                            CloseLoopQtyStepper(title: "余り", value: $leftoverQty, unit: "ml", step: CloseLoopInputStep.leftover)
                        }

                        HStack(spacing: PrepFlowSpacing.md) {
                            CloseLoopDecisionPicker(carriesOver: $carriesOver)
                            CloseLoopReasonPicker(reason: $reason, isEnabled: !carriesOver)
                        }

                        CloseLoopBatchTable(records: batchRecords, learningRecords: learningRecords)
                    }

                    VStack(spacing: PrepFlowSpacing.md) {
                        CloseLoopPreview(summary: summary, carriesOver: carriesOver, leftoverQty: leftoverQty)
                        CloseLoopNextDayPanel(reservations: nextDayReservations, toggle: toggleNextDayReservation)
                        CloseLoopCommitStatus(commitCount: commitCount, canCommit: canCommit, gateCompletedAt: gateCompletedAt)
                    }
                    .frame(width: PrepFlowMetric.railWidth)
                }

                HStack(spacing: PrepFlowSpacing.md) {
                    Button(commitCount > 0 ? "単品を上書き" : "単品を記録", action: commit)
                        .buttonStyle(SheetSecondaryWideButtonStyle(isEnabled: canCommit))
                        .disabled(!canCommit)
                    Button("締め表を記録", action: commitBatch)
                        .buttonStyle(CloseLoopPrimaryWideButtonStyle())
                    Button("締めゲート完了", action: completeGate)
                        .buttonStyle(SheetSecondaryWideButtonStyle(isEnabled: summary != nil))
                        .disabled(summary == nil)
                    Button("予約差分へ", action: openReservationHub)
                        .buttonStyle(SheetSecondaryWideButtonStyle(isEnabled: summary != nil))
                        .disabled(summary == nil)
                    Button("明日のボードへ", action: openBoard)
                        .buttonStyle(SheetSecondaryWideButtonStyle(isEnabled: gateCompletedAt != nil))
                        .disabled(gateCompletedAt == nil)
                }
            }
            .padding(PrepFlowSpacing.xl)
        }
        .background(PrepFlowColor.g5)
        .presentationDetents([.large])
    }
}

// 正本: design/p2-wireframe-close-flow-liquidglass.png
private struct CloseLoopCommitStatus: View {
    let commitCount: Int
    let canCommit: Bool
    let gateCompletedAt: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
            HStack(spacing: PrepFlowSpacing.sm) {
                Text(statusTitle)
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(canCommit ? PrepFlowColor.ink : PrepFlowColor.time) // time-use: close blocking validation
                Spacer()
                Text(statusDetail)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(canCommit ? PrepFlowColor.g2 : PrepFlowColor.time) // time-use: close blocking validation detail
            }

            if let gateCompletedAt {
                Text("締めゲート完了 \(gateCompletedAt)")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }
        }
        .padding(.horizontal, PrepFlowSpacing.md)
        .padding(.vertical, PrepFlowSpacing.sm)
        .background(canCommit ? PrepFlowColor.white : PrepFlowColor.time.opacity(PrepFlowOpacity.timeSoft)) // time-use: close blocking validation background
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(statusBorder, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private var statusTitle: String {
        guard canCommit else {
            return "入力を確認"
        }
        return commitCount > 0 ? "記録済み" : "未記録"
    }

    private var statusDetail: String {
        guard canCommit else {
            return "余りは作った量以下にしてください"
        }
        return commitCount > 0 ? "必要なら数値を直して上書きできます" : "記録後に翌日推奨へ反映されます"
    }

    private var statusBorder: Color {
        canCommit ? PrepFlowColor.g4 : PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) // time-use: close blocking validation stroke
    }
}

// 正本: design/p2-wireframe-close-nextday-liquidglass.png
private struct CloseLoopBatchTable: View {
    let records: [CloseTaskRecord]
    let learningRecords: [WasteRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("③ パー・廃棄記録")
                        .font(PrepFlowFont.sectionTitle)
                    Text("複数品目を締め、作りすぎだけ自己補正へ流します。")
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                }
                Spacer()
                Text("FR-08/68")
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.g2)
                    .padding(.horizontal, PrepFlowSpacing.sm)
                    .padding(.vertical, PrepFlowSpacing.xxs)
                    .background(PrepFlowColor.g5)
                    .clipShape(Capsule(style: .continuous))
            }

            VStack(spacing: PrepFlowSpacing.none) {
                CloseLoopBatchHeader()
                ForEach(Array(records.enumerated()), id: \.offset) { index, record in
                    CloseLoopBatchRow(record: record, learningRecord: learningRecords[safe: index])
                }
            }
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                    .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }

            CloseLoopLearningFeed(learningRecords: learningRecords)
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

// 正本: design/p2-wireframe-close-flow-liquidglass.png
private struct CloseLoopBatchHeader: View {
    var body: some View {
        HStack {
            Text("品目")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("作った")
                .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .trailing)
            Text("余り")
                .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .trailing)
            Text("判定")
                .frame(width: PrepFlowMetric.topBarHeight, alignment: .center)
            Text("学習")
                .frame(width: PrepFlowMetric.topBarHeight, alignment: .center)
        }
        .font(PrepFlowFont.countdownLabel)
        .foregroundStyle(PrepFlowColor.g2)
        .padding(.horizontal, PrepFlowSpacing.md)
        .padding(.vertical, PrepFlowSpacing.sm)
        .background(PrepFlowColor.g5)
    }
}

// 正本: design/p2-wireframe-close-flow-liquidglass.png
private struct CloseLoopBatchRow: View {
    let record: CloseTaskRecord
    let learningRecord: WasteRecord?

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(displayName)
                    .font(PrepFlowFont.bodyBold)
                Text(record.task)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(closeValueText(record.madeQty))\(record.unit)")
                .font(PrepFlowFont.smallBold)
                .monospacedDigit()
                .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .trailing)

            Text("\(closeValueText(record.leftoverQty))\(record.unit)")
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(record.carryoverToNext ? PrepFlowColor.ink : PrepFlowColor.time) // time-use: waste quantity
                .monospacedDigit()
                .frame(width: PrepFlowMetric.actionButtonHeight, alignment: .trailing)

            Text(record.carryoverToNext ? "繰越" : "廃棄")
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(record.carryoverToNext ? PrepFlowColor.ink : PrepFlowColor.time) // time-use: waste decision
                .frame(width: PrepFlowMetric.topBarHeight)
                .padding(.vertical, PrepFlowSpacing.xs)
                .background(record.carryoverToNext ? PrepFlowColor.g5 : PrepFlowColor.time.opacity(PrepFlowOpacity.timeSoft)) // time-use: waste decision background
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))

            Text(learningRecord?.exclude == true ? "除外" : "対象")
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(learningRecord?.exclude == true ? PrepFlowColor.g2 : PrepFlowColor.ink)
                .frame(width: PrepFlowMetric.topBarHeight)
        }
        .padding(.horizontal, PrepFlowSpacing.md)
        .padding(.vertical, PrepFlowSpacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(height: PrepFlowMetric.lineWidth)
        }
    }

    private var displayName: String {
        switch record.task {
        case "task-nikiri":
            "煮切り"
        case "task-tai-kombu":
            "鯛の昆布締め"
        case "task-anago-tsume":
            "穴子のツメ"
        case "task-aemono":
            "先付けの和え物"
        default:
            record.task
        }
    }
}

// 正本: design/p2-wireframe-close-flow-liquidglass.png
private struct CloseLoopLearningFeed: View {
    let learningRecords: [WasteRecord]

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(PrepFlowFont.icon)
                .foregroundStyle(PrepFlowColor.ok)
            Text(feedText)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Spacer()
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }

    private var feedText: String {
        guard !learningRecords.isEmpty else {
            return "締め表を記録すると、作りすぎ由来のみ自己補正へ流れます。"
        }
        let included = learningRecords.count { !$0.exclude }
        let excluded = learningRecords.count { $0.exclude }
        return "自己補正対象 \(included)件 / 品質・期限などの除外 \(excluded)件"
    }
}

// 正本: design/p2-wireframe-close-nextday-liquidglass.png
private struct CloseLoopNextDayPanel: View {
    let reservations: [CloseNextDayPrepReservation]
    let toggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text("⑤ 翌日の前倒し仕込み")
                    .font(PrepFlowFont.sectionTitle)
                Text("今夜着手をONにしたものは明日のボードへ引き継ぎます。")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }

            ForEach(reservations) { reservation in
                CloseLoopNextDayRow(reservation: reservation) {
                    toggle(reservation.id)
                }
            }
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

// 正本: design/p2-wireframe-close-nextday-liquidglass.png
private struct CloseLoopNextDayRow: View {
    let reservation: CloseNextDayPrepReservation
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(reservation.title)
                    .font(PrepFlowFont.bodyBold)
                Text(reservation.detail)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }
            Spacer()
            Text(reservation.timing)
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(PrepFlowColor.ink)
                .padding(.horizontal, PrepFlowSpacing.sm)
                .padding(.vertical, PrepFlowSpacing.xxs)
                .background(PrepFlowColor.g5)
                .clipShape(Capsule(style: .continuous))
            Button(reservation.isReserved ? "ON" : "OFF", action: toggle)
                .buttonStyle(CloseLoopToggleButtonStyle(isOn: reservation.isReserved))
        }
        .padding(PrepFlowSpacing.sm)
        .background(PrepFlowColor.g5)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

private enum CloseLoopInputStep {
    static let made = 10
    static let leftover = 5
}

// 正本: design/p2-wireframe-close-flow-liquidglass.png
private struct CloseLoopQtyStepper: View {
    let title: String
    @Binding var value: Int
    let unit: String
    let step: Int

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            Text(title)
                .font(PrepFlowFont.sectionTitle)
                .foregroundStyle(PrepFlowColor.g2)
            HStack {
                Button("−") {
                    value = max(0, value - step)
                }
                .buttonStyle(SmallStepperButtonStyle())
                Text("\(value)\(unit)")
                    .font(PrepFlowFont.focusTitle)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
                Button("+") {
                    value += step
                }
                .buttonStyle(SmallStepperButtonStyle())
            }
        }
        .padding(PrepFlowSpacing.md)
        .frame(maxWidth: .infinity)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p2-wireframe-close-flow-liquidglass.png
private struct CloseLoopDecisionPicker: View {
    @Binding var carriesOver: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            Text("判定")
                .font(PrepFlowFont.sectionTitle)
                .foregroundStyle(PrepFlowColor.g2)
            HStack(spacing: PrepFlowSpacing.sm) {
                CloseLoopChoiceButton(title: "繰越", isSelected: carriesOver) {
                    carriesOver = true
                }
                CloseLoopChoiceButton(title: "廃棄", isSelected: !carriesOver) {
                    carriesOver = false
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 正本: design/p2-wireframe-close-flow-liquidglass.png
private struct CloseLoopReasonPicker: View {
    @Binding var reason: WasteReason
    let isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            Text("廃棄理由")
                .font(PrepFlowFont.sectionTitle)
                .foregroundStyle(PrepFlowColor.g2)
            HStack(spacing: PrepFlowSpacing.sm) {
                ForEach([WasteReason.overmade, .expiry, .quality], id: \.self) { option in
                    CloseLoopChoiceButton(
                        title: option.displayTitle,
                        isSelected: reason == option && isEnabled
                    ) {
                        reason = option
                    }
                    .disabled(!isEnabled)
                }
            }
        }
        .opacity(isEnabled ? PrepFlowOpacity.solid : PrepFlowOpacity.selection)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 正本: design/p2-wireframe-close-flow-liquidglass.png
private struct CloseLoopChoiceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(isSelected ? PrepFlowColor.white : PrepFlowColor.ink)
            .padding(.horizontal, PrepFlowSpacing.md)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .background(isSelected ? PrepFlowColor.ink : PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous)
                    .stroke(isSelected ? PrepFlowColor.ink : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
    }
}

// 正本: design/p2-wireframe-close-flow-liquidglass.png
private struct CloseLoopPreview: View {
    let summary: CloseLoopSummary?
    let carriesOver: Bool
    let leftoverQty: Int

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            Text("翌日プレビュー")
                .font(PrepFlowFont.sectionTitle)
                .foregroundStyle(PrepFlowColor.g2)
            if let adjustment = summary?.nextDayAdjustments.first {
                CloseLoopSummaryRow(title: "明日の基準", value: "\(valueText(adjustment.base))\(adjustment.unit)")
                CloseLoopSummaryRow(title: "繰越差引後", value: "\(valueText(adjustment.adjusted))\(adjustment.unit)")
                Text("この実績は自己補正レシピへ環流し、作りすぎ以外の廃棄は学習から除外されます。")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            } else {
                Text(carriesOver ? "\(leftoverQty)ml を繰越候補として記録します。" : "\(leftoverQty)ml を廃棄として記録します。")
                    .font(PrepFlowFont.body)
                    .foregroundStyle(PrepFlowColor.ink)
                Text("記録後に明日の推奨量がここへ表示されます。")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g2)
            }
        }
        .padding(PrepFlowSpacing.md)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }

    private func valueText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 1)))
    }
}

// 正本: design/p2-wireframe-close-flow-liquidglass.png
private struct CloseLoopSummaryRow: View {
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

private extension WasteReason {
    var displayTitle: String {
        switch self {
        case .overmade:
            "作りすぎ"
        case .expiry:
            "期限"
        case .quality:
            "品質"
        case .other:
            "その他"
        }
    }
}

private struct CloseLoopPrimaryWideButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.action)
            .foregroundStyle(PrepFlowColor.white)
            .frame(maxWidth: .infinity, minHeight: PrepFlowMetric.actionButtonHeight)
            .background(PrepFlowColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .shadow(color: PrepFlowColor.ink.opacity(PrepFlowOpacity.glassShadow), radius: PrepFlowSpacing.md, y: PrepFlowSpacing.xs)
            .opacity(configuration.isPressed ? PrepFlowOpacity.contentHeader : PrepFlowOpacity.solid)
    }
}

private struct SmallStepperButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.action)
            .foregroundStyle(PrepFlowColor.ink)
            .frame(width: PrepFlowMetric.catalogFieldHeight, height: PrepFlowMetric.catalogFieldHeight)
            .background(PrepFlowColor.g5)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private struct SheetSecondaryWideButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.action)
            .foregroundStyle(isEnabled ? PrepFlowColor.ink : PrepFlowColor.g2)
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

private struct CloseLoopToggleButtonStyle: ButtonStyle {
    let isOn: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(isOn ? PrepFlowColor.white : PrepFlowColor.g2)
            .frame(width: PrepFlowMetric.actionButtonHeight, height: PrepFlowMetric.catalogFieldHeight)
            .background(isOn ? PrepFlowColor.ink : PrepFlowColor.white)
            .clipShape(Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(isOn ? PrepFlowColor.ink : PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
            }
            .opacity(configuration.isPressed ? PrepFlowOpacity.pressed : PrepFlowOpacity.solid)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private func closeValueText(_ value: Double) -> String {
    value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
}
