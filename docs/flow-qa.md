# Flow QA Harness

目的: PrepFlow の「触れるが全機能を使えない」穴を、ユーザー視点の流れで毎回確認できるように固定する。

## 正本

- UI契約: `docs/ui-fidelity-contract.md`
- ASCII流れ順: `docs/ascii-user-flow-screens.md`
- ハイフィディリティ流れ順: `design/high-fidelity-user-flow.html` / `design/high-fidelity-user-flow.png`
- 画面正本: `design/p0-wireframe-*.png`、`design/p1-wireframe-*.png`、`design/p2-wireframe-*.png`、`design/p3-wireframe-*.png`、`design/p4-wireframe-*.png`
- 比較画像: `docs/ui-comparisons/*.comparison.png`
- PR運用: `.github/pull_request_template.md`、`docs/ui-comparisons/README.md`

## ユーザー流れ

| 順 | 画面 | 必須操作 | 戻り先 |
| --- | --- | --- | --- |
| 01 | `AuthGateView` | Apple / magic link / SQLite 縮退で入る | `ActivationSummaryView` |
| 02 | `ActivationSummaryView` | 初期状態と不足秘密を確認し、シミュへ進む | `SimulationView` |
| 03 | `SimulationView` | 期間変更、人数調整、数字反映 | `ServiceSetupView` |
| 04 | `ServiceSetupView` | 人数手入力、編集、ボード生成 | `PrepFlowBoardView` |
| 05 | `PrepFlowBoardView` 今これ | 着手、停止、再開、確認まとめ、次完了、取り消し | `NowGuidanceSheet` / `LabelOpsSheet` |
| 06 | `PrepFlowBoardView` 皿ごと | 料理単位チェック、予約/営業影響の適用/却下 | 今これ |
| 07 | `PrepFlowBoardView` 担当 | 担当単位チェック、影響適用、ライン点検状態確認 | 今これ |
| 08 | `CatalogEditorView` | 保存、プレビュー、削除 | 今これ |
| 09 | `SettingsHomeView` | 最小設定、export、lock確認 | 今これ |
| 10 | `CloseLoopSheet` | 余り/廃棄/持越しを記録 | `ReservationHubSheet` |
| 11 | `ReservationHubSheet` | 手入力/CSV差分を仕込みへ反映 | 今これ |
| 12 | `DirectBookingOpsSheet` | direct予約を差分として取り込む | `ReservationHubSheet` |
| 13 | `ServicePassOpsSheet` | fire/hold、残数、再同期 | 今これ |

## Board 操作チェック

- `BoardTopBar` の segmented control だけで「今これ / 皿ごと / 担当」を切り替える。サイドバーで代替しない。
- 今これは `BoardOperationStrip` と `BoardWorkStatePanel` を常時表示し、着手前でも操作が発見できる。
- 着手、停止、再開、確認まとめ、次完了、取り消しの結果が `BoardStore`、`event_log`、`LineGateBar` に反映される。
- 皿ごと/担当は `BoardModeStatusHeader` で次工程、完了数、残分、開店ゲート詰まりを表示する。
- 予約/営業/ゲスト影響は適用または後回しにでき、未解決件数が開店ゲートへ残る。
- 進捗バーと選択状態は INK。朱 `#c2410c` 相当は NOW、T-minus、遅延、期限、緊急だけに使う。
- Liquid Glass は上部バー、セグメント切替、T-minus島、下部アクション、sheet など機能層だけに使う。

## Sheet 導線チェック

| 親画面 | Sheet | 開く操作 | Sheet内操作 | 戻り |
| --- | --- | --- | --- | --- |
| `PrepFlowBoardView` | `NowGuidanceSheet` | `BoardBottomBar` の手順ガイド | 着手、確認、遅れ確認、次完了、取り消し | drag down / ボード継続 |
| `PrepFlowBoardView` | `LabelOpsSheet` | ライン点検OK後の下部アクション | ラベル作成、QR残量、繰越、PDF/印刷 | `閉じる` |
| `SimulationView` | `CloseLoopSheet` | `本適用する` / 結果パネル適用 | 単品記録、締め表、締めゲート | `明日のボードへ` または `予約差分へ` |
| `SimulationView` | `ReservationHubSheet` | `CloseLoopSheet` の予約差分 | 差分適用、再同期、Direct、Service Pass | `閉じる` または適用後Board |
| `ReservationHubSheet` | `DirectBookingOpsSheet` | `PrepFlow Direct` 操作 | 枠判定、直販予約確定、キャンセル、厨房反映 | `予約ハブへ` |
| `ReservationHubSheet` | `ServicePassOpsSheet` | `サービス進行` 操作 | fire/hold、提供済み、オフライン保存、再同期 | `予約ハブへ` |

## 戻り導線チェック

- `SettingsHomeView` の `今日へ` は `PrepFlowBoardView` へ戻る。
- `SettingsHomeView` の営業帯行は `ServiceSetupView` へ進み、`今日へ` または `この内容で当日ボードを生成` で戻る。
- `SettingsHomeView` のプラン行は `CatalogEditorView` へ進み、`今日へ` または `当日ボードでプレビュー` で戻る。
- `SettingsHomeView` の繰越差引行は `SimulationView` へ進み、`今日へ` で戻る。
- `CatalogEditorView` の保存は画面に留まり、プレビューはBoardへ戻る。
- `ServiceSetupView` の人数編集と予約編集は画面に留まり、生成はBoardへ戻る。

## 実機確認メモ

1. iPad Pro 11-inch で `AuthGateView` から入る。
2. `SimulationView` で人数を変え、`ServiceSetupView` でボード生成する。
3. 今これで「着手」してから「停止」「再開」「確認まとめ」「次完了」を順に触る。
4. 「取り消し」で次工程が戻ることを確認する。
5. 皿ごとで煮切り/ネタ/椀物のチェックを触り、今これへ戻る。
6. 担当で親方/ガルド/シェフのチェックを触り、LineGateBar の詰まりが減ることを確認する。
7. 未解決影響を残した状態ではライン点検が開かず、適用/却下後に開くことを確認する。
8. `SettingsHomeView` の export で現在状態が出ることを確認する。
9. `SettingsHomeView` から Service Setup / Catalog / Simulation を開き、各画面からBoardへ戻る。
10. `CloseLoopSheet` から `ReservationHubSheet`、さらに Direct / Service Pass を開き、それぞれ親へ戻る。

## コマンド

```sh
swift test --package-path packages/Engine
swift test --package-path packages/Data
cd apps/ios
xcodegen generate
xcodebuild build -project PrepFlow.xcodeproj -scheme PrepFlow -destination 'platform=iOS Simulator,name=iPad Pro 11-inch,OS=26.5'
xcodebuild test -project PrepFlow.xcodeproj -scheme PrepFlow -destination 'platform=iOS Simulator,name=iPad Pro 11-inch,OS=26.5' -only-testing:PrepFlowSnapshotTests
swiftlint --strict
swiftformat --lint ../..
cd ../..
rg -n 'Color\(red:|#[0-9A-Fa-f]{6}|\.font\(\.system' apps/ios/Sources
```

GitHub hosted runner に iOS 26 SDK / Xcode 17+ がない場合、app build/snapshot CI は明示 skip で green にし、上記ローカル結果を PR 本文へ残す。
