# PrepFlow design/ — 成果物インデックス

軽量版PrepFlow（コース・予約主体の中〜高級飲食店向け 仕込み管理SaaS）の画面設計・図版一式。
各成果物は **自己完結HTML＋PNG** のペア（HTMLはブラウザで直接開けます）。
要件定義本文は [`../docs/requirements.md`](../docs/requirements.md)（v1.3）。

## 確定デザイン言語
- **白基調＋黒文字＋グレー**、アクセントは**朱 `#c2410c` 1色のみ＝「時間/NOW/遅延/緊急」専用**
- 3つ星運営思想：**T−逆算表記・開店カウントダウン・ライン点検ゲート**
- 3ビュー切替（今これ／皿ごと／担当）、タブレット特化（1180×812想定）、大タッチ領域・最小文字
- アラート3段階：トースト → バナー → 全画面反転＋音（FR-22）

---

## 0. 全画面サムネ集（最初に見る索引）

| 成果物 | ファイル | 内容 |
|---|---|---|
| **設計一覧（全画面サムネ集）** | `overview-gallery.html/.png` | **64画面 / 7カテゴリ**を1枚に。各サムネにラベル＋FRタグ |

## 1. 図版（リサーチ・全体設計）

| 成果物 | ファイル | 内容 |
|---|---|---|
| 競合ポジショニング図 | `competitive-positioning.html/.png` | V-Manage／カミナシ／PrepFlowの2軸マップ＋機能比較表 |
| 画面遷移図（フロー） | `flow-screen-map.html/.png` | ①初回セットアップ ②日次運用ループ ③振り返り・管理の3レーン |

## 2. 初期ワイヤーフレーム（v0.2世代・ティール基調）

| 画面 | ファイル | 対応FR |
|---|---|---|
| オンボーディング（業態テンプレ選択） | `p0-wireframe-onboarding.html/.png` | NFR-07 |
| 本日のサービス設定／予約メール取込 〔初期版・予約ハブ(FR-34)へ統合〕 | `p0-wireframe-service-setup.html/.png` | FR-02/10 |
| 今日のタスク（仕込みボード） | `p0-wireframe-todaytask.html/.png` | FR-01/03/05/06/11/17 |
| コーステンプレ編集 | `p1-wireframe-template-editor.html/.png` | FR-01/03/06 |
| ダッシュボード | `p1-wireframe-dashboard.html/.png` | FR-11/09/17 |
| HACCP電子チェックシート | `p2-wireframe-haccp-checklist.html/.png` | FR-16 |

## 3. リデザイン探求（3案×2世代）

| 世代 | ファイル | 内容 |
|---|---|---|
| 第1世代（白基調＋2色） | `redesign-A-bigcard` / `redesign-B-kanban` / `redesign-C-focus` | ビッグカード／担当カンバン／フォーカス |
| 第2世代（確定・配色削減） | `redesign2-1-ink` / `redesign2-2-passsheet` / `redesign2-3-oneaccent` | INK（完全モノクロ）／PASS SHEET（帳票）／ONE ACCENT（朱1色）— **3テーマとも採用（要件§13）** |
| **実装スキン（iOS / Liquid Glass）** | `p0-wireframe-board-liquidglass.html/.png` | **今これボードの Liquid Glass 版**（iPad/iOS 26）。グラス=機能レイヤーのみ・コンテンツ不透明・朱=時間（A-12）。SwiftUI実装の視覚基準 |
| ├ 皿ごとビュー（LG） | `p1-wireframe-view-dishes-liquidglass.html/.png` | 上部バー＋ゲートのみガラス |
| ├ 担当ビュー（LG） | `p1-wireframe-view-staff-liquidglass.html/.png` | 上部バーのみガラス・カンバン不透明 |
| ├ 閉店・締めフロー（LG） | `p2-wireframe-close-flow-liquidglass.html/.png` | 上部バー＋ステッパー＋下部操作ガラス |
| ├ 予約ハブ（LG） | `p2-wireframe-reservation-hub-liquidglass.html/.png` | 上部バー＋ソースチップガラス・重複警告は不透明 |
| ├ オンボーディング（LG・P0） | `p0-wireframe-onboarding-liquidglass.html/.png` | 上部ステップ＋下部操作ガラス |
| ├ コーステンプレ編集（LG・P0） | `p1-wireframe-template-editor-liquidglass.html/.png` | 上部バーガラス・編集面は不透明 |
| ├ 本日のサービス設定（LG・P0） | `p0-wireframe-service-setup-liquidglass.html/.png` | 手入力主・メール取込は準備中（FR-10降格） |
| ├ シミュレーション並走（LG・P0） | `p0-wireframe-simulation-liquidglass.html/.png` | 上部バーガラス・KPI/比較表は不透明 |
| └ 設定ホーム（LG・P0） | `p1-wireframe-settings-home-liquidglass.html/.png` | 上部バー＋トースト（ダークガラス）|

