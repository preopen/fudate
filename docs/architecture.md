# PrepFlow 実装アーキテクチャ・実装前決定（ADR）

| 項目 | 内容 |
|---|---|
| 版 / 日付 | v1.2 / 2026-06-12 |
| 対応要件 | `requirements.md` v1.4（FR-01〜58） |
| 目的 | コーディング（Sonnetへの発注）開始前に、**モジュール分割と「決めるべきこと」を確定する単一ソース** |
| 読者 | 実装担当（Sonnet）への発注の元仕様。画面はワイヤー（`design/`）、要件は v1.4、実装単位は本書が正 |
| **D1 方針（v1.2）** | **iOS専用ネイティブアプリ＋Apple Liquid Glass デザインで確定**（まずはiPad＝高単価ターゲットに集中）。**Liquid Glass はApple HIG準拠で「機能レイヤー（chrome/操作/一時UI）のみ・コンテンツ層は不透明高コントラスト」**＝厨房のグランス可読性を死守（§A-12）。残る最終分岐は **D1a：実装方式（SwiftUIネイティブ ｜ React Native/Expo on iOS 26）の1点のみ**。**推奨＝RN/Expo on iOS 26**（expo-glass-effect/@expo/uiで本物のLiquid Glass・engine純TSをWeb共有・Sonnet生成精度最高・将来Android）。SwiftUI選択時はengineをSwift化しWeb共有を諦める |

---

## 0. 結論

1. **複雑性監査**：仕様は「広いが防御線が効いている」（§2.2のOut明文化・モード既定OFF・MoSCoW/フェーズ分割）。ただし**そのまま実装に持ち込むと、同型の機能が3〜4箇所で別実装になる**リスクがあった。→ 共有エンジンとして一本化（§1.1）し、要件側の整理4点を v1.4 に反映。
2. **コーディング開始判定：GO（条件付き）。**
   - 仕様側の前提は充足：S優先の画面穴ゼロ（coverage-matrix）・データモデル§6・イベント語彙§14・本書のモジュール分割。
   - **D1 は iOS専用＋Liquid Glass で確定（上表）。** 残る決定は **D1a（実装方式 SwiftUI vs RN/Expo）＝engineの言語を左右**する1点のみ。**`engine`の関数仕様（§3）・データモデル（§6）・モジュール責務（§2）は D1a に依存しない**ため、仕様確定作業は先行できる。
   - GOゲートは2つ：**D1a の確定** と **WS2 同期スパイクの合格**（R-1「オフライン縮退」＝No-Go級）。D1a確定後、WS0/WS1（骨格・engine）即着手、**全面GO（画面量産）は WS2 合格後**。
   - ※本書 §2.1/§3/§7/§A は**推奨のRN/Expo路線（engine純TS）**で記述。SwiftUI路線を採る場合、engineはSwift・Web共有なし・モーションはSwiftUI標準（A-11読替）に変わる。
3. **49画面 ≠ 49実装。** `design/` は探求・世代記録を含む。P0の実装画面は**6枚**（§6）。

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
- **FR-14 分割**：認証（マジックリンク・招待制）＝P0／Stripe課金＝P1。課金UIは Stripe Checkout + Customer Portal に委譲。

### 1.3 統合しなかった（無理にやらない判断）
| 対象 | 判断 | 理由 |
|---|---|---|
| モード制（ラベル/HACCP） | 維持 | 既定OFF＋疎結合は正しい設計。統合すると逆にコアが太る |
| 3テーマ × 3ビュー | 維持 | テーマ=CSSトークン差し替えのみ、3ビュー=1クエリ3レイアウト。コスト極小（A-6） |
| 価格4段＋アドオン | 維持 | 複雑性は entitlements 表（A-8）でデータ側に寄せ、コードから plan の if 分岐を排除 |
| §14 イベント駆動 | **縮小して維持** | ブローカー/キュー基盤は**入れない**。in-process 型付きイベント＋ event_log テーブルのみ（A-1）。P4でPOSを「発行者」として外付けする時に初めてトランスポートを足す |
| FR番号体系・要件書の構成 | 維持 | 履歴とトレーサビリティの価値。実装単位は本書が正 |

