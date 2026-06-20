// 正本: design/p1-wireframe-settings-home-liquidglass.png
import DesignTokens
import SwiftUI

struct SettingsHomeView: View {
    let session: AuthSession
    let authEnvironment: AuthEnvironment
    @ObservedObject var store: BoardStore
    let backToBoard: () -> Void
    let signOut: () -> Void
    var openServiceSetup: (() -> Void)?
    var openCatalog: (() -> Void)?
    var openSimulation: (() -> Void)?

    @State private var toastMessage = "保存しました（追い仕込み閾値 25%）"

    init(
        session: AuthSession,
        authEnvironment: AuthEnvironment = .current,
        store: BoardStore = BoardStore(database: nil),
        backToBoard: @escaping () -> Void,
        signOut: @escaping () -> Void,
        openServiceSetup: (() -> Void)? = nil,
        openCatalog: (() -> Void)? = nil,
        openSimulation: (() -> Void)? = nil
    ) {
        self.session = session
        self.authEnvironment = authEnvironment
        self.store = store
        self.backToBoard = backToBoard
        self.signOut = signOut
        self.openServiceSetup = openServiceSetup
        self.openCatalog = openCatalog
        self.openSimulation = openSimulation
    }

    var body: some View {
        ZStack {
            PrepFlowColor.g5.ignoresSafeArea()

            ScrollView {
                VStack(spacing: PrepFlowSpacing.md) {
                    HStack(alignment: .top, spacing: PrepFlowSpacing.md) {
                        SettingsCard(title: "店舗", rows: [
                            SettingsRowModel(title: "店舗情報", value: "鮨 はやし ・ カウンター14席"),
                            SettingsRowModel(title: "営業帯（T=0）", value: "夜 第一部 18:00", isTime: true, action: .serviceSetup),
                            SettingsRowModel(title: "営業日カレンダー", value: "月曜定休"),
                        ], perform: perform)
                        SettingsCard(title: "チーム・認証", rows: [
                            SettingsRowModel(title: "オーナー", value: session.displayName),
                            SettingsRowModel(title: "tenant", value: session.tenantID),
                            SettingsRowModel(title: "認証方式", value: session.provider.label),
                        ], perform: perform)
                    }

                    HStack(alignment: .top, spacing: PrepFlowSpacing.md) {
                        SettingsCard(title: "表示", rows: [
                            SettingsRowModel(title: "デフォルトのテーマ", value: "ONE ACCENT"),
                            SettingsRowModel(title: "デフォルトのビュー", value: "今これ"),
                            SettingsRowModel(title: "夜厨房（ダーク）", value: "OFF"),
                        ], perform: perform)
                        SettingsCard(title: "仕込み・数量", rows: [
                            SettingsRowModel(title: "自己補正レシピ", value: "提案のみ"),
                            SettingsRowModel(title: "追い仕込み閾値", value: "残 25%", isTime: true),
                            SettingsRowModel(title: "繰越差引", value: "ON（期限内のみ）", action: .simulation),
                        ], perform: perform)
                    }

                    SettingsCard(title: "プラン・データ", rows: [
                        SettingsRowModel(title: "プラン", value: "P0 Pilot", action: .catalog),
                        SettingsRowModel(title: "データのエクスポート", value: store.latestExportSummary, action: .exportData),
                        SettingsRowModel(title: "ローカル縮退", value: authEnvironment.settingsReadinessLabel),
                    ], perform: perform)
                }
                .padding(.horizontal, PrepFlowSpacing.xxl)
                .padding(.top, PrepFlowMetric.topInset)
                .padding(.bottom, PrepFlowMetric.bottomInset)
            }

            VStack(spacing: PrepFlowSpacing.md) {
                SettingsTopBar(
                    lockLabel: store.settingsLocked ? "設定ロック ON ・ オーナー解除中" : "設定ロック OFF ・ オーナー解除中",
                    backToBoard: backToBoard,
                    toggleLock: {
                        store.toggleSettingsLock()
                        toastMessage = store.settingsLocked ? "保存しました（設定ロック ON）" : "保存しました（設定ロック OFF）"
                    },
                    signOut: signOut
                )
                Spacer()
                SettingsToast(message: toastMessage)
            }
            .padding(PrepFlowSpacing.md)
        }
        .foregroundStyle(PrepFlowColor.ink)
    }

