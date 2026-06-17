# PrepFlow 実装アーキテクチャ・実装前決定（ADR）

| 項目 | 内容 |
|---|---|
| 版 / 日付 | v1.3 / 2026-06-12 |
| 対応要件 | `requirements.md` v1.4（FR-01〜58） |
| 目的 | コーディング（Sonnetへの発注）開始前に、**モジュール分割と「決めるべきこと」を確定する単一ソース** |
| 読者 | 実装担当（Sonnet）への発注の元仕様。画面はワイヤー（`design/`）、要件は v1.4、実装単位は本書が正 |
| **技術スタック（確定）** | **iOS専用ネイティブ（iPad中心・iOS 26+）／SwiftUI ＋ Apple Liquid Glass ／ Swift 6（strict concurrency）。`Engine` は純Swiftパッケージ（golden test 検証）。ローカルSQLite＋オフライン同期、バックエンドは Supabase（Postgres/Auth）。ゲスト/課金/LP は別の薄いWeb（Next.js, P3.5〜）。** D1=iOS+Liquid Glass、D1a=SwiftUIネイティブ で確定（iPadのプラットフォーム機能と最高忠実度のLiquid Glassを設計の前提にするため） |

---

## 0. 結論

1. **複雑性監査**：仕様は「広いが防御線が効いている」（§2.2のOut明文化・モード既定OFF・MoSCoW/フェーズ分割）。ただし**そのまま実装に持ち込むと、同型の機能が3〜4箇所で別実装になる**リスクがあった。→ 共有エンジンとして一本化（§1.1）し、要件側の整理4点を v1.4 に反映。
2. **コーディング開始判定：GO。**
   - 仕様側の前提は充足：S優先の画面穴ゼロ（coverage-matrix）・データモデル§6・イベント語彙§14・本書のモジュール分割。
   - **技術スタックは確定（D1=iOS+Liquid Glass／D1a=SwiftUIネイティブ）。** 残る唯一のゲートは **WS2 同期スパイクの合格**（R-1「オフライン縮退」＝No-Go級）。
   - WS0/WS1（Xcode骨格・`Engine`）は即着手可。**全面GO（画面量産）は WS2 合格後**。
3. **49画面 ≠ 49実装。** `design/` は探求・世代記録を含む。P0の実装画面は**6枚**（§6）。`design/` の確定ワイヤーは**レイアウト/IA/導線の参照**として有効（視覚スキンは Liquid Glass 化＝§A-12）。

---

## 1. 複雑性監査の結果

### 1.1 一本化した（同型機能 → 共有エンジン）
仕様上は別FRだが、実装は**1つ**にする。Sonnetへの発注もこの単位で行う。

| 共有実装 | 含まれるFR | 一本化の内容 |
|---|---|---|
| **数量・差分エンジン** | FR-03/37/38 ＋ **19/34/55** ＋ 09 ＋ 42 | 「予約・残数の変化→タスクの増減」は**1つの diff 関数の3トリガ**（営業中の閾値割れ／予約増／予約減）。数量計算・自己補正・繰越も同じ純関数群 |
| **タスク生成器** | FR-01由来 ＋ **17/31/32/40/41** | コース由来・定期ルール・業務フロー（T−アンカー）の3源を**1つのジェネレータ**で TaskInstance 化（prep_day・営業帯対応） |
| **実績記録（WasteLog）** | FR-08 ＋ 46（→ 09/42 が消費） | **1テーブル・2入力経路**（手入力／ラベルQR）。読者は自己補正と繰越 |
| **締めフロー** | FR-33 ＋ 23 ＋ 08 | FR-23は独立機能にせず**FR-42繰越の構造化＋自由文メモ**として close-flow 内に実装（ワイヤー `p2-wireframe-close-flow` の通り） |

### 1.2 降格・分割（v1.4 反映済み）
- **FR-10 予約メール取込：S/P2 → C/保留**。TableCheck CRM（FR-13）主役化＋CSV/手入力で代替可能。各社メールテンプレへの追従（R-5）はsoloの保守タールピット。パイロットで需要が確認できた場合のみ実装。
- **FR-14 分割**：認証（Sign in with Apple／マジックリンク・招待制）＝P0／Stripe課金＝P1。課金UIは Stripe Checkout + Customer Portal に委譲。

