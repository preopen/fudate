# PrepFlow ASCII ワイヤーフレーム実装修正マップ

目的: 現在の SwiftUI 実装を、修正時に追いやすい ASCII ワイヤーフレームとして整理する。

このファイルは UI の正本ではない。正本は常に次のファイル群とする。

- `docs/ui-fidelity-contract.md`
- `design/*.png`
- `design/*.html`
- snapshot test（スナップショットテスト）
- `docs/ui-comparisons/*.comparison.png`

このファイルはコードを読むための補助地図である。レイアウトを変更したい場合は、先に対応する `design/` の正本ワイヤーを更新し、その後に SwiftUI 実装を追従させる。

## 凡例

```text
+-----+     不透明なコンテンツ層
|     |
+-----+

[glass]     Liquid Glass を使う機能層
(time)      時間 / NOW / 遅延 / 期限。PrepFlowColor.time 使用可
[ink]       選択 / 進捗 / 通常強調。朱を使わない
<sheet>     モーダルシート
{store}     BoardStore または AuthStore の状態/操作
```

## 画面遷移マップ

```text
PrepFlowApp
  |
  v
ContentView
  |
  v
AuthenticatedRootView
  |
  +-- セッションなし ----------------------------------------+
  |                                                        |
  |  AuthGateView                                          |
  |   -> 招待 / Apple / マジックリンク / SQLite 縮退         |
  |                                                        |
  +-- セッションあり ----------------------------------------+
                                                           |
     AuthenticatedSessionView                              |
       |                                                   |
       +-- 活性化     -> ActivationSummaryView             |
       +-- 試算       -> SimulationView                    |
       +-- 営業設定   -> ServiceSetupView                  |
       +-- ボード     -> PrepFlowBoardView                 |
       +-- カタログ   -> CatalogEditorView                 |
       +-- 設定       -> SettingsHomeView                  |
```

## オンボーディング / 認証

実装ファイル: `apps/ios/Sources/PrepFlow/AuthGateView.swift`
正本ワイヤー: `design/p0-wireframe-onboarding-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] AuthTopBar                                                              |
|         手順 1 -- 手順 2 -- 手順 3                                               |
+--------------------------------------------------------------------------------+
|                                                                                |
| +--------------------------------+  +-----------------------------------------+ |
| | AuthHero                       |  | AuthInvitePanel                         | |
| | - プロダクト信号               |  | - email 入力                            | |
| | - 初期導入メッセージ           |  | - マジックリンク操作                    | |
| | - 準備状態 / SQLite 縮退       |  | - Apple サインイン操作                  | |
| +--------------------------------+  +-----------------------------------------+ |
|                                                                                |
| +--------------------------------+  +-----------------------------------------+ |
| | AuthTenantPanel                |  | AuthStatusRows                         | |
| | - tenant / role                |  | - Supabase 準備状態                     | |
| | - ローカル招待                 |  | - Apple 準備状態                        | |
| +--------------------------------+  +-----------------------------------------+ |
|                                                                                |
+--------------------------------------------------------------------------------+
| [glass] AuthBottomBar                                                           |
|         主操作 / 縮退状態                                                       |
+--------------------------------------------------------------------------------+
```

修正アンカー:

```text
AuthGateView          -> 画面全体
AuthTopBar            -> 上部 glass 機能層
AuthHero              -> 左側の導入ブロック
AuthInvitePanel       -> 認証入力と操作
AuthTenantPanel       -> tenant 状態
AuthStatusRow         -> 準備状態の行
AuthStore/AuthModels  -> session / invite / env 縮退
```

## 活性化サマリー

