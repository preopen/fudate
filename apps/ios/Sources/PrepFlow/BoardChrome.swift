// 正本: design/p0-wireframe-board-liquidglass.png
import DesignTokens
import SwiftUI

// 正本: design/p0-wireframe-board-liquidglass.png
struct BoardBottomBar: View {
    let status: LineGateStatus
    let openGuidance: () -> Void
    let markAllDone: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.md) {
                LineGateBar(status: status)
                Spacer()
                GlassSecondaryButton(title: "手順・動画", systemImage: "play.fill", action: openGuidance)
                Button(action: markAllDone) {
                    Label(primaryActionTitle, systemImage: status.canOpen ? "tag.fill" : "checkmark")
                        .font(PrepFlowFont.action)
                        .foregroundStyle(PrepFlowColor.white)
                        .frame(height: PrepFlowMetric.actionButtonHeight)
                        .padding(.horizontal, PrepFlowSpacing.xl)
                        .background(PrepFlowColor.ink)
                        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, PrepFlowSpacing.md)
            .frame(height: PrepFlowMetric.bottomBarHeight)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xxxl, style: .continuous))
            .glassEffect()
        }
    }

    private var primaryActionTitle: String {
        status.canOpen ? "ラベルへ進む" : "未解決を確認"
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
struct LineGateBar: View {
    var status: LineGateStatus?

    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            Image(systemName: iconName)
                .font(PrepFlowFont.icon)
                .foregroundStyle(PrepFlowColor.white)
                .frame(width: PrepFlowSpacing.xl, height: PrepFlowSpacing.xl)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text(title)
                    .font(PrepFlowFont.sectionTitle)
                    .foregroundStyle(PrepFlowColor.white)
                Text(detail)
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g3)
            }
            Text(timeText)
                .font(PrepFlowFont.chip)
                .foregroundStyle(timeColor)
                .monospacedDigit()
                .padding(.leading, PrepFlowSpacing.md)
        }
        .padding(.horizontal, PrepFlowSpacing.md)
        .padding(.vertical, PrepFlowSpacing.sm)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(strokeColor, lineWidth: PrepFlowMetric.lineWidth)
        }
        .glassEffect()
    }

    private var resolved: LineGateStatus? {
        status
    }

    private var title: String {
        guard let resolved else {
            return "ライン点検"
        }
        return resolved.canOpen ? "開店ゲートOK" : "開店ゲート未解決"
    }

    private var detail: String {
        guard let resolved else {
            return "全5皿そろって開店ゲート"
        }
        if resolved.unresolvedImpactCount > 0 {
            return "外部変化 \(resolved.unresolvedImpactCount)件を手順へ追加"
        }
        if resolved.recheckCount > 0 {
            return "返信変更の再確認 \(resolved.recheckCount)件"
        }
        if resolved.labelReprintRequired {
            return "席札再印刷待ち"
        }
        if resolved.completedCount < resolved.totalCount {
            return "\(resolved.completedCount) / \(resolved.totalCount) 工程完了"
        }
        return resolved.lastAction
    }

    private var iconName: String {
        resolved?.canOpen == true ? "checkmark" : "exclamationmark"
    }

    private var timeText: String {
        guard let resolved else {
            return "17:30"
        }
        return resolved.canOpen ? "17:30" : "\(resolved.blockingCount)"
    }

    private var timeColor: Color {
        resolved?.canOpen == false ? PrepFlowColor.time : PrepFlowColor.white // time-use: line gate blocking count before open
    }

    private var iconBackground: Color {
        resolved?.canOpen == false ? PrepFlowColor.time : PrepFlowColor.white.opacity(PrepFlowOpacity.selection) // time-use: line gate block icon
    }

    private var backgroundColor: Color {
        resolved?.canOpen == false ? PrepFlowColor.ink.opacity(PrepFlowOpacity.darkGlass) : PrepFlowColor.ink.opacity(PrepFlowOpacity.darkGlass)
    }

    private var strokeColor: Color {
        resolved?.canOpen == false ? PrepFlowColor.time.opacity(PrepFlowOpacity.timeStroke) : PrepFlowColor.clear // time-use: line gate block stroke
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct GlassSecondaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(PrepFlowFont.chip)
                .foregroundStyle(PrepFlowColor.ink)
                .frame(height: PrepFlowMetric.actionButtonHeight)
                .padding(.horizontal, PrepFlowSpacing.lg)
                .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
                .glassEffect()
        }
        .buttonStyle(.plain)
    }
}