### 1.3 統合しなかった（無理にやらない判断）
| 対象 | 判断 | 理由 |
|---|---|---|
| モード制（ラベル/HACCP） | 維持 | 既定OFF＋疎結合は正しい設計。統合すると逆にコアが太る |
| テーマ × 3ビュー | 維持 | テーマ=デザイントークン差し替えのみ、3ビュー=1クエリ3レイアウト。コスト極小（A-6） |
| 価格4段＋アドオン | 維持 | 複雑性は entitlements 表（A-8）でデータ側に寄せ、コードから plan の if 分岐を排除 |
| §14 イベント駆動 | **縮小して維持** | ブローカー/キュー基盤は**入れない**。in-process イベント（AsyncStream/Combine）＋ event_log テーブルのみ（A-1）。P4でPOSを「発行者」として外付けする時に初めてトランスポートを足す |
| FR番号体系・要件書の構成 | 維持 | 履歴とトレーサビリティの価値。実装単位は本書が正 |

---

## 2. モジュール分割

実装＝**SwiftPM ターゲット**で表現し、依存方向をターゲット境界で強制する。`apps/ios`（SwiftUIアプリ）＋ `packages/Engine`（純Swift）＋ `packages/DesignTokens`。

### 2.1 コア（P0–P2）
| # | モジュール（SwiftPM target） | 責務 | 対応FR | Phase |
|---|---|---|---|---|
| 1 | **`Engine`**（純Swift・最重要IP・I/Oなし） | 数量計算・差分・自己補正・繰越・逆算スケジュール・ロールアップ | 03/37/38・19/34/55(差分)・09・42・06/40/41・05 | P0 |
| 2 | `Data` + `Sync` | スキーマ（§6）・GRDB(SQLite)・local-first同期・オフライン | NFR-01/02/03/08 | P0（スパイク） |
| 3 | `Catalog` | コーステンプレ・皿・構成要素・タスク定義・メディア・版 | 01・30・(18は文字列のみ) | P0基本／P1メディア |
| 4 | `ServiceDay` | 営業日・営業帯・営業日カレンダー・T0 | 02・41・カレンダー | P0 |
| 5 | `Board`（SwiftUI） | 3ビュー・テーマ・チェックオフ・完了者・営業中表示・印刷 | 04/05/06/07・43・32・19(UI)・44 | P0 |
| 6 | `Reservations` | 正規化Reservation・ソース合算・差分検知→Engine | 34・(10保留)・13受け口・55 | P0は手入力のみ |
| 7 | `Records` | WasteLog・締めフロー・申し送り・シミュレーション並走 | 08/23/33・39・42入力 | P0(39)〜P2 |
| 8 | `Alerts` | タイマー・3段階通知（haptics/音） | 21/22・17の通知 | P1–P2 |
| 9 | `Dashboard` | 達成率・履歴・(将来リプレイ) | 11・29 | P1 |
| 10 | `Account` | 認証・entitlements・設定ホーム・端末・ロック・エクスポート | 14/15・52/53/54・12 | P0認証／P1 |

### 2.2 アドオン（コア非依存・後付け）
| モジュール | 対応FR | Phase | 接続方法 |
|---|---|---|---|
| `ModeLabel` | 20/45/46/47/48/50・49(在庫面) | P2.5 | `task.completed` 購読＋WasteLog書込 |
| `ModeHACCP` | 16/51・49(温度面) | P2 | ChecklistRecord / TempLog |
| `ConnectorTableCheck` | 13/57/58 | P3（申請はP0） | `Reservations` への供給者＋Messaging |
| `Direct`（Web中心） | 35/36/56/35+ | P3.5 | `Reservations` への供給者（Next.js + Stripe） |
| `ServiceSync` | 24/25/26/27/28 | P4 | イベント発行者として外付け（A-1） |