実装ファイル: `apps/ios/Sources/PrepFlow/SimulationViews.swift`
正本ワイヤー: `design/p0-wireframe-activation-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] ActivationTopBar                                                        |
|         業態 完了 -> 削減 現在 -> 初回ボード 待機                              |
+--------------------------------------------------------------------------------+
|                                                                                |
| +------------------------------------------------------------------------------+|
| | ActivationNumbers                                                            ||
| | +--------------------+  +--------------------+  +--------------------+       ||
| | | 削減の主指標       |  | ロス削減           |  | 的中率             |       ||
| | +--------------------+  +--------------------+  +--------------------+       ||
| +------------------------------------------------------------------------------+|
|                                                                                |
| +------------------------------------------------------------------------------+|
| | ActivationBars                                                               ||
| | - 推奨前                                                                        ||
| | - 推奨後                                                                        ||
| | - 削減見込み                                                                    ||
| +------------------------------------------------------------------------------+|
|                                                                                |
+--------------------------------------------------------------------------------+
| [glass] ActivationBottomBar -> シミュレーション / ボードへ進む                  |
+--------------------------------------------------------------------------------+
```

修正アンカー:

```text
ActivationSummaryView -> 画面全体
ActivationTopBar      -> glass の進行ヘッダー
ActivationNumbers     -> KPI カード
ActivationBars        -> 比較バー
ActivationBottomBar   -> 遷移アクション
BoardStore            -> シミュレーション概要と遷移進捗
```

## シミュレーション