---

## 2. モジュール分割

### 2.1 コア（P0–P2）
| # | モジュール | 責務 | 対応FR | Phase |
|---|---|---|---|---|
| 1 | **`engine`**（純TS・最重要IP） | 数量計算・差分・自己補正・繰越・逆算スケジュール・ロールアップ | 03/37/38・19/34/55(差分)・09・42・06/40/41・05 | P0 |
| 2 | `data` + `sync` | スキーマ（§6）・local-first同期・オフライン | NFR-01/02/03/08 | P0（スパイク） |
| 3 | `catalog` | コーステンプレ・皿・構成要素・タスク定義・メディア・版 | 01・30・(18は文字列のみ) | P0基本／P1メディア |
| 4 | `serviceday` | 営業日・営業帯・営業日カレンダー・T0 | 02・41・カレンダー | P0 |
| 5 | `board` | 3ビュー・テーマ・チェックオフ・完了者・営業中表示・印刷 | 04/05/06/07・43・32・19(UI)・44 | P0 |
| 6 | `reservations` | 正規化Reservation・ソース合算・差分検知→engine | 34・(10保留)・13受け口・55 | P0は手入力のみ |
| 7 | `records` | WasteLog・締めフロー・申し送り・シミュレーション並走 | 08/23/33・39・42入力 | P0(39)〜P2 |
| 8 | `alerts` | タイマー・3段階通知 | 21/22・17の通知 | P1–P2 |
| 9 | `dashboard` | 達成率・履歴・(将来リプレイ) | 11・29 | P1 |
| 10 | `account` | 認証・entitlements・設定ホーム・端末・ロック・エクスポート | 14/15・52/53/54・12 | P0認証／P1 |

### 2.2 アドオン（コア非依存・後付け）
| モジュール | 対応FR | Phase | 接続方法 |
|---|---|---|---|
| `mode-label` | 20/45/46/47/48/50・49(在庫面) | P2.5 | `task.completed` 購読＋WasteLog書込 |
| `mode-haccp` | 16/51・49(温度面) | P2 | ChecklistRecord / TempLog |
| `connector-tablecheck` | 13/57/58 | P3（申請はP0） | `reservations` への供給者＋Messaging |
| `direct` | 35/36/56/35+ | P3.5 | `reservations` への供給者 |
| `service-sync` | 24/25/26/27/28 | P4 | イベント発行者として外付け（A-1） |

**原則：アドオンはコアのイベント/テーブルを購読・供給するだけ。コアはアドオンを知らない**（import方向の一方通行をlintで強制）。

### 2.3 依存方向
```
engine（純TS・依存ゼロ）
  ↑
data / sync ← catalog・serviceday・reservations・records
  ↑
board・alerts・dashboard・account
  ↑（購読・供給のみ）
mode-label・mode-haccp・connector-tablecheck・direct・service-sync
```

---

## 3. `engine` の関数仕様（発注の最小単位）
すべて**純関数・I/Oなし・golden test必須**。テスト期待値は確定ワイヤー上の数値（例：24名×煮切り→200ml/残65ml、卓3キャンセル→煮切り−84ml）をそのまま使う。

| 関数 | 入出力 | 対応FR |
|---|---|---|
| `calcQty(task, covers)` | scale_mode（per_cover/per_portion/fixed_batch）×人数×歩留り → 数量 | 03/37 |
| `aggregateSubrecipes(tasks)` | uses[] の重複 → 1タスク合算 | 38 |
| `diffPlan(plan, change)` | 予約増減・残数閾値 → タスク追加（追い仕込み）/減算/繰越・廃棄候補 | 19/34/55 |
| `selfCorrect(history, cfg)` | WasteLog（lookback N回・週次/月次）→ qty_coeff 提案 | 09 |
| `applyCarryover(plan, leftovers)` | 期限内繰越 → 翌日推奨から減算 | 42 |
| `schedule(tasks, calendar, period)` | T0−(リード＋所要)・定休日スキップ・prep_day 算出 | 06/40/41 |
| `rollup(tree, completion)` | 子全完了 → 親完了の伝播 | 05 |
| `generateInstances(sources, day)` | コース/定期/業務フロー → TaskInstance[] | 17/31/32/40 |

