# PrepFlow — Codex 実装ハンドオフ

> **目的**：このリポジトリの設計・仕様を、**ステージング可能な P0 ビルド**（iPad・iOS 26・TestFlight）まで実装する。
> **役割分担**：仕様・決定論的な正・足場の定義・ガードレールは整備済み（Claude）。**ここから先のコード実装は Codex** が担う。
> **読む順**：本書 → `docs/architecture.md`（決定/モジュール/WS） → `docs/engine-api.md`＋`golden/`（Engineの正） → `docs/data-schema.md` → `docs/requirements.md`（FR本文） → `design/`（ワイヤー・動線）。

---

## 0. 完成の定義（ステージングできる＝DoD）
すべて満たしたら「ステージング可能」とみなす：
1. **ビルド**：`xcodebuild`（iPad・iOS 26 シミュレータ）で app がビルド＆起動。アーカイブ（Release）成功。
2. **Engine**：`swift test`（`packages/Engine`）で **`golden/*.json` 全ケース green**。
3. **WS2 同期スパイク合格**（唯一のGOゲート・§下の D2 基準）。不合格なら採用候補を切替えて再試行。
4. **P0 縦ぎり（スライスB）が端末/シミュで通る**：オンボ→活性化(シミュ)→サービス設定(人数)→ボード(今これ/皿ごと)→チェックオフでロールアップ→シミュレーション→設定。**機内モードで継続**し復帰で同期。
5. **認証**：Sign in with Apple ＋ マジックリンク（招待制）。**マルチテナント分離（RLS）**の経路テスト green。
6. **CI green**（`swift test` ＋ xcodebuild ＋ SwiftLint/Format）。
7. **秘密情報を一切コミットしていない**（`.env`/署名鍵）。`.env.example` が最新。
8. （資格情報があれば）**TestFlight 内部配布アップロード**。無ければアーカイブ成功までで可。

---

## 1. 技術スタック（確定・`architecture.md` D1/D1a）
- iOS専用ネイティブ・**iPad中心・iOS 26+**／**SwiftUI ＋ Apple Liquid Glass**（`.glassEffect`/`GlassEffectContainer`）／Swift 6（strict concurrency）。
- `Engine`＝純Swiftパッケージ（I/Oなし・golden test）。`DesignTokens`＝色/間隔/モーションのSwift定数（`design/` の確定言語＝白基調＋黒＋朱(時間のみ)）。
- ローカル：SQLite（**GRDB**）。同期：**WS2で確定**（PowerSync Swift SDK → GRDB自作 → SwiftData の順で検証）。
- バックエンド：**Supabase**（Postgres/Auth/Storage・RLS）。認証：Sign in with Apple＋マジックリンク。
- 課金（P1）：**Webで完結（Stripe Checkout/Portal）＝App内IAP回避**（A-5）。アプリはサインインのみ。
- 配布：P0は **TestFlight 内部**。

## 2. リポジトリ目標構成
```
/ (このリポジトリ)
├─ CODEX_HANDOFF.md            ← 本書
├─ .env.example  .gitignore
├─ docs/   architecture.md / engine-api.md / data-schema.md / requirements.md / coverage-matrix.md / proposal-optimization.md
├─ design/ （確定ワイヤー＋Liquid Glass＋6縦ぎり＋全体マップ＝UIの正）
├─ golden/ （Engine決定論ベクタ＝数値の正）
├─ packages/
│   ├─ Engine/         （純Swift・SwiftPM。golden を resources で同梱）
│   └─ DesignTokens/   （Swift定数）
├─ apps/
│   └─ ios/            （SwiftUIアプリ。project.yml=xcodegen で生成）
└─ supabase/           （migrations/ ・ config.toml）
```

## 3. WS0 で作る足場（そのまま materialize 可・要ビルド確認）

### `packages/Engine/Package.swift`
```swift
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
  name: "Engine",
  platforms: [.iOS(.v26), .macOS(.v15)],
  products: [.library(name: "Engine", targets: ["Engine"])],
  targets: [
    .target(name: "Engine"),
    .testTarget(name: "EngineTests", dependencies: ["Engine"],
      resources: [.copy("golden")]) // golden/ をこの配下へコピー or シンボリックに配置
  ]
)
```
> goldenの配置：CIで `cp -R golden packages/Engine/Tests/EngineTests/golden` するか、テストリソースとして取り込む。`Bundle.module` で読む。