実装ファイル: `apps/ios/Sources/PrepFlow/SimulationViews.swift`
正本ワイヤー: `design/p0-wireframe-simulation-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] SimulationTopBar                                                        |
|         期間 / 動線操作 / 予約ハブ / 締めループ                                 |
+--------------------------------------------------------------------------------+
|                                                                                |
| +--------------------------------+  +-----------------------------------------+ |
| | SimulationKPIGrid              |  | SimulationResultPanel                   | |
| | + KPIBox + KPIBox + KPIBox     |  | - 廃棄ログ / 補正結果                  | |
| | - 推奨 vs 実績                 |  | - ボード影響の概要                     | |
| +--------------------------------+  +-----------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | SimulationItemList                                                           ||
| | - SimulationItemRow                                                          ||
| | - SimulationBar: 推奨 / 実績 / 差分                                          ||
| +------------------------------------------------------------------------------+|
|                                                                                |
| +------------------------------------------------------------------------------+|
| | SimulationStatusBox                                                          ||
| | - ローカル保存状態                                                         ||
| | - 係数適用状態                                                               ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

修正アンカー:

```text
SimulationView        -> 画面全体と sheet 起動
SimulationTopBar      -> glass 機能層
SimulationKPIGrid     -> KPI 概要
SimulationItemList    -> 行リスト
SimulationResultPanel -> 適用/調整の概要
CloseLoopSheet        -> 締めフロー sheet
ReservationHubSheet   -> 予約差分 sheet
```

## 本日のサービス設定

実装ファイル: `apps/ios/Sources/PrepFlow/ServiceSetupView.swift`
正本ワイヤー: `design/p0-wireframe-service-setup-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] ServiceTopBar                                                           |
|         日付 / 営業帯 / 開店時刻                                                |
+--------------------------------------------------------------------------------+
|                                                                                |
| +------------------------------------------+ +-------------------------------+ |
| | ReservationList                          | | ServiceCoversPanel            | |
| | + ServiceControlStrip                    | | - メイン人数 stepper          | |
| | | - 営業帯切替                           | | - その他人数 stepper          | |
| | | - 開店時刻入力 (time)                  | | - ボード生成済み状態          | |
| | +--------------------------------------+ | | - ボード生成操作             | |
| | | ReservationRow                         | +-------------------------------+ |
| | | ReservationRow                         |                                   |
| | | 手入力予約を追加                       |                                   |
| | +--------------------------------------+ |                                   |
| +------------------------------------------+                                   |
|                                                                                |
| <sheet> ReservationEditSheet                                                    |
|         人数 stepper / メモ入力 / 削除操作                                      |
+--------------------------------------------------------------------------------+
```

修正アンカー:

```text
ServiceSetupView        -> 画面全体
ServiceTopBar           -> 上部 glass 層
ServiceControlStrip     -> 営業帯 / 開店時刻の操作
ReservationList         -> 手入力予約リスト
ReservationRow          -> 編集 sheet 起動行
ServiceCoversPanel      -> 人数合計と board 生成
ReservationEditSheet    -> 編集 / 削除 sheet
BoardStore              -> service / reservations / board preview
```

## 仕込みボード: 共通シェル

実装ファイル:

- `apps/ios/Sources/PrepFlow/ContentView.swift`
- `apps/ios/Sources/PrepFlow/BoardChrome.swift`

正本ワイヤー:

- `design/p0-wireframe-board-liquidglass.png`
- `design/p1-wireframe-board-eta-liquidglass.png`
- `design/p1-wireframe-view-dishes-liquidglass.png`
- `design/p1-wireframe-view-staff-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] BoardTopBar                                                             |
|  タイトル + 日付/人数        [ 今これ | 皿ごと | 担当 ]     (T-minus 島)          |
|  影響バッジ / 設定                                                            |
+--------------------------------------------------------------------------------+
|                                                                                |
|                         選択中の BoardMode                                      |
|                                                                                |
|      今これ view              皿ごと view                 担当 view             |
|         |                         |                          |                  |
|         v                         v                          v                  |
|   NowBoardContent          DishBoardContent            StaffBoardContent         |
|                                                                                |
+--------------------------------------------------------------------------------+
| [glass] BoardBottomBar または LineGateBar                                      |
|  - ライン開始ゲート状態                                                        |
|  - 手順ガイド操作                                                              |
|  - ラベル進捗 / 未解決チェック                                                |
+--------------------------------------------------------------------------------+
| <sheet> NowGuidanceSheet                                                        |
| <sheet> LabelOpsSheet                                                           |
+--------------------------------------------------------------------------------+
```

維持する規則:

```text
1. ボードナビは上部バー + segmented control。
2. now/dishes/staff を sidebar に置き換えない。
3. progress bar は ink。time red を使わない。
4. time red は T-minus / NOW / 遅延 / 期限 / 緊急のみ。
5. glass は top bar / segment / countdown island / bottom bar / sheet のみ。
```

## 仕込みボード: 今これ

実装ファイル: `apps/ios/Sources/PrepFlow/ContentView.swift`
主 View: `NowBoardContent`

```text
+--------------------------------------------------------------------------------+
| +--------------------------------------+ +------------------------------------+ |
| | フォーカス領域                      | | TimelineRail                       | |
| | - 現在タスク名                      | | - T-minus 順序                    | |
| | - 数量 / 担当                       | | - RailItem 行                      | |
| | - FocusTaskRow リスト               | | - 手順ごとの状態                  | |
| | - CheckCircle 状態                  | |                                    | |
| +--------------------------------------+ +------------------------------------+ |
|                                                                                |
| +--------------------------------------+ +------------------------------------+ |
| | BoardWorkStatePanel                  | | BoardLandingForecastCard           | |
| | - 開始/保留/準備状態                | | - ETACompact                       | |
| | - 開始/一時停止/再開/確認/完了      | | - 遅延/不足状態 (time)            | |
| | - 応援提案操作                      | | - 応援適用                        | |
| +--------------------------------------+ +------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | BoardImpactRailCard                                                          ||
| | - 待機中の予約/営業/ゲスト/残数影響                                      ||
| | - 影響の適用または却下                                                    ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## 仕込みボード: 皿ごと

実装ファイル: `apps/ios/Sources/PrepFlow/ContentView.swift`
主 View: `DishBoardContent`

```text
+--------------------------------------------------------------------------------+
| DishBoardContent                                                                |
|                                                                                |
| +----------------------+ +----------------------+ +----------------------+     |
| | DishCard             | | DishCard             | | DishCard             |     |
| | - 料理名            | | - 料理名            | | - 料理名            |     |
| | - [ink] ProgressBar  | | - [ink] ProgressBar  | | - [ink] ProgressBar  |     |
| | - DishTaskRow        | | - DishTaskRow        | | - DishTaskRow        |     |
| | - DishImpactRow      | | - DishImpactRow      | | - DishImpactRow      |     |
| +----------------------+ +----------------------+ +----------------------+     |
+--------------------------------------------------------------------------------+
```