---

## 4. 決定済み（ADR）

| # | 決定 | 内容・理由 |
|---|---|---|
| A-1 | イベントは in-process | §14の語彙を**TypeScript型＋event_logテーブル**として実装。ブローカー/キューは入れない（YAGNI・solo運用）。P4で外部発行者を足す時にトランスポート追加 |
| A-2 | TaskInstance は実体化 | 日次オープン時に生成して保存（**オフライン端末がチェック対象の行を持つ必要**があるため）。予約変更は `diffPlan` の差分適用で更新 |
| A-3 | ID/テナント | ULID・全行 `tenant_id`・soft delete（復元・監査） |
| A-4 | 文字列の一元化 | 日本語文字列は1ファイルに集約。i18nフレームワークはP3まで導入しない（FR-18への保険のみ） |
| A-5 | 課金は委譲 | Stripe Checkout＋Customer Portal。自前課金UIは作らない |
| A-6 | テーマ/ビュー | **共有デザイントークン（TS定数：色/間隔/モーション）**を RN(StyleSheet) と Web(CSS) が参照。3ビュー=同一クエリの3レイアウト。テーマ差し替えはトークンのみ |
| A-7 | 印刷 | FR-44/16のPDF出力は **Web側(Next.js)の print CSS** で生成（RNから共有Web経由で呼ぶ）。PDF生成ライブラリ不採用 |
| A-8 | entitlements | プラン→機能フラグの**データ表**。コード内のプラン分岐は禁止 |
| A-9 | リポジトリ | 本リポジトリに monorepo：`packages/engine`（純TS・共有IP）・`packages/tokens`（デザイントークン）・`apps/mobile`（Expo/RN・厨房アプリ）・`apps/web`（Next.js・ゲスト/Direct/LP/課金）・`apps/server`（or Supabase） |
| A-10 | iOS専用ネイティブ＋薄いWeb | 厨房アプリは **iOSネイティブ（iPad中心）**。実装方式は D1a（SwiftUI ｜ RN/Expo on iOS 26）。ゲスト/課金/LP のみ Web（Next.js）。**まずはiOSに集中**（Androidは将来）。PWAは不採用（Safariストレージ退避リスク回避） |
| A-11 | モーション | FR-22（toast→banner→全画面反転＋音）・T−カウントダウン・NOW遷移・パー減少・ロールアップ完了をモーションで階層化。RN/Expo路線＝**react-native-reanimated**（UIスレッド・spring）／SwiftUI路線＝標準アニメーション＋`matchedGeometryEffect`等。Liquid Glassの`GlassEffectContainer`のmorphを遷移演出に活用可 |
| A-12 | **Liquid Glass 規律（最重要）** | Apple HIG準拠：**Liquid Glass は機能レイヤー（ツールバー/ビュー切替/シート/フローティング操作・カウントダウンchrome）のみ。タスクカード・数値・3段階アラート＝コンテンツ層は不透明・高コントラスト**に保つ（厨房はグランス可読性が安全要件）。グラスの tint は**朱＝時間だけ**（確定規律を継承）。**Reduce Transparency / Increase Contrast を尊重**（フロスト化・縁取りでフォールバック）。`design/` 49枚は**レイアウト/IA/導線の参照**として有効、視覚スキンのみ Liquid Glass 化 |

---

## 5. 決定と残る分岐

