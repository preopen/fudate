# WS2 同期スパイク結果

## 結論

P0の同期方式は **GRDB + 自作同期** を採用する。

PowerSync Swift SDK + Supabase Postgres は要件に技術適合するが、実検証には Supabase プロジェクト、PowerSync インスタンス、Sync Streams、認証/接続資格情報が必要。現時点では資格情報がないため、GOゲートの実測対象から外し、次候補の GRDB 自作同期を検証した。

## 検証実装

- 実装: `packages/SyncSpike`
- ローカル: 端末ごとの SQLite/GRDB レプリカ
- サーバ相当: `SyncHub` actor
- 競合規則:
  - チェックオフ: 冪等な `done`
  - 数値: `updated_at` による LWW
  - 数値履歴: 全 mutation を `quantity_history` に保持
  - offline: `outbox` に蓄積し、復帰時に push/pull

## D2 合格基準

| 基準 | 結果 |
|---|---|
| 2台のiPadでチェックオフ相互反映 < 2秒 | 2端末相当の SQLite レプリカで 0.010s |
| 機内モード30分→復帰で無損失マージ | outbox 0、チェック完了維持、数量履歴3件保持 |
| 完了は冪等、数値はLWW＋履歴保持 | green |
| 2世代前相当でも当日ボード操作が体感即時 | 100件local write 0.103s |
| offline中も当日ボード完全動作 | local SQLite read/write green |

## コマンド

```bash
swift test --package-path packages/SyncSpike
```

結果: 4 tests, 0 failures.

## 未実施/後続

- 実機2台 + Supabase + PowerSync の実接続検証は資格情報が必要。
- WS3以降は GRDB + 自作同期を前提に、Supabase Postgres/RLS と同期API境界を実装する。