### `packages/DesignTokens/Package.swift`（雛形）
```swift
// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "DesignTokens", platforms: [.iOS(.v26)],
  products: [.library(name: "DesignTokens", targets: ["DesignTokens"])],
  targets: [.target(name: "DesignTokens")])
```
DesignTokens 中身（`design/` の規律をコード化）：`ink #15171a / g2 #70757b / g3 #c2c6ca / g4 #e9ebed / g5 #f6f7f8 / time(朱) #c2410c / ok #3a6a2a`、Satoshi、間隔・角丸・モーション(spring)。**朱は時間/NOW/遅延/緊急のみ（A-12）**。

### `apps/ios/project.yml`（xcodegen）
```yaml
name: PrepFlow
options: { bundleIdPrefix: com.prepflow, deploymentTarget: { iOS: "26.0" } }
packages:
  Engine: { path: ../../packages/Engine }
  DesignTokens: { path: ../../packages/DesignTokens }
  GRDB: { url: https://github.com/groue/GRDB.swift, from: "7.0.0" }
targets:
  PrepFlow:
    type: application
    platform: iOS
    sources: [Sources]
    dependencies: [ {package: Engine}, {package: DesignTokens}, {package: GRDB} ]
    settings:
      base: { TARGETED_DEVICE_FAMILY: 2, INFOPLIST_KEY_UISupportedInterfaceOrientations: "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight" }
```
> 生成：`cd apps/ios && xcodegen generate`。Supabase/PowerSync の SPM 依存は WS2/WS3 で追加。

### `.github/workflows/ci.yml`（雛形）
```yaml
name: ci
on: [push, pull_request]
jobs:
  engine:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - run: cp -R golden packages/Engine/Tests/EngineTests/golden
      - run: swift test --package-path packages/Engine
  app:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - run: brew install xcodegen swiftlint
      - run: cd apps/ios && xcodegen generate
      - run: swiftlint --strict
      - run: xcodebuild build -project apps/ios/PrepFlow.xcodeproj -scheme PrepFlow -destination 'platform=iOS Simulator,name=iPad Pro 11-inch,OS=26.0'
```

## 4. ワークストリーム（WS0→WS9）
各 WS：**1ブランチ＝1PR**、PRタイトルに WS番号＋FR を明記。受入を満たすまでマージしない。

| WS | ゴール | 受入（verify） | 依存 |
|---|---|---|---|
| **WS0** | 足場：上記スケルトンを生成 | `swift test`(Engine, 空でも) green・`xcodegen generate`成功・`xcodebuild build` 成功・CI green | — |
| **WS1** | `Engine` 全関数を実装 | **`golden/*.json` 全ケース green**（`docs/engine-api.md`準拠）。浮動小数1e-6 | WS0 |
| **WS2** | **同期スパイク（GOゲート）** | 下記 D2 基準を満たす実装を1つ確定。不合格なら次候補へ | WS0 |
| **WS3** | スキーマ＋データ層（GRDB＋Supabase migrations＋RLS） | `data-schema.md` の★テーブル作成・CRUD・**tenant分離(RLS)テスト** green | WS2 |
| **WS4** | Boardシェル（SwiftUI・今これ/皿ごと・チェックオフ・ロールアップ・Liquid Glass・Reanimated相当のSwiftUIモーション） | `design/p0-wireframe-board-liquidglass` 再現・操作体感即時・**オフライン動作**・A-12遵守（グラスは機能層のみ・コンテンツ不透明・朱=時間） | WS1/WS3 |
| **WS5** | Catalogエディタ（テキスト・FR-01/37） | 階層CRUD・係数/歩留り入力→ボード数量に反映 | WS3 |
| **WS6** | ServiceDay設定＋人数手入力（FR-02） | T0/人数確定→`calcQty`/`schedule`がボードに反映（`p0-wireframe-service-setup-liquidglass`） | WS3 |
| **WS7** | シミュレーション並走＋WasteLog入力（FR-39/08/63） | 実績vs推奨の差分表示・活性化サマリー（`p0-wireframe-simulation/activation-liquidglass`） | WS4/WS6 |
| **WS8** | 認証（Sign in with Apple＋マジックリンク・招待制） | サインイン→tenant解決→RLSで自店のみ見える経路テスト | WS3 |
| **WS9** | P0統合・TestFlight（または Release アーカイブ） | §0 DoD 全項目 | 全部 |