| # | 論点 | 状態（v1.2） |
|---|---|---|
| D1 | プラットフォーム/デザイン | ✅ **確定：iOS専用ネイティブ＋Apple Liquid Glass**（iPad中心・高単価ターゲット集中）。Liquid Glassは§A-12の規律（機能レイヤーのみ・コンテンツ不透明・朱tint=時間・Reduce Transparency尊重） |
| **D1a** | **実装方式（唯一の未決）** | **SwiftUIネイティブ ｜ React Native/Expo on iOS 26**。推奨＝**RN/Expo**（expo-glass-effect/@expo/uiで本物のLiquid Glass・`engine`純TSをWeb共有・Sonnet生成精度最高・将来Android）。SwiftUIは最高忠実度/性能だがengineがSwift・Web共有なし・新APIのAI生成は要レビュー |
| D2 | 同期エンジン（**GOゲート・WS2**） | ネイティブSQLite前提。RN路線：① **PowerSync(RN SDK)** → ② WatermelonDB → ③ op-sqlite＋最小自作。SwiftUI路線：① **GRDB＋自作同期** or ② PowerSync(Swift)。**合格基準**：2台のチェックオフ相互反映＜2秒／機内モード30分→復帰で無損失マージ／完了は冪等・数値はLWW＋履歴保持／2世代前のiPadで体感即時（NFR-03）。ネイティブSQLなのでブラウザ退避リスクは無し＝焦点は競合解決と性能 |

> 残る決定は **D1a（実装方式）1点**。確定すれば WS0/WS1 即着手、GOゲートは WS2（D2スパイク）。

---

## 6. P0スコープ凍結（ロードマップ§9準拠）

- **画面6枚**：①オンボーディング簡易 ②コーステンプレ編集（テキストのみ） ③本日のサービス設定（人数手入力） ④仕込みボード（今これ＋皿ごと・ONE ACCENTのみ） ⑤シミュレーション並走 ⑥設定（最小：店舗・営業帯1本・テーマ）
- **FR**：01(基本)/02/03/04/05/39 ＋ 14(認証のみ)。`engine` 自体は§3の全関数を先行実装（純関数は安いうちに揃え、UIは段階解放）
- **P0でやらない**：課金・メディア添付・担当ビュー・複数営業帯・定期タスク・予約ハブUI・モード類・テーマ3種（ONE ACCENTのみ）

---

## 7. 発注計画（Sonnet向けワークストリーム）

| WS | 内容 | 受入条件 | 依存 |
|---|---|---|---|
| WS0 | monorepo骨格（Expo＋Next＋packages）・CI・lint・型 | build/test green・Expo起動・Next起動 | — |
| WS1 | `engine` 全関数＋golden tests（純TS） | §3の全関数がワイヤー数値の期待値で green | WS0 |
| WS2 | **同期スパイク**（D2・PowerSync RN） | §5 D2の合格基準。**不合格なら次候補で再試行＝唯一のGOゲート** | WS0 |
| WS3 | スキーマ＋データ層（§6モデル・PowerSync/Supabase） | マイグレーション＋CRUD＋tenant分離テスト | WS2 |
| WS4 | boardシェル（RN・今これ/皿ごと・チェックオフ・ロールアップ・Reanimated） | ワイヤー再現・操作体感即時・オフライン動作・モーション | WS1/3 |
| WS5 | catalogエディタ（テキスト） | 階層CRUD・係数/歩留り入力 | WS3 |
| WS6 | serviceday設定＋人数入力 | T0設定→ボード数量反映 | WS3 |
| WS7 | シミュレーション並走＋WasteLog入力 | 実績vs推奨の差分表示 | WS4/6 |
| WS8 | 認証（マジックリンク・招待制） | 多テナント分離の経路テスト | WS3 |
| WS9 | P0統合・パイロットビルド | 10店を招待可能な状態 | 全部 |

**発注プロンプトの型（毎WS共通）**：対象モジュール／対応FR／参照ワイヤー（ファイル名）／受入条件／**変更禁止領域**（engineへのI/O持込禁止・イベント語彙の追加禁止・`--time` 色は時間系以外に使用禁止）を明記して渡す。

---

## 8. コーディング規約（Sonnetへの恒常指示・抜粋）

1. `packages/engine` は I/O・`Date.now()`・乱数の直接使用を禁止（すべて引数で受ける）
2. イベント名は §14 の語彙のみ。追加する場合は本書の改版を先に行う
3. 朱 `--time #c2410c` はカウントダウン/NOW/遅延/期限・緊急のみ（確定デザイン規律）
4. プラン分岐は entitlements 表の参照のみ（A-8）
5. アドオン→コアの一方向import（逆はlintエラー）
6. 1WS＝1PR、PRにFR番号を明記
