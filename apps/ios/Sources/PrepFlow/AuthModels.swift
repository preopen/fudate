import Foundation
import PrepFlowData

enum AuthProvider: String, CaseIterable {
    case apple
    case magicLink = "magiclink"

    var label: String {
        switch self {
        case .apple:
            "Sign in with Apple"
        case .magicLink:
            "マジックリンク"
        }
    }
}

struct AuthSession: Equatable {
    let ownerID: String
    let tenantID: String
    let email: String
    let provider: AuthProvider
    let displayName: String
    let role: String
}

struct LocalInvite: Equatable {
    let ownerID: String
    let tenantID: String
    let email: String
    let displayName: String
    let allowedProviders: Set<AuthProvider>
}

enum AuthError: Error, Equatable {
    case inviteRequired
    case providerNotAllowed
    case magicLinkNotRequested
}

struct AuthEnvironment: Equatable {
    let supabaseURL: String
    let supabaseAnonKey: String
    let appleServicesID: String
    let appleTeamID: String
    let magicLinkRedirectURL: String

    static let current = AuthEnvironment(
        supabaseURL: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "",
        supabaseAnonKey: ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "",
        appleServicesID: ProcessInfo.processInfo.environment["APPLE_SERVICES_ID"] ?? "",
        appleTeamID: ProcessInfo.processInfo.environment["APPLE_TEAM_ID"] ?? "",
        magicLinkRedirectURL: ProcessInfo.processInfo.environment["MAGICLINK_REDIRECT_URL"] ?? "prepflow://auth-callback"
    )

    var usesLocalSQLiteFallback: Bool {
        supabaseURL.isEmpty || supabaseAnonKey.isEmpty || supabaseURL.contains("YOUR-PROJECT")
    }

    var missingSecrets: [String] {
        var missing: [String] = []
        if supabaseURL.isEmpty || supabaseURL.contains("YOUR-PROJECT") {
            missing.append("SUPABASE_URL")
        }
        if supabaseAnonKey.isEmpty || supabaseAnonKey.contains("eyJ...") {
            missing.append("SUPABASE_ANON_KEY")
        }
        if appleServicesID.isEmpty {
            missing.append("APPLE_SERVICES_ID")
        }
        if appleTeamID.isEmpty {
            missing.append("APPLE_TEAM_ID")
        }
        return missing
    }
}

struct LocalInviteRegistry {
    private let invites: [String: LocalInvite]

    init(invites: [LocalInvite] = [.hayashiOwner]) {
        self.invites = Dictionary(uniqueKeysWithValues: invites.map { ($0.email.lowercased(), $0) })
    }

    func resolve(email: String, provider: AuthProvider) throws -> LocalInvite {
        guard let invite = invites[email.normalizedEmail] else {
            throw AuthError.inviteRequired
        }
        guard invite.allowedProviders.contains(provider) else {
            throw AuthError.providerNotAllowed
        }
        return invite
    }
}

extension LocalInvite {
    static let hayashiOwner = LocalInvite(
        ownerID: "owner-hayashi",
        tenantID: "tenant-local",
        email: "owner@prepflow.test",
        displayName: "林 直人",
        allowedProviders: Set(AuthProvider.allCases)
    )
}

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var session: AuthSession?
    @Published private(set) var magicLinkSentTo: String?
    @Published private(set) var errorMessage: String?
    @Published var email: String

    let database: PrepFlowDatabase?
    let environment: AuthEnvironment

    private let registry: LocalInviteRegistry

    init(
        database: PrepFlowDatabase? = AppDatabaseFactory.makeDatabase(),
        environment: AuthEnvironment = .current,
        registry: LocalInviteRegistry = LocalInviteRegistry(),
        initialEmail: String = LocalInvite.hayashiOwner.email
    ) {
        self.database = database
        self.environment = environment
        self.registry = registry
        email = initialEmail
    }

    var usesLocalSQLiteFallback: Bool {
        environment.usesLocalSQLiteFallback
    }

    var missingSecretsText: String {
        environment.missingSecrets.joined(separator: " / ")
    }

    func signInWithApple() {
        complete(provider: .apple, requireMagicLinkRequest: false)
    }

    func sendMagicLink() {
        do {
            _ = try registry.resolve(email: email, provider: .magicLink)
            magicLinkSentTo = email.normalizedEmail
            errorMessage = nil
        } catch {
            handle(error)
        }
    }

    func completeMagicLink() {
        complete(provider: .magicLink, requireMagicLinkRequest: true)
    }

    func signOut() {
        session = nil
        magicLinkSentTo = nil
    }

    private func complete(provider: AuthProvider, requireMagicLinkRequest: Bool) {
        do {
            if requireMagicLinkRequest, magicLinkSentTo != email.normalizedEmail {
                throw AuthError.magicLinkNotRequested
            }
            let invite = try registry.resolve(email: email, provider: provider)
            let resolvedSession = AuthSession(
                ownerID: invite.ownerID,
                tenantID: invite.tenantID,
                email: invite.email,
                provider: provider,
                displayName: invite.displayName,
                role: "owner"
            )
            persistOwnerAccount(resolvedSession)
            session = resolvedSession
            errorMessage = nil
        } catch {
            handle(error)
        }
    }

    private func persistOwnerAccount(_ session: AuthSession) {
        let values: [String: String?] = [
            "id": session.ownerID,
            "tenant_id": session.tenantID,
            "email": session.email,
            "auth_provider": session.provider.rawValue,
            "display_name": session.displayName,
            "role": session.role,
        ]

        let ownerExists = (try? database?.rows(.ownerAccount, tenantID: session.tenantID).contains { $0.id == session.ownerID }) == true
        if ownerExists {
            try? database?.update(.ownerAccount, id: session.ownerID, tenantID: session.tenantID, values: values)
        } else {
            try? database?.create(.ownerAccount, values: values)
        }
    }

    private func handle(_ error: Error) {
        switch error as? AuthError {
        case .inviteRequired:
            errorMessage = "招待済みのメールだけが利用できます。"
        case .providerNotAllowed:
            errorMessage = "この招待では選択した認証方式を使えません。"
        case .magicLinkNotRequested:
            errorMessage = "先にマジックリンクを送信してください。"
        case nil:
            errorMessage = "認証に失敗しました。"
        }
    }
}

private extension String {
    var normalizedEmail: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