**原則：アドオンはコアのイベント/テーブルを購読・供給するだけ。コアはアドオンを知らない**（SwiftPM の依存グラフで一方向を強制）。

### 2.3 依存方向
```
Engine（純Swift・依存ゼロ・golden test）
  ↑
Data / Sync ← Catalog・ServiceDay・Reservations・Records
  ↑
Board・Alerts・Dashboard・Account（SwiftUI）
  ↑（購読・供給のみ）
ModeLabel・ModeHACCP・ConnectorTableCheck・Direct・ServiceSync
```

---

## 3. `Engine` の関数仕様（発注の最小単位）
すべて**純関数・I/Oなし・値型・golden test必須**（`Date` や乱数は引数注入）。テスト期待値は確定ワイヤー上の数値（例：24名×煮切り→200ml/残65ml、卓3キャンセル→煮切り−84ml）を **`golden/*.json` の共有ベクタ**にして XCTest で検証（将来 Web/Android も同じベクタを使う）。

| 関数（Swift signature 目安） | 入出力 | 対応FR |
|---|---|---|
| `calcQty(_ task: PrepTask, covers: Int) -> Quantity` | scale_mode（per_cover/per_portion/fixed_batch）×人数×歩留り → 数量 | 03/37 |
| `aggregateSubrecipes(_ tasks: [PrepTask]) -> [PrepTask]` | uses[] の重複 → 1タスク合算 | 38 |
| `diffPlan(_ plan: Plan, _ change: Change) -> PlanDiff` | 予約増減・残数閾値 → タスク追加（追い仕込み）/減算/繰越・廃棄候補 | 19/34/55 |
| `selfCorrect(_ history: [WasteLog], _ cfg: CorrectionConfig) -> [CoeffSuggestion]` | lookback N回・週次/月次 → qty_coeff 提案 | 09 |
| `applyCarryover(_ plan: Plan, _ leftovers: [Leftover]) -> Plan` | 期限内繰越 → 翌日推奨から減算 | 42 |
| `schedule(_ tasks: [Task], _ calendar: Calendar, _ period: ServicePeriod) -> [ScheduledTask]` | T0−(リード＋所要)・定休日スキップ・prep_day 算出 | 06/40/41 |
| `rollup(_ tree: TaskTree, _ completion: Completion) -> TaskTree` | 子全完了 → 親完了の伝播 | 05 |
| `generateInstances(_ sources: Sources, _ day: ServiceDay) -> [TaskInstance]` | コース/定期/業務フロー → TaskInstance | 17/31/32/40 |

---

## 4. 決定済み（ADR）