    private func perform(_ action: SettingsAction?) {
        switch action {
        case .serviceSetup:
            openServiceSetup?()
        case .catalog:
            openCatalog?()
        case .simulation:
            openSimulation?()
        case .exportData:
            let export = store.exportSnapshotJSON(authReadinessLabel: authEnvironment.settingsReadinessLabel)
            toastMessage = "JSON出力済み（\(export.count) bytes）"
        case nil:
            break
        }
    }
}

private enum SettingsAction: Equatable {
    case serviceSetup
    case catalog
    case simulation
    case exportData
}

private struct SettingsRowModel: Equatable {
    let title: String
    let value: String
    var isTime = false
    var action: SettingsAction?
}

// 正本: design/p1-wireframe-settings-home-liquidglass.png
private struct SettingsTopBar: View {
    let lockLabel: String
    let backToBoard: () -> Void
    let toggleLock: () -> Void
    let signOut: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.md) {
                Button("← 今日へ", action: backToBoard)
                    .buttonStyle(SettingsGhostButtonStyle())

                Text("設定")
                    .font(PrepFlowFont.topTitle)

                Text("設定を検索（例：テーマ、定休日）")
                    .font(PrepFlowFont.small)
                    .foregroundStyle(PrepFlowColor.g3)
                    .padding(.horizontal, PrepFlowSpacing.md)
                    .frame(maxWidth: PrepFlowMetric.railWidth, minHeight: PrepFlowMetric.catalogFieldHeight, alignment: .leading)
                    .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
                    .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))

                Spacer()

                Button(lockLabel, action: toggleLock)
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.ok)
                    .padding(.horizontal, PrepFlowSpacing.sm)
                    .padding(.vertical, PrepFlowSpacing.xs)
                    .background(PrepFlowColor.ok.opacity(PrepFlowOpacity.selection))
                    .clipShape(Capsule(style: .continuous))
                    .buttonStyle(.plain)

                Button("サインアウト", action: signOut)
                    .buttonStyle(SettingsGhostButtonStyle())
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

// 正本: design/p1-wireframe-settings-home-liquidglass.png
private struct SettingsCard: View {
    let title: String
    let rows: [SettingsRowModel]
    let perform: (SettingsAction?) -> Void

    var body: some View {
        VStack(spacing: PrepFlowSpacing.none) {
            Text(title)
                .font(PrepFlowFont.sectionTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PrepFlowSpacing.md)
                .padding(.top, PrepFlowSpacing.md)
                .padding(.bottom, PrepFlowSpacing.sm)

            ForEach(rows, id: \.title) { row in
                SettingsRow(row: row) {
                    perform(row.action)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p1-wireframe-settings-home-liquidglass.png
private struct SettingsRow: View {
    let row: SettingsRowModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PrepFlowSpacing.md) {
                Text(row.title)
                    .font(PrepFlowFont.smallBold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(row.value)
                    .font(PrepFlowFont.small)
                    .foregroundStyle(row.isTime ? PrepFlowColor.time : PrepFlowColor.g2) // time-use: T0/deadline settings values
                    .lineLimit(1)
                    .minimumScaleFactor(PrepFlowMetric.textMinimumScale)
                Text("›")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.g3)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, PrepFlowSpacing.md)
        .padding(.vertical, PrepFlowSpacing.sm)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(height: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p1-wireframe-settings-home-liquidglass.png
private struct SettingsToast: View {
    let message: String

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.sm) {
                Text("✓")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.ink)
                Text(message)
                    .font(PrepFlowFont.smallBold)
                Text("元に戻す")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.ok)
            }
            .padding(.horizontal, PrepFlowSpacing.lg)
            .frame(height: PrepFlowMetric.catalogFieldHeight)
            .background(PrepFlowColor.ink.opacity(PrepFlowOpacity.darkGlass))
            .foregroundStyle(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.lg, style: .continuous))
            .glassEffect()
        }
    }
}

private struct SettingsGhostButtonStyle: ButtonStyle {
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