> **P0実装6画面は Liquid Glass で完全カバー**：オンボーディング／テンプレ編集／サービス設定／ボード（今これ・皿ごと）／シミュレーション／設定ホーム。SwiftUI実装の視覚基準。

### v1.5 追加機能の Liquid Glass ワイヤー（`proposal-optimization.md` 採用分）
| 画面 | ファイル | 対応FR |
|---|---|---|
| 着地予測ボード「間に合う/危ない」 | `p1-wireframe-board-eta-liquidglass.html/.png` | FR-59 |
| 活性化サマリー（シミュ先行オンボ・TTV） | `p0-wireframe-activation-liquidglass.html/.png` | FR-63 |
| 多店舗オーナー切替（本部統制でない） | `p1-wireframe-multistore-liquidglass.html/.png` | FR-66 |
| 信頼性運用網（solo版SRE） | `p1-wireframe-reliability-liquidglass.html/.png` | FR-67 |
| 締め→翌日ループ＋廃棄理由タグ | `p2-wireframe-close-nextday-liquidglass.html/.png` | FR-68 |

## 4. 確定テーマの画面（モノクロ＋朱）

| 画面 | ファイル | 対応FR / Ph |
|---|---|---|
| 今これビュー（フォーカス） | `redesign2-3-oneaccent.html/.png` | FR-04/05/06 |
| 皿ごとビュー | `p1-wireframe-view-dishes.html/.png` | FR-04/05（皿の自動ロールアップ俯瞰） |
| 担当ビュー | `p1-wireframe-view-staff.html/.png` | FR-07（セクション別負荷） |
| 営業中サービスボード | `p2-wireframe-service-board.html/.png` | FR-19/21/22（P2） |
| 状態バリエーション（遅延／点検NG／全画面） | `p2-wireframe-state-alerts.html/.png` | FR-22（アラート3段階） |
| パスビュー（卓×コース） | `p4-wireframe-passview.html/.png` | FR-24/25/27（P4 Service Sync） |
| ホール側UI（ハンディ＋タッチパネル） | `p4-wireframe-hall-handy.html/.png` | FR-25/26/27/28（P4 Service Sync） |
| 設定画面 〔初期版・設定ホーム(FR-52)＋5サブ画面へ分割置換〕 | `p1-wireframe-settings.html/.png` | FR-14/15/10・§13テーマ切替・T−規律既定値 |
| デイレール（業務×仕込み 1日ビュー） | `p1-wireframe-dayrail.html/.png` | FR-31/32（業務フローを同じT−軸に混在） |
| Direct予約ページ（ゲスト直販動線） | `p3-wireframe-direct-booking.html/.png` | FR-35（コース事前選択・アレルギー・事前決済） |
| 予約ハブ（複数ソース合算・重複警告） | `p2-wireframe-reservation-hub.html/.png` | FR-34 |
| Direct設定・店舗側（アロットメント/デポジット/コース公開） | `p3-wireframe-direct-settings.html/.png` | FR-35/36 |
| コース手動割当モーダル（予約ハブ） | `p2-wireframe-course-assign.html/.png` | FR-34 |
| Direct確定メール＋ゲストマイページ | `p3-wireframe-direct-mypage.html/.png` | FR-35（リマインド・キャンセル動線） |
| 仕込みアイテム編集（スケール則/自動手動/自己補正/合算） | `p1-wireframe-prepitem-editor.html/.png` | FR-37/38/09 |
| シミュレーション並走（実績 vs 推奨） | `p0-wireframe-simulation.html/.png` | FR-39 |
| 複数日デイレール（今日提供＋前倒し） | `p1-wireframe-dayrail-multiday.html/.png` | FR-40/41 |
| 営業日カレンダー設定 | `p1-wireframe-calendar.html/.png` | FR-17/40の基礎（設定追加） |
| ラベル運用フロー（完了→印刷→QR残量→繰越） | `p2-wireframe-label-flow.html/.png` | FR-20/42/45/46 |
| 「今ある半製品」ビュー（作り置き・残量・期限） | `p2-wireframe-prep-larder.html/.png` | FR-45（ラベルモード） |
| ラベルモード設定（プリンタ接続） | `p2-wireframe-label-settings.html/.png` | FR-48 |
| 冷蔵庫QRレンズ／点検モード | `p2-wireframe-fridge-lens.html/.png` | FR-49/50 |
| モード設定（ラベル/HACCP・冷蔵庫登録） | `p2-wireframe-modes-settings.html/.png` | FR-48/49/51・モード制 |
| HACCPモード設定（チェック項目・基準温度） | `p2-wireframe-haccp-settings.html/.png` | FR-16/51 |
| 設定ホーム（ハブ・1機能1場所） | `p1-wireframe-settings-home.html/.png` | FR-52/54・§4.7 |
| ├ セクション・スタッフ | `p1-wireframe-staff-sections.html/.png` | FR-07/43 |
| ├ 営業帯・T−規律 | `p1-wireframe-service-periods.html/.png` | FR-41/22 |
| ├ 仕込み・数量の既定 | `p1-wireframe-prep-defaults.html/.png` | FR-09/19/40/42 |
| ├ プラン・支払い／データ | `p1-wireframe-billing-data.html/.png` | FR-14/15 |
| ├ 端末管理 | `p1-wireframe-devices.html/.png` | FR-53/12 |
| 席番アレルゲン・ラベル | `p3-wireframe-allergen-labels.html/.png` | FR-47（参考表示） |
| 店側キャンセル・ノーショー処理 | `p2-wireframe-cancellation.html/.png` | FR-55/56 |
| TableCheck連携設定 | `p3-wireframe-tablecheck-settings.html/.png` | FR-13 |
| 特別仕込み（おもてなし→自動生成） | `p2-wireframe-special-prep.html/.png` | FR-57 |
| アレルギー事前確認メッセージ（店側設定＋ゲストLINE） | `p3-wireframe-allergy-message.html/.png` | FR-58（Messaging API・参考確認） |
| 閉店・締めフロー（締めゲート＋パー/廃棄＋申し送り） | `p2-wireframe-close-flow.html/.png` | FR-33/23/08（1日の締めゲート・FR-09/42へ環流） |

---

## PNGの再生成

```bash
cd design
npm i                                   # puppeteer（node_modules はコミット対象外）
npx puppeteer browsers install chrome
node render-batch4.mjs                  # 各 render-*.mjs が対象PNGを出力（幅1240・2x・fullPage）
```

render スクリプト対応：`render.mjs`（図版2点）/ `render-add.mjs`（初期3画面）/ `render-one.mjs`・`render-onb.mjs`・`render-flow.mjs`（単発）/ `render-redesign.mjs`・`render-redesign2.mjs`（リデザイン各3案）/ `render-v03.mjs`（営業中・パス）/ `render-batch4.mjs`（皿ごと・担当・ホール・状態）