| # | 決定 | 内容・理由 |
|---|---|---|
| A-1 | イベントは in-process | §14の語彙を **Swift の型＋AsyncStream/Combine＋event_logテーブル**で実装。ブローカー/キューは入れない（YAGNI・solo運用）。P4で外部発行者を足す時にトランスポート追加 |
| A-2 | TaskInstance は実体化 | 日次オープン時に生成して保存（**オフライン端末がチェック対象の行を持つ必要**があるため）。予約変更は `diffPlan` の差分適用で更新 |
| A-3 | ID/テナント | ULID・全行 `tenant_id`・soft delete（復元・監査） |
| A-4 | 文字列の一元化 | 日本語文字列は String Catalog（`.xcstrings`）に集約。i18nの本格対応はP3まで保留（FR-18への保険のみ） |
| A-5 | 課金は委譲＋IAP回避 | **アカウント作成・課金は Web（Stripe Checkout＋Customer Portal）。iOSアプリはサインインのみ＝サーバ側 entitlements で機能解放**。B2B SaaS の標準形で App Store IAP（15–30%）を回避。※提出前に最新の App Review ガイドライン（3.1.1/3.1.3）と anti-steering 規定を確認 |
| A-6 | テーマ/トークン | **DesignTokens（Swift：色/間隔/タイポ/モーション）**を単一ソースに。テーマ差し替えはトークンのみ。3ビュー=同一クエリの3レイアウト。将来Webは同トークンをJSON経由で共有 |
| A-7 | 印刷 | FR-44（PASS SHEET A4）・FR-16（HACCP PDF）は **PDFKit / `ImageRenderer`** でネイティブ生成・AirPrint。外部PDFライブラリ不採用 |
| A-8 | entitlements | プラン→機能フラグの**データ表**。コード内のプラン分岐は禁止 |
| A-9 | リポジトリ | 単一リポジトリ：`apps/ios`（Xcode・SwiftUI）・`packages/Engine`（純Swift）・`packages/DesignTokens`・`golden/`（共有テストベクタ）・`supabase/`（マイグレーション/設定）・`web/`（Next.js＝ゲスト/Direct/LP/課金, P3.5〜）。CI＝xcodebuild test ＋ SwiftLint/SwiftFormat |
| A-10 | iOS専用ネイティブ | 厨房アプリは **iPad中心の iOSネイティブ（SwiftUI, iOS 26+）**。Androidは将来（アプリ層は作り直し・`Engine`仕様とgoldenベクタはKotlinへ移植可）。PWAは不採用（Safariストレージ退避リスク回避） |
| A-11 | モーション | FR-22（トースト→バナー→全画面反転）・T−カウントダウン・NOW遷移・パー減少・ロールアップ完了を SwiftUI の `withAnimation`(spring)・`matchedGeometryEffect`・`phaseAnimator`・`symbolEffect`・`GlassEffectContainer` の morph で階層化。全画面反転は `fullScreenCover`＋**CoreHaptics＋AVFoundation の音**。確定デザイン（朱=時間）の上に構築 |
| A-12 | **Liquid Glass 規律（最重要）** | Apple HIG準拠：**Liquid Glass は機能レイヤー（ツールバー/ビュー切替/シート/フローティング操作・カウントダウンchrome）のみ。タスクカード・数値・3段階アラート＝コンテンツ層は不透明・高コントラスト**に保つ（厨房はグランス可読性が安全要件）。`.glassEffect(_:in:)`＋`GlassEffectContainer`を使用。グラスの tint は**朱＝時間だけ**。**Reduce Transparency / Increase Contrast を尊重**（フロスト化・縁取りでフォールバック） |
| A-13 | バックエンド | **Supabase（Postgres/Auth/Storage）＝マネージドで solo運用（NFR-04）**。CloudKitは検討したが**マルチテナントB2B（店舗内で複数スタッフが共有・サーバ側の課金/横断クエリ）に不向き**のため不採用。オンデバイスは SQLite（GRDB）。同期は §D2 スパイクで確定 |
| A-14 | 認証 | **Sign in with Apple（iPadで摩擦最小）＋ マジックリンク**。P0は招待制（パイロット10店）。マルチテナントは Supabase Auth＋RLS |

---

## 5. 決定と残る分岐

| # | 論点 | 状態（v1.3） |
|---|---|---|
| D1 | プラットフォーム/デザイン | ✅ **確定：iOS専用ネイティブ＋Apple Liquid Glass**（iPad中心）。規律は§A-12 |
| D1a | 実装方式 | ✅ **確定：SwiftUIネイティブ**（iPadのプラットフォーム機能＝Pencil/Stage Manager/トラックパッドhover/⌘/D&D と最高忠実度のLiquid Glassを設計の前提にするため）。`Engine`はSwift、Web版ロジックは別（goldenベクタで整合検証） |
| D2 | 同期エンジン（**唯一のGOゲート・WS2**） | スパイク順：① **PowerSync（Swift SDK）＋Supabase Postgres** → ② **GRDB＋自作同期** → ③ SwiftData実験。**合格基準**：2台のチェックオフ相互反映＜2秒／機内モード30分→復帰で無損失マージ／完了は冪等・数値はLWW＋履歴保持／2世代前のiPadで体感即時（NFR-03）。ネイティブSQLiteなのでブラウザ退避リスクは無し＝焦点は競合解決と性能 |

> 残る決定はゼロ。**WS0/WS1 即着手可。GOゲートは WS2（D2スパイク）のみ。**