## 仕込みボード: 担当

実装ファイル: `apps/ios/Sources/PrepFlow/ContentView.swift`
主 View: `StaffBoardContent`

```text
+--------------------------------------------------------------------------------+
| StaffBoardContent                                                               |
|                                                                                |
| +---------------------------+ +---------------------------+ +----------------+ |
| | StaffColumn               | | StaffColumn               | | StaffColumn    | |
| | - 担当者 / 負荷           | | - 担当者 / 負荷           | | - 担当者      | |
| | - StaffTaskCard           | | - StaffTaskCard           | | - タスク群    | |
| | - StaffImpactCard         | | - StaffImpactCard         | | - 影響        | |
| +---------------------------+ +---------------------------+ +----------------+ |
+--------------------------------------------------------------------------------+
```

## 今これ手順 Sheet

実装ファイル: `apps/ios/Sources/PrepFlow/NowGuidanceSheet.swift`
正本ワイヤー: `design/p0-wireframe-board-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> NowGuidanceSheet                                                        |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | GuidanceWorkStatePanel            | | TodayPrepImpactPanel                  | |
| | - 現在の担当者                   | | - 影響行                              | |
| | - 開始/一時停止/再開             | | - 適用/却下                           | |
| | - 実績分数の調整                 | |                                       | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | GuidanceReadinessGate             | | AssistProposalCard                    | |
| | - GuidanceCheckRow                | | - 遅延/不足提案                       | |
| | - 完了チェック状態               | | - 応援適用                            | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | GuidanceStepRow リスト / 取り消し / 次を完了                                 ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## Catalog Editor（カタログ編集）

実装ファイル: `apps/ios/Sources/PrepFlow/CatalogEditorView.swift`
正本ワイヤー:

- `design/p1-wireframe-template-editor-liquidglass.png`
- `design/p1-wireframe-prepitem-editor.png`

```text
+--------------------------------------------------------------------------------+
| [glass] CatalogTopBar                                                           |
+--------------------------------------------------------------------------------+
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | CatalogTree                       | | CatalogDetail                         | |
| | - 料理行                          | | - タスク項目                          | |
| | - コンポーネント行                | | - スケール方式                        | |
| | - タスク行                        | | - 収量 / リード / 所要時間            | |
| | - 追加ボタン                      | | - 手順 / メディア枠                   | |
| +-----------------------------------+ | - CatalogPreview                      | |
|                                       | - CatalogSavedStatus                  | |
|                                       +---------------------------------------+ |
+--------------------------------------------------------------------------------+
```

## Settings Home（設定ホーム）

実装ファイル: `apps/ios/Sources/PrepFlow/SettingsHomeView.swift`
正本ワイヤー: `design/p1-wireframe-settings-home-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] SettingsTopBar                                                          |
|         board へ戻る / session / サインアウト                                  |
+--------------------------------------------------------------------------------+
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | SettingsCard: Account             | | SettingsCard: Store / service         | |
| | - 認証プロバイダ                  | | - 営業時刻 (time)                     | |
| | - tenant 準備状態                 | | - テーマ / ロック / 書き出し          | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | SettingsToast                                                                 ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## 締め -> 翌日 Sheet

実装ファイル: `apps/ios/Sources/PrepFlow/CloseLoopSheet.swift`
正本ワイヤー:

