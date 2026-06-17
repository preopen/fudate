// 正本: design/p0-wireframe-onboarding-liquidglass.png
// 正本: design/p1-wireframe-settings-home-liquidglass.png
import DesignTokens
import SwiftUI

struct AuthenticatedRootView: View {
    @StateObject private var authStore: AuthStore
    @State private var screen: AuthenticatedScreen = .board

    init(authStore: AuthStore = AuthStore()) {
        _authStore = StateObject(wrappedValue: authStore)
    }

    var body: some View {
        if let session = authStore.session {
            switch screen {
            case .board:
                PrepFlowBoardView(
                    initialMode: .now,
                    store: BoardStore(database: authStore.database, tenantID: session.tenantID),
                    openSettings: {
                        screen = .settings
                    }
                )
            case .settings:
                SettingsHomeView(
                    session: session,
                    backToBoard: {
                        screen = .board
                    },
                    signOut: {
                        authStore.signOut()
                        screen = .board
                    }
                )
            }
        } else {
            AuthGateView(store: authStore)
        }
    }
}

private enum AuthenticatedScreen {
    case board
    case settings
}

// 正本: design/p0-wireframe-onboarding-liquidglass.png
struct AuthGateView: View {
    @ObservedObject var store: AuthStore

    var body: some View {
        ZStack {
            PrepFlowColor.g5.ignoresSafeArea()

            VStack(spacing: PrepFlowSpacing.md) {
                AuthHero(store: store)
                AuthInvitePanel(store: store)
            }
            .padding(.horizontal, PrepFlowSpacing.xxl)
            .padding(.top, PrepFlowMetric.topInset)
            .padding(.bottom, PrepFlowMetric.bottomInset)

            VStack(spacing: PrepFlowSpacing.md) {
                AuthTopBar(usesLocalFallback: store.usesLocalSQLiteFallback)
                Spacer()
                AuthBottomBar(store: store)
            }
            .padding(PrepFlowSpacing.md)
        }
        .foregroundStyle(PrepFlowColor.ink)
    }
}

// 正本: design/p0-wireframe-onboarding-liquidglass.png
private struct AuthTopBar: View {
    let usesLocalFallback: Bool

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: PrepFlowSpacing.lg) {
                Text("セットアップ")
                    .font(PrepFlowFont.topTitle)

                Spacer()

                HStack(spacing: PrepFlowSpacing.xs) {
                    AuthStep(index: "1", title: "招待確認", isActive: true)
                    AuthStepSeparator()
                    AuthStep(index: "2", title: "認証", isActive: false)
                    AuthStepSeparator()
                    AuthStep(index: "3", title: "初回ボード", isActive: false)
                }

                Text(usesLocalFallback ? "LOCAL SQLite" : "Supabase Auth")
                    .font(PrepFlowFont.countdownLabel)
                    .foregroundStyle(PrepFlowColor.ok)
                    .padding(.horizontal, PrepFlowSpacing.sm)
                    .padding(.vertical, PrepFlowSpacing.xs)
                    .background(PrepFlowColor.ok.opacity(PrepFlowOpacity.selection))
                    .clipShape(Capsule(style: .continuous))
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

private struct AuthStepSeparator: View {
    var body: some View {
        Rectangle()
            .fill(PrepFlowColor.ink.opacity(PrepFlowOpacity.selection))
            .frame(width: PrepFlowSpacing.lg, height: PrepFlowMetric.timelineRuleWidth)
    }
}

private struct AuthStep: View {
    let index: String
    let title: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: PrepFlowSpacing.xs) {
            Text(index)
                .font(PrepFlowFont.countdownLabel)
                .foregroundStyle(isActive ? PrepFlowColor.white : PrepFlowColor.g2)
                .frame(width: PrepFlowMetric.countdownRingInner, height: PrepFlowMetric.countdownRingInner)
                .background(isActive ? PrepFlowColor.ink : PrepFlowColor.ink.opacity(PrepFlowOpacity.selection))
                .clipShape(Circle())
            Text(title)
                .font(PrepFlowFont.smallBold)
                .foregroundStyle(isActive ? PrepFlowColor.ink : PrepFlowColor.g2)
        }
    }
}

