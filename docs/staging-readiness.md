# PrepFlow Staging Readiness

Last local verification: 2026-06-21 06:12 JST

This note records the current evidence for `CODEX_HANDOFF.md` section 0. It is intended to be copied into the PR body and updated when a new archive or TestFlight upload is produced.

## DoD Evidence

| # | Requirement | Current evidence | Status |
|---|---|---|---|
| 1 | iPad / iOS 26 app builds, launches in simulator, Release archive succeeds | `xcodebuild test -project apps/ios/PrepFlow.xcodeproj -scheme PrepFlow -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5),OS=26.5' -only-testing:PrepFlowSnapshotTests` passed 75 tests. `xcodebuild archive -project apps/ios/PrepFlow.xcodeproj -scheme PrepFlow -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/prepflow-current.xcarchive CODE_SIGNING_ALLOWED=NO` succeeded. Archive: `/tmp/prepflow-current.xcarchive` (35M). | Green locally |
| 2 | Engine golden tests green | `swift test --package-path packages/Engine` passed 32 tests, including golden and thick-slice tests. | Green |
| 3 | WS2 sync spike GO gate | `docs/ws2-sync-spike.md` and `docs/architecture.md` D2 record GRDB + custom sync as the adopted P0 path. `swift test --package-path packages/SyncSpike` passed 4 tests for two-replica checkoff, 30-minute offline merge, idempotent checkoff, and local-first immediacy. | Green |
| 4 | P0 vertical slice B passes with offline restore | `PrepFlowSnapshotTests.testP0VerticalSliceBEndToEndMatchesHandoffGoldenAndOfflineRestore` passed. It covers local fallback, activation, service setup, board generation, checkoff rollup, simulation, settings export, event log, and restore. | Green |
| 5 | Auth, invite path, and RLS tenant separation | `PrepFlowSnapshotTests.testMagicLinkAuthResolvesTenantAndScopesRows`, `testAuthEnvironmentReportsLocalFallbackAndStagingReadiness`, and `PrepFlowDataTests.testSupabaseMigrationCreatesOnlyP0TablesAndTenantRLSPolicies` passed. Real Supabase/Apple credentials are still required for live staging. | Green locally / live credentials pending |
| 6 | CI quality gates | `.github/workflows/ci.yml` runs Engine/Data/Sync tests, SwiftFormat, SwiftLint strict, token guardrails, `PrepFlowColor.time` annotations, canonical wire references, no-secret guard, and app build/snapshot when Xcode 17 + iOS 26 SDK are available. Local runs passed. | Green locally |
| 7 | No committed secrets and env template current | Local no-secret guard passed. `.env.example` includes Supabase, magic link, Sign in with Apple, PowerSync placeholders, Stripe placeholders, and App Store Connect API placeholders. | Green |
| 8 | TestFlight internal distribution or Release archive | Release archive succeeded without signing at `/tmp/prepflow-current.xcarchive`. TestFlight upload still requires Apple Developer/App Store Connect credentials and signing assets. | Archive green / upload pending |
| 9 | UI source-of-truth fidelity | `docs/ui-fidelity-contract.md` is enforced by CI guards. Each SwiftUI View declaration is required to have a nearby `// 正本: design/...` reference to an existing wire. Snapshot tests passed, and comparison PNGs live in `docs/ui-comparisons/`. | Green locally |

## Local Verification Commands

```bash
swift test --package-path packages/Engine
swift test --package-path packages/SyncSpike
swift test --package-path packages/Data
cd apps/ios && xcodegen generate
swiftformat --lint .
swiftlint --strict
xcodebuild test -project apps/ios/PrepFlow.xcodeproj -scheme PrepFlow \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5),OS=26.5' \
  -only-testing:PrepFlowSnapshotTests
xcodebuild archive -project apps/ios/PrepFlow.xcodeproj -scheme PrepFlow \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /tmp/prepflow-current.xcarchive CODE_SIGNING_ALLOWED=NO
```

## TestFlight Blockers

The codebase is ready for unsigned Release archive validation. A real TestFlight upload still needs:

- Apple Developer team access for `com.prepflow.app`
- Signing certificate and provisioning profile
- Sign in with Apple app/service configuration
- App Store Connect API key (`APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_ID`, local `AuthKey_*.p8`)
- Supabase project URL and anon key for live auth/RLS staging
- Pilot invite tenant/user records

Until those are present, the app intentionally starts in local SQLite fallback mode and reports missing environment values in the auth surface.