- `design/p2-wireframe-close-flow-liquidglass.png`
- `design/p2-wireframe-close-nextday-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> CloseLoopSheet                                                          |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | CloseLoopQtyStepper               | | CloseLoopPreview                      | |
| | - 仕込み済み数量                  | | - 廃棄 / 持越し概要                 | |
| | - 残数量                          | | - 翌日への影響                      | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | CloseLoopDecisionPicker           | | CloseLoopBatchTable                   | |
| | CloseLoopReasonPicker             | | - CloseLoopBatchRow                  | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | CloseLoopLearningFeed             | | CloseLoopNextDayPanel                 | |
| | - 学習用の廃棄記録                | | - CloseLoopNextDayRow                | |
| +-----------------------------------+ +---------------------------------------+ |
+--------------------------------------------------------------------------------+
```

## 予約ハブ Sheet

実装ファイル: `apps/ios/Sources/PrepFlow/ReservationHubSheet.swift`
正本ワイヤー: `design/p2-wireframe-reservation-hub-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> ReservationHubSheet                                                     |
|                                                                                |
| [glass] ReservationHubTopBar                                                    |
|         取得元 chips / 再同期 / 適用                                            |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | ReservationHubList                | | ReservationHubApplyPanel              | |
| | - ReservationHubRow               | | - 適用ゲート状態                      | |
| | - 重複アラート                    | | - パネル行                            | |
| | - 取得元状態                      | | - 適用済み状態                        | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | ReservationConnectorReviewPanel                                             ||
| | - connector 差分レビュー行                                                 ||
| | - 承認/却下                                                                  ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## 予約おもてなし Panel

実装ファイル: `apps/ios/Sources/PrepFlow/ReservationOmotenashiPanel.swift`
正本ワイヤー:

- `design/p2-wireframe-special-prep.png`
- `design/p3-wireframe-allergy-message.png`
- `design/p3-wireframe-allergen-labels.png`

```text
+--------------------------------------------------------------------------------+
| ReservationOmotenashiPanel                                                      |
|                                                                                |
| +------------------------------+ +-------------------------------------------+ |
| | ReservationSpecialPrepRow    | | ReservationGuestReplyRecheckRow           | |
| | - 特別仕込みタスク          | | - 変更されたゲスト回答                   | |
| | - 割当/状態                 | | - 再確認の影響                           | |
| +------------------------------+ +-------------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | ReservationAllergenPreview                                                  ||
| | - アレルゲンラベルのプレビュー                                             ||
| | - 印刷/再印刷状態                                                           ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## ラベル / ラーダー / QR Sheet

実装ファイル: `apps/ios/Sources/PrepFlow/LabelOpsSheet.swift`
正本ワイヤー:

- `design/p2-wireframe-label-flow.png`
- `design/p2-wireframe-prep-larder.png`
- `design/p2-wireframe-label-settings.png`
- `design/p2-wireframe-fridge-lens.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> LabelOpsSheet                                                           |
|                                                                                |
| [glass] LabelOpsTopBar                                                          |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | LabelFlowColumn                   | | PrepLarderPanel                       | |
| | - 手順1 完了タスクプレビュー      | | - ラーダーKPI                         | |
| | - 手順2 ラベルプレビュー          | | - プリンタ設定                        | |
| | - 手順3 QR 残量/廃棄              | | - 冷蔵庫レンズ                        | |
| | - 手順4 持越しプレビュー          | | - ラーダー品目                        | |
| +-----------------------------------+ | - FIFO フッター                       | |
|                                       +---------------------------------------+ |
+--------------------------------------------------------------------------------+
```

## Direct Booking Sheet（Direct予約）