---

## 6. P0スコープ凍結（ロードマップ§9準拠）

- **画面6枚**：①オンボーディング簡易 ②コーステンプレ編集（テキストのみ） ③本日のサービス設定（人数手入力） ④仕込みボード（今これ＋皿ごと・Liquid Glass chrome） ⑤シミュレーション並走 ⑥設定（最小：店舗・営業帯1本・テーマ）
- **FR**：01(基本)/02/03/04/05/39 ＋ 14(認証のみ＝Sign in with Apple/招待制)。`Engine` 自体は§3の全関数を先行実装（純関数は安いうちに揃え、UIは段階解放）
- **配布**：**TestFlight**（App Store審査前・パイロット10店招待）
- **P0でやらない**：課金・メディア添付・担当ビュー・複数営業帯・定期タスク・予約ハブUI・モード類・iPhoneレイアウト最適化

---

## 7. 発注計画（Sonnet向けワークストリーム）

| WS | 内容 | 受入条件 | 依存 |
|---|---|---|---|
| WS0 | Xcode骨格（SwiftUIアプリ＋SwiftPM: Engine/DesignTokens）・Supabaseプロジェクト・CI（xcodebuild test＋SwiftLint） | build/test green・iPad(iOS 26)シミュレータで起動 | — |
| WS1 | `Engine` 全関数＋golden tests（XCTest＋`golden/*.json`） | §3の全関数がワイヤー数値の期待値で green | WS0 |
| WS2 | **同期スパイク**（D2・PowerSync Swift / GRDB） | §5 D2の合格基準。**不合格なら次候補で再試行＝唯一のGOゲート** | WS0 |
| WS3 | スキーマ＋データ層（§6モデル・GRDB＋Supabaseマイグレーション） | CRUD＋tenant分離（RLS）テスト | WS2 |
| WS4 | Boardシェル（SwiftUI・今これ/皿ごと・チェックオフ・ロールアップ・Liquid Glass chrome・モーション） | ワイヤー再現・操作体感即時・オフライン動作・A-12規律遵守 | WS1/3 |
| WS5 | Catalogエディタ（テキスト） | 階層CRUD・係数/歩留り入力 | WS3 |
| WS6 | ServiceDay設定＋人数入力 | T0設定→ボード数量反映 | WS3 |
| WS7 | シミュレーション並走＋WasteLog入力 | 実績vs推奨の差分表示 | WS4/6 |
| WS8 | 認証（Sign in with Apple＋マジックリンク・招待制） | 多テナント分離の経路テスト | WS3 |
| WS9 | P0統合・TestFlightビルド | 10店を招待可能な状態 | 全部 |

**発注プロンプトの型（毎WS共通）**：対象モジュール／対応FR／参照ワイヤー（ファイル名）／受入条件／**変更禁止領域**（`Engine`へのI/O持込禁止・イベント語彙の追加禁止・**Liquid Glassをコンテンツ層に使わない(A-12)**・朱は時間系以外に使用禁止）を明記して渡す。

---

## 8. コーディング規約（Sonnetへの恒常指示・抜粋）

1. `Engine` は I/O・`Date()`／`Date.now`・乱数の直接使用を禁止（すべて引数で受ける）。Swift 6 strict concurrency・値型中心。
2. イベント名は §14 の語彙のみ。追加する場合は本書の改版を先に行う。
3. **朱（time）はカウントダウン/NOW/遅延/期限・緊急のみ**（Liquid Glass の tint も含め確定デザイン規律）。
4. **Liquid Glass はコンテンツ層に使わない（A-12）**。タスクカード・数値・アラートは不透明・高コントラスト。
5. プラン分岐は entitlements 表の参照のみ（A-8）。
6. アドオン→コアの一方向依存（SwiftPM ターゲット境界で強制・逆は不可）。
7. `golden/*.json` のテストベクタは Swift／将来 Web・Android で共有（数値仕様の単一ソース）。
8. 1WS＝1PR、PRにFR番号を明記。