// 正本: design/p0-wireframe-onboarding-liquidglass.png
private struct AuthHero: View {
    @ObservedObject var store: AuthStore

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.sm) {
            Text("招待済みアカウントで開始")
                .font(PrepFlowFont.focusTitle)
                .lineLimit(1)
                .minimumScaleFactor(PrepFlowMetric.textMinimumScale)
            Text("PrepFlow は店舗ごとの tenant で分離します。招待済みメールでサインインすると、この端末の SQLite と Supabase RLS が同じ tenant を参照します。")
                .font(PrepFlowFont.body)
                .foregroundStyle(PrepFlowColor.g2)
                .frame(maxWidth: PrepFlowMetric.railWidth + PrepFlowMetric.catalogTreeWidth, alignment: .leading)

            if store.usesLocalSQLiteFallback {
                Text("資格情報未設定のため、ローカル SQLite 縮退で起動します。")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.ok)
                    .padding(.horizontal, PrepFlowSpacing.md)
                    .padding(.vertical, PrepFlowSpacing.xs)
                    .background(PrepFlowColor.ok.opacity(PrepFlowOpacity.selection))
                    .clipShape(Capsule(style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 正本: design/p0-wireframe-onboarding-liquidglass.png
private struct AuthInvitePanel: View {
    @ObservedObject var store: AuthStore

    var body: some View {
        HStack(alignment: .top, spacing: PrepFlowSpacing.md) {
            VStack(alignment: .leading, spacing: PrepFlowSpacing.md) {
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xs) {
                    Text("招待メール")
                        .font(PrepFlowFont.sectionTitle)
                    TextField("owner@prepflow.test", text: $store.email)
                        .font(PrepFlowFont.bodyBold)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(PrepFlowSpacing.md)
                        .frame(height: PrepFlowMetric.actionButtonHeight)
                        .background(PrepFlowColor.g5)
                        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
                }

                HStack(spacing: PrepFlowSpacing.sm) {
                    Button("Appleで続ける") {
                        store.signInWithApple()
                    }
                    .buttonStyle(AuthPrimaryButtonStyle())

                    Button("リンクを送信") {
                        store.sendMagicLink()
                    }
                    .buttonStyle(AuthSecondaryButtonStyle())

                    Button("リンクで入る") {
                        store.completeMagicLink()
                    }
                    .buttonStyle(AuthSecondaryButtonStyle())
                }

                if let sentTo = store.magicLinkSentTo {
                    Text("\(sentTo) にマジックリンクを送信しました。")
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(PrepFlowColor.ok)
                }

                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(PrepFlowFont.smallBold)
                        .foregroundStyle(PrepFlowColor.time) // time-use: blocking auth alert requiring action now
                }
            }
            .padding(PrepFlowSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PrepFlowColor.white)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.xl, style: .continuous)
                    .stroke(PrepFlowColor.ink, lineWidth: PrepFlowMetric.heavyLineWidth)
            }

            AuthTenantPanel(store: store)
                .frame(width: PrepFlowMetric.railWidth)
        }
    }
}

// 正本: design/p1-wireframe-settings-home-liquidglass.png
private struct AuthTenantPanel: View {
    @ObservedObject var store: AuthStore

    var body: some View {
        VStack(alignment: .leading, spacing: PrepFlowSpacing.md) {
            Text("tenant / RLS")
                .font(PrepFlowFont.sectionTitle)
            AuthStatusRow(title: "招待", value: "owner@prepflow.test")
            AuthStatusRow(title: "tenant", value: "tenant-local")
            AuthStatusRow(title: "role", value: "owner")
            AuthStatusRow(title: "RLS", value: "tenant_id claim")

            if !store.missingSecretsText.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: PrepFlowSpacing.xxs) {
                    Text("不足")
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                    Text(store.missingSecretsText)
                        .font(PrepFlowFont.railMeta)
                        .foregroundStyle(PrepFlowColor.g2)
                        .lineLimit(2)
                        .minimumScaleFactor(PrepFlowMetric.textMinimumScale)
                }
            }
        }
        .padding(PrepFlowSpacing.lg)
        .background(PrepFlowColor.white)
        .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PrepFlowRadius.xl, style: .continuous)
                .stroke(PrepFlowColor.g4, lineWidth: PrepFlowMetric.lineWidth)
        }
    }
}

private struct AuthStatusRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(PrepFlowFont.railMeta)
                .foregroundStyle(PrepFlowColor.g2)
            Spacer()
            Text(value)
                .font(PrepFlowFont.smallBold)
                .lineLimit(1)
        }
        .padding(.vertical, PrepFlowSpacing.xs)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PrepFlowColor.g4)
                .frame(height: PrepFlowMetric.lineWidth)
        }
    }
}

// 正本: design/p0-wireframe-onboarding-liquidglass.png
private struct AuthBottomBar: View {
    @ObservedObject var store: AuthStore

    var body: some View {
        GlassEffectContainer {
            HStack {
                Text("招待制 ・ Sign in with Apple / マジックリンク ・ ステップ 1/3")
                    .font(PrepFlowFont.smallBold)
                    .foregroundStyle(PrepFlowColor.g2)
                Spacer()
                Button("サンプル招待で開始") {
                    store.signInWithApple()
                }
                .buttonStyle(AuthPrimaryButtonStyle())
            }
            .padding(.horizontal, PrepFlowSpacing.lg)
            .frame(height: PrepFlowMetric.bottomBarHeight)
            .background(PrepFlowColor.white.opacity(PrepFlowOpacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PrepFlowRadius.xxl, style: .continuous)
                    .stroke(PrepFlowColor.white.opacity(PrepFlowOpacity.glassStroke), lineWidth: PrepFlowMetric.lineWidth)
            }
            .shadow(color: PrepFlowColor.ink.opacity(PrepFlowOpacity.glassShadow), radius: PrepFlowSpacing.lg, y: -PrepFlowSpacing.xs)
            .glassEffect()
        }
    }
}

private struct AuthPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.action)
            .foregroundStyle(PrepFlowColor.white)
            .padding(.horizontal, PrepFlowSpacing.lg)
            .frame(height: PrepFlowMetric.actionButtonHeight)
            .background(configuration.isPressed ? PrepFlowColor.g2 : PrepFlowColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}

private struct AuthSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PrepFlowFont.smallBold)
            .foregroundStyle(PrepFlowColor.ink)
            .padding(.horizontal, PrepFlowSpacing.md)
            .frame(height: PrepFlowMetric.actionButtonHeight)
            .background(configuration.isPressed ? PrepFlowColor.g4 : PrepFlowColor.g5)
            .clipShape(RoundedRectangle(cornerRadius: PrepFlowRadius.md, style: .continuous))
    }
}