> 着地予測（FR-59）は WS4 のボードに内包して実装してよい（`etaProjection` は WS1 で済む）。締め(FR-33)・予約ハブUI・モード類・多店舗・信頼性運用網の残りは P1+（P0スコープ外＝`architecture.md §6`）。

## 5. WS2：同期スパイクの合格基準（GOゲート・D2）
- 候補順：① **PowerSync（Swift SDK）＋Supabase Postgres** → ② **GRDB＋自作同期** → ③ SwiftData。
- 合格：
  1. **2台のiPad**でチェックオフが相互反映 **< 2秒**（同一テナント）。
  2. **機内モード30分→復帰**で**無損失マージ**（チェックは冪等、数値はLWW＋履歴保持）。
  3. **2世代前のiPad/シミュ**で当日ボード操作が**体感即時**（NFR-03）。
  4. オフライン中も当日ボードが**完全動作**（ローカルSQLiteが正）。
- 不合格時：次候補へ切替えて再試行（このゲートを越えるまで WS4 以降の量産はしない）。

## 6. ガードレール（越えない線・PRレビュー観点）
- **やらない**：発注/仕入/在庫/原価/会計（連携含む・§2.2）／材料BOM／予約台帳・席割り・顧客DB／本部一斉配信／アレルゲンの“正”管理（参考のみ・**NFR-06**）／冷蔵庫QRの出し入れスキャン（読み取りレンズ）。
- **Engine**：I/O・`Date()`・乱数を関数内で使わない（引数注入）。イベント名は §14 語彙のみ。
- **色**：朱 `#c2410c` は**時間/NOW/遅延/期限・緊急のみ**。**Liquid Glass はコンテンツ層に使わない**（A-12：カード・数値・アラートは不透明・高コントラスト。Reduce Transparency/Increase Contrast 尊重）。
- **プラン分岐**：`entitlement.features`（データ表）参照のみ。コードに `if plan == ...` を書かない（A-8）。
- **依存方向**：アドオン→コアの一方向（SwiftPM境界で強制）。
- **課金**：アプリ内に IAP/購入導線を置かない（Web委譲・A-5。提出前に App Review 3.1.1/3.1.3 を確認）。

## 7. 秘密情報・環境
- 実値は `.env`（コミット禁止／`.gitignore`済）。`.env.example` 参照。`SUPABASE_SERVICE_ROLE_KEY` はアプリに入れない。
- 未設定でもビルドは通し、起動時に「未設定」を明示（パイロット前の動作確認用にローカルSQLiteのみで起動できる縮退を用意）。
- このリポジトリのリモート実行環境はネットワークポリシー下にある。外部依存取得が要る場合は許可状況を確認。

## 8. 規約
- 1 WS = 1 PR。コミット/PRに **FR番号** とWS番号。SwiftLint/SwiftFormat 適用。
- TDD：`golden/` を先に green に。UIは `design/` の対応ワイヤーを再現（ファイル名をPRに記載）。
- ドメインイベントは `docs/architecture.md §14` の語彙＋ `event_log` テーブル（A-1）。
- 破壊的変更（削除・モードOFF）のみ確認ダイアログ。設定は即時保存＋トースト取消（§13）。

## 9. 最初に走らせるコマンド（WS0）
```bash
# 1) 足場生成（上の雛形を materialize 後）
brew install xcodegen swiftlint swiftformat
cp -R golden packages/Engine/Tests/EngineTests/golden
swift test --package-path packages/Engine        # まだ空 → 後でWS1
cd apps/ios && xcodegen generate && cd -
xcodebuild build -project apps/ios/PrepFlow.xcodeproj -scheme PrepFlow \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch,OS=26.0'
```

## 10. 受入の最終確認（P0 縦ぎりB／`design/flow-vertical-slice.png`）
オンボ→活性化(自店の削減見込み)→サービス設定(14名/T0 18:00)→ボード今これ(煮切り200ml/着手15:00)→チェックオフでロールアップ→着地予測→シミュレーション→設定、が**1本通る**こと。`golden` の数値（煮切り200ml・着手15:00・卓3取消−84ml・着地18:12）がアプリ上でも一致すること。
