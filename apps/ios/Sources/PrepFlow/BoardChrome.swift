// 正本: design/p0-wireframe-board-liquidglass.png
import DesignTokens
import SwiftUI

// 正本: design/p0-wireframe-board-liquidglass.png
struct BoardBottomBar: View {
    let markAllDone: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.md) {
                LineGateBar()
                Spacer()
                GlassSecondaryButton(title: "手順・動画", systemImage: "play.fill")
                Button(action: markAllDone) {
                    Label("すべて完了 → 次へ", systemImage: "checkmark")
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
}

// 正本: design/p0-wireframe-board-liquidglass.png
struct LineGateBar: View {
    var body: some View {
        HStack(spacing: PrepFlowSpacing.sm) {
            Image(systemName: "checkmark")
                .font(PrepFlowFont.icon)
                .foregroundStyle(PrepFlowColor.white)
                .frame(width: PrepFlowSpacing.xl, height: PrepFlowSpacing.xl)
                .background(PrepFlowColor.white.opacity(PrepFlowOpacity.selection))
                .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
            VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                Text("ライン点検")
                    .font(PrepFlowFont.sectionTitle)
                    .foregroundStyle(PrepFlowColor.white)
                Text("全5皿そろって開店ゲート")
                    .font(PrepFlowFont.railMeta)
                    .foregroundStyle(PrepFlowColor.g3)
            }
            Text("17:30")
                .font(PrepFlowFont.chip)
                .foregroundStyle(PrepFlowColor.white)
                .monospacedDigit()
                .padding(.leading, PrepFlowSpacing.md)
        }
        .padding(.horizontal, PrepFlowSpacing.md)
        .padding(.vertical, PrepFlowSpacing.sm)
        .background(PrepFlowColor.ink.opacity(PrepFlowOpacity.darkGlass))
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .glassEffect()
    }
}

// 正本: design/p0-wireframe-board-liquidglass.png
private struct GlassSecondaryButton: View {
    let title: String
    let systemImage: String

    var body: some View {
        Button {} label: {
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
