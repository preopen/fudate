# 実装エージェント向け キックオフ・プロンプト（コピペ用）

Codex / Sonnet / その他のコーディングエージェントに**そのまま貼る**ためのプロンプト集。
1メッセージ＝1WS。WS0→WS1→…の順。各PRは `CODEX_HANDOFF.md §0`(DoD)・`§4`(受入)・`§6`(ガードレール) を満たすこと。

---

## ⓪ 最重要・UI正本固定（全UI作業の前提・最初に必ず渡す）
> 実装が進むほどワイヤーから剥がれる事故を構造的に防ぐ。詳細・命令文は **`docs/ui-fidelity-contract.md`**（§0にコピペ用の厳守命令）。
> 要旨：design/ の Liquid Glass ワイヤー＋縦ぎりが**唯一の正本**。Liquid Glass は機能層のみ／**朱は時間/NOW/遅延のみ**（進捗・選択・装飾に使わない）／色・フォント・角丸は **DesignTokens 経由のみ**（ハードコード禁止・Satoshi）／ボードのナビは上部バー＋セグメント切替（サイドバーで3ビュー代替禁止）。**UIを変えるなら先にワイヤーを更新**してから実装。各UI PRは「スクショ↔ワイヤーPNG」横並び＋チェックリストでゲート。

## ① 最初に渡す共通コンテキスト（全WS共通・最初の1回）
```
あなたはリポジトリ preopen/fudate で iOSアプリ「PrepFlow」を P0 までステージング可能に実装するシニアiOSエンジニアです。
まず CODEX_HANDOFF.md を読み、続けて docs/architecture.md / docs/engine-api.md / golden/ / docs/data-schema.md / docs/requirements.md / design/ を参照してください。
鉄則：
- 守る線（CODEX_HANDOFF.md §6 ガードレール）と 完成の定義（§0 DoD）を厳守。
- 1 WS = 1 PR。PRタイトルとコミットに WS番号 と FR番号 を明記。
- 秘密情報（.env・署名鍵）はコミットしない。.env.example を最新に保つ。
- 数値の正は golden/*.json。UIの正は design/ の対応ワイヤー。矛盾したら golden/ と CODEX_HANDOFF.md が優先。
- Engine は純関数（Date()/乱数/IO禁止・すべて引数注入）。色の朱は時間/NOW/遅延のみ。Liquid Glass はコンテンツ層に使わない（A-12）。
准備ができたら「WS0」から着手します。
```

## ② WS0 — 足場
```
WS0 を実装してください。CODEX_HANDOFF.md §3 の雛形を materialize します：
- packages/Engine/Package.swift（テストに golden を同梱）
- packages/DesignTokens/Package.swift ＋ design/ の確定トークンをコード化
  （ink #15171a / g2 #70757b / g3 #c2c6ca / g4 #e9ebed / g5 #f6f7f8 / time(朱) #c2410c / ok #3a6a2a、Satoshi、間隔・角丸・spring。朱は時間/NOW/遅延/緊急のみ）
- apps/ios/project.yml（xcodegen・iOS26・iPad横向き・Engine/DesignTokens/GRDB依存）
- .github/workflows/ci.yml
- supabase/ 骨格（config.toml の雛形）
受入：`cp -R golden packages/Engine/Tests/EngineTests/golden && swift test --package-path packages/Engine`（空でも成功）／`cd apps/ios && xcodegen generate`／`xcodebuild build -scheme PrepFlow -destination 'platform=iOS Simulator,name=iPad Pro 11-inch,OS=26.0'` が成功し CI green。
ブランチ ws0-scaffold、PR「WS0 足場」。まずビルドを通すことを最優先に。
```

## ③ WS1 — Engine（TDD）
```
WS1 を実装してください。docs/engine-api.md の契約に厳密に従い packages/Engine/Sources/Engine に下記を実装：
calcQty / aggregateSubrecipes / diffPlan / schedule / rollup / etaProjection / selfCorrect / applyCarryover / generateInstances。
packages/Engine/Tests/EngineTests に golden/*.json を読み込む XCTest を書き、全 cases を green にする（浮動小数は 1e-6、時刻は "HH:mm" 文字列一致）。境界（丸め195/205・0.5tie・空配列・yield不正）も追加。
鉄則：純関数（Date()/乱数/IO 禁止）。Foundation 最小依存でプラットフォーム非依存（macOSでもテストが回る）。
受入：`swift test --package-path packages/Engine` 全 green。
ブランチ ws1-engine、PR「WS1 Engine (FR-03/05/06/09/19/34/37/38/40/42/55/59)」。
```

## ④ WS2 — 同期スパイク（GOゲート）
```
WS2：オフライン同期の技術検証（CODEX_HANDOFF.md §5）。候補順 ① PowerSync(Swift SDK)＋Supabase Postgres → ② GRDB＋自作同期 → ③ SwiftData。
合格基準：2台のiPadでチェックオフ相互反映<2秒／機内モード30分→復帰で無損失マージ（完了は冪等・数値LWW＋履歴）／2世代前iPadで体感即時／オフライン中も当日ボード完全動作。
最初に通った候補を確定し、結果を docs/architecture.md D2 に追記。**このゲートを越えるまで WS4 以降のUI量産はしない**。
ブランチ ws2-sync-spike、PR「WS2 同期スパイク（GOゲート）」。
```

## ⑤ 以降（順に同形式で）
- WS3 スキーマ＋データ層（GRDB＋Supabase migrations＋RLSテナント分離）／受入：data-schema.md ★テーブル・CRUD・RLSテスト
- WS4 Boardシェル（今これ/皿ごと・チェックオフ・ロールアップ・着地予測・Liquid Glass・A-12）
- WS5 Catalogエディタ ／ WS6 ServiceDay設定＋人数手入力 ／ WS7 シミュレーション＋WasteLog＋活性化 ／ WS8 認証(Apple＋マジックリンク・招待制・RLS)
- WS9 P0統合・TestFlight（または Release アーカイブ）＝ §0 DoD 全項目

> 各WSの受入は CODEX_HANDOFF.md §4 を参照。P0スコープ外（締め/予約ハブUI/モード/多店舗/信頼性運用網の残り）は P1+。