実装ファイル: `apps/ios/Sources/PrepFlow/DirectServiceOpsSheet.swift`
正本ワイヤー: `design/p3-wireframe-direct-booking.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> DirectBookingOpsSheet                                                   |
|                                                                                |
| +------------------------------+ +-------------------------------------------+ |
| | DirectBrandPanel             | | DirectStepCard stack                      | |
| | - 予約元                     | | - 人数カード                            | |
| | - 枠 / 残数                  | | - コースカード                          | |
| +------------------------------+ | - メモカード                            | |
|                                  | - 決済カード                            | |
|                                  +-------------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | DirectOpsStatus                                                             ||
| | - checkout / no-show / waitlist / 仕込み影響                                ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## Service Pass Sheet（サービス進行）

実装ファイル: `apps/ios/Sources/PrepFlow/DirectServiceOpsSheet.swift`
正本ワイヤー: `design/p4-wireframe-passview.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> ServicePassOpsSheet                                                     |
|                                                                                |
| [glass] ServicePassTopBar                                                       |
|         segmented mode / 同期操作                                               |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | ServicePassMatrix                 | | ServiceRemainingBoard                 | |
| | - ServicePassCell グリッド        | | - 残数                                | |
| | - fire / hold / 提供済み状態      | | - ペース提案                          | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | ServiceFireBanner                 | | ServiceSyncPanel                      | |
| | - 緊急 fire/hold 状態             | | - オフライン送信                      | |
| +-----------------------------------+ | - POS/KDS event replay                | |
|                                       +---------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | ServicePassStaffHandoff / ServiceTimelineRow                                 ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## Store / Engine / Data の接続

```text
SwiftUI View
  |
  | ユーザー操作
  v
BoardStore または AuthStore
  |
  +-- 純粋計算 ---------------------------------------------+
  |                                                         |
  |  Engine                                                 |
  |   - calcQty                                             |
  |   - schedule                                            |
  |   - rollup                                              |
  |   - ETA / today-prep                                    |
  |   - close / carryover                                   |
  |   - reservation diff                                    |
  |   - label / larder                                      |
  |   - direct / service sync                               |
  |                                                         |
  +-- ローカル永続化 --------------------------------------+
                                                            |
     PrepFlowDatabase (GRDB SQLite)
      - tenant スコープ行
      - event log
      - settings payload
      - ローカル縮退
      - 再起動時の状態復元
```

## 修正手順

```text
1. この文書で対象画面または sheet を選ぶ。
2. 記載されている正本デザインファイルを design/ で開く。
3. 記載されている Swift ソースファイルを開く。
4. 大枠の構造を維持する。
   - 上部 glass layer
   - 不透明 content layer
   - 下部/sheet glass layer
5. 色 / font / radius / spacing / motion は DesignTokens のみ使う。
6. PrepFlowColor.time は time / NOW / 遅延 / 期限 / 緊急のみに使う。
7. PrepFlowColor.time の使用箇所には必ず // time-use: を付ける。
8. すべての SwiftUI View 近くに // 正本: design/... を維持する。
9. 最低限、次を走らせる。
   swiftformat --lint .
   swiftlint --strict
   xcodebuild test ... -only-testing:PrepFlowSnapshotTests
10. 見た目の構造を意図的に変える場合:
   先に design/ を更新し、PNG を render してから snapshot/comparison を更新する。
```

## Snapshot 比較ファイル

```text
docs/ui-comparisons/testAuthGateMatchesSourceWire.p0-wireframe-onboarding-liquidglass.comparison.png
docs/ui-comparisons/testActivationMatchesSourceWire.p0-wireframe-activation-liquidglass.comparison.png
docs/ui-comparisons/testSimulationMatchesSourceWire.p0-wireframe-simulation-liquidglass.comparison.png
docs/ui-comparisons/testServiceSetupMatchesSourceWire.p0-wireframe-service-setup-liquidglass.comparison.png
docs/ui-comparisons/testBoardNowMatchesSourceWire.p0-wireframe-board-liquidglass.comparison.png
docs/ui-comparisons/testBoardDishesMatchesSourceWire.p1-wireframe-view-dishes-liquidglass.comparison.png
docs/ui-comparisons/testBoardStaffMatchesSourceWire.p1-wireframe-view-staff-liquidglass.comparison.png
docs/ui-comparisons/testCatalogEditorMatchesSourceWire.p1-wireframe-template-editor-liquidglass.comparison.png
docs/ui-comparisons/testSettingsHomeMatchesSourceWire.p1-wireframe-settings-home-liquidglass.comparison.png
```
