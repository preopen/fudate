# PrepFlow v1.3 整合チェック — FR×画面 カバレッジ・マトリクス

| 項目 | 内容 |
|---|---|
| 対象 | 要件定義 v1.3（FR-01〜58）× design/ 全画面（49画面）|
| 日付 | 2026-06-12（updated）|
| 目的 | 要件と画面設計のトレーサビリティ確認。**抜け漏れ（未ワイヤー化FR）**と**重複（機構共有・世代重複）**の棚卸し |
| 凡例 | ✓=専用ワイヤーあり ／ △=別画面に内包・テーマ/アンカーで代替（専用画面なし）／ ✗=ワイヤー無し |

> **更新（2026-06-12）**：推奨アクション①②を反映。**「閉店・締めフロー」ワイヤー新規作成**（`p2-wireframe-close-flow`）で **FR-33/23/08 を充足**。索引の**世代ラベル注記（a/b/c）も反映済み**。下表・サマリーは反映後の値。

---

## 0. サマリー（結論）

- **FR充足率：53/58 が専用ワイヤーあり（✓）。** 残り5件は △2・✗3。
- **致命的な抜けは無し。** 未充足は全て **優先度C かつ 後段フェーズ（P2.5/P3）または将来** に集中。
- **～~最大の単一ギャップ＝「閉店・締めフロー」~~ → 解消済み。** FR-33（クローズフロー・S/P2）／FR-23（引き継ぎノート・P2）／FR-08（パー/廃棄記録・S/P1）を **`p2-wireframe-close-flow` 1枚で一括充足**（締めゲート＝5ステップ：クローズ点検→衛生記録→繰越/廃棄→申し送り→日次サマリー）。朝↔夜の運用ループが画面上で閉じた。
- **「重複FR」は実害なし。** ID重複（同番号の二重定義）はゼロ。見かけ上の重複は全て **(a) 意図した機構共有**（追い仕込みエンジン／WasteLog／席別アレルギー供給源）か **(b) 画面の世代置換**（初期案→確定テーマ）であり、要件本文に注記済み。本書で一覧化。

---

## 1. FR → 画面 トレーサビリティ表（FR-01〜58）

| FR | 機能 | 優先/Ph | 状態 | 主な対応画面 |
|---|---|---|:--:|---|
| FR-01 | コーステンプレート管理 | M/P0-1 | ✓ | template-editor, todaytask |
| FR-02 | 本日のサービス設定 | M/P0 | ✓ | service-setup ※reservation-hubへ昇格統合 |
| FR-03 | 仕込み量の自動算出 | M/P0 | ✓ | todaytask, template-editor |
| FR-04 | 当日仕込みボード | M/P0 | ✓ | redesign2-3-oneaccent, view-dishes, redesign系 |
| FR-05 | チェックオフ→ロールアップ | M/P0 | ✓ | redesign2-3-oneaccent, view-dishes |
| FR-06 | 逆算タイムライン | M/P1 | ✓ | oneaccent, todaytask, template-editor |
| FR-07 | 担当アサイン | S/P1 | ✓ | view-staff, staff-sections |
| FR-08 | パー/廃棄の記録 | **S/P1** | ✓ | close-flow（③本日のパー・廃棄記録：予約→作った→余った→繰越/廃棄）。simulation・prepitem-editorも参照 |
| FR-09 | 自己補正レシピ | S/P2 | ✓ | prepitem-editor, prep-defaults, simulation, dashboard |
| FR-10 | 予約メール取込 | C/保留（v1.4降格） | ✓ | service-setup, settings ※実装はパイロット需要の確認後 |
| FR-11 | ダッシュボード/分析 | S/P1-2 | ✓ | dashboard, todaytask |
| FR-12 | 複数フロア/複数厨房 | C/P2 | △ | devices設定に内包。**分割ボードの専用画面は未作成** |
| FR-13 | TableCheck深掘り連携 | **S戦略上位**/申請P0・構築P3 | ✓ | tablecheck-settings |
| FR-14 | アカウント/課金 | M/P0-1 | ✓ | settings, billing-data |
| FR-15 | データエクスポート | S/P1 | ✓ | billing-data, settings |
| FR-16 | 電子チェックシート(HACCP) | S/P2 | ✓ | haccp-checklist, haccp-settings |
| FR-17 | 定期タスク＋未実施アラート | S/P1 | ✓ | todaytask, dashboard, calendar |
| FR-18 | 多言語（厨房） | C/P3 | ✗ | **専用画面なし**。表示設定にIA枠のみ（将来） |
| FR-19 | 営業中サービスボード | S/P2 | ✓ | service-board, prep-defaults |
| FR-20 | 仕込みラベル自動発行 | C/P2.5 | ✓ | label-flow |
| FR-21 | 内蔵タイマー | S/P2 | ✓ | service-board |
| FR-22 | アラート3段階 | S/P2 | ✓ | service-board, state-alerts, service-periods |
| FR-23 | 引き継ぎノート | C/P2 | ✓ | close-flow（④申し送り：残仕込み自動転記＋入力＋記録者・翌日サービス設定へ自動表示）|
| FR-24 | パスビュー（卓×コース） | C/P4 | ✓ | passview |
| FR-25 | ファイア／ホールド | C/P4 | ✓ | passview, hall-handy |
| FR-26 | 席番アレルギー/VIPチップ | C/P4 | ✓ | hall-handy |
| FR-27 | 双方向の残数 | C/P4 | ✓ | passview, hall-handy |
| FR-28 | ペーシング提案 | C/P4 | ✓ | hall-handy |
| FR-29 | サービスリプレイ | C/P3 | ✗ | **専用画面なし**（FR-11の拡張） |
| FR-30 | コース版管理 | C/P2.5 | ✗ | **専用画面なし** |
| FR-31 | 業務フロー（デイレール） | S/P1.5 | ✓ | dayrail |
| FR-32 | 統合表示 | S/P1.5 | ✓ | dayrail |
| FR-33 | クローズフロー | **S/P2** | ✓ | close-flow（締めゲート＝5ステップを1本の流れで）。dayrailにも閉店アンカー |
| FR-34 | 予約ハブ | S/P2 | ✓ | reservation-hub, course-assign |
| FR-35 | Direct予約ページ | C/P3.5 | ✓ | direct-booking, direct-settings, direct-mypage |
| FR-36 | 直販アロットメント在庫 | C/P3.5 | ✓ | direct-settings |
| FR-37 | スケール則＋自動/手動 | S/P1 | ✓ | prepitem-editor |
| FR-38 | サブレシピ合算 | C/P1.5 | ✓ | prepitem-editor |
| FR-39 | シミュレーション並走 | S/P0 | ✓ | simulation |
| FR-40 | 複数日リードの仕込み | **M/P1** | ✓ | dayrail-multiday, calendar, prep-defaults |
| FR-41 | 二部制・複数営業帯 | **M/P1** | ✓ | dayrail-multiday, service-periods |
| FR-42 | 繰越残量の差引 | S/P2 | ✓ | label-flow, prep-defaults, cancellation |
| FR-43 | 完了者の記録（共有端末） | S/P1 | ✓ | staff-sections |
| FR-44 | 紙の仕込みリスト印刷 | C/P2.5 | △ | PASS SHEETテーマ(redesign2-2)が印刷帳票。**印刷/PDF出力の操作画面は未独立** |
| FR-45 | 期限アラート＋今ある半製品 | C/P2.5 | ✓ | label-flow, prep-larder |
| FR-46 | ラベルQRで残量/廃棄記録 | C/P2.5 | ✓ | label-flow |
| FR-47 | 席番アレルゲン・ラベル | C/P3 | ✓ | allergen-labels |
| FR-48 | ラベルプリンタ接続設定 | C/P2.5 | ✓ | label-settings, modes-settings |
| FR-49 | 冷蔵庫QR＝レンズ | C/P2.5-3 | ✓ | fridge-lens, modes-settings |
| FR-50 | 点検モード | C/P2.5 | ✓ | fridge-lens |
| FR-51 | 温度記録（冷蔵庫・加熱） | S/P2 | ✓ | modes-settings, haccp-settings |
| FR-52 | 設定ホーム（ハブ） | S/P1 | ✓ | settings-home |
| FR-53 | 端末管理 | C/P2 | ✓ | devices |
| FR-54 | 設定ロック | S/P1 | ✓ | settings-home |
| FR-55 | 店側キャンセル・ノーショー | S/P2・Direct分P3.5 | ✓ | cancellation |
| FR-56 | ウェイトリスト | C/P3.5 | ✓ | cancellation |
| FR-57 | おもてなし→特別仕込み・VIP | S/P2-3 | ✓ | special-prep |
| FR-58 | アレルギー事前確認メッセージ | C/P3 | ✓ | allergy-message |

**集計（更新後）：✓ 53 ／ △ 2（FR-12/44）／ ✗ 3（FR-18/29/30）**　※FR-08/23/33 は close-flow で充足

---

## 2. 抜け漏れの棚卸し（△・✗ の判定）

優先度・フェーズで「今すぐ要否」を判定。

| FR | 状態 | 優先/Ph | 判定・推奨 |
|---|:--:|---|---|
| ~~FR-33 クローズフロー~~ | ✓ | S/P2 | ✅ **解消済み**（close-flow） |
| ~~FR-08 パー/廃棄記録~~ | ✓ | S/P1 | ✅ **解消済み**（close-flow ③） |
| ~~FR-23 引き継ぎノート~~ | ✓ | C/P2 | ✅ **解消済み**（close-flow ④） |
| FR-12 複数厨房ボード | △ | C/P2 | devices設定で足りる。分割ボードはP2着手時に検討で可 |
| FR-44 紙リスト印刷 | △ | C/P2.5 | PASS SHEETテーマが実体。印刷操作はモーダルで足り、独立画面は不要寄り |
| FR-18 多言語 | ✗ | C/P3 | 将来。表示設定の枠だけで現状可 |
| FR-29 サービスリプレイ | ✗ | C/P3 | 将来。FR-11分析の拡張で後付け |
| FR-30 コース版管理 | ✗ | C/P2.5 | template-editorの「版」操作として後付け可 |

> 残る △2・✗3 は **全て優先度C＋後段/将来**。新規の独立画面は不要寄り（各画面の付随UI：モーダル/タブ/設定枠で後付け可）。

### ✅ 解消済み：「閉店・締めフロー」クラスタ（FR-33 + FR-23 + FR-08）
要件§4.2 FR-33の「クローズチェック→HACCP(FR-16)→引き継ぎ(FR-23)→日次サマリー」を**1本の流れ**として `p2-wireframe-close-flow` に実装。締めゲート＝5ステップのステッパー（FR-33）＋本日のパー・廃棄記録テーブル（FR-08・繰越/廃棄→FR-09/42へ環流）＋申し送りノート（FR-23・翌日サービス設定へ自動表示）＋日次サマリー。**S優先の穴2件＋C1件を1枚で一括充足**。朝（onboarding/service-setup）↔夜（close-flow）の運用ループが画面上で閉じた。

---

## 3. 重複FRの棚卸し（ID重複ゼロ・見かけの重複の整理）

**ID重複（同番号の二重定義）は無し**。FR-01〜58は連番で全て一意に存在。以下は「機能が似て見える」ものの実体整理。

### 3.1 意図した機構共有（重複ではない＝1エンジン多トリガ）
| 共有機構 | 関与FR | 関係 |
|---|---|---|
| **追い仕込み自動生成** | FR-19 / FR-34 / FR-55 | 同一エンジンの3トリガ：FR-19=営業中パー閾値割れ／FR-34=予約**増**の差分（営業前）／FR-55=予約**減**の差分（対称版）。要件本文に「FR-19と同機構」と明記済み |
| **WasteLog（実績）** | FR-08 → FR-09 / FR-42 / FR-46 | FR-08=記録（源泉）。FR-09(自己補正)・FR-42(繰越差引)が消費。FR-46=ラベルモード時の**FR-08自動入力経路**（QR）。→「手入力(FR-08) vs QR(FR-46)」は同一テーブルへの2経路 |
| **席別アレルギー/VIP** | 供給:FR-13/FR-34/FR-35 → 消費:FR-26/FR-47/FR-57/FR-58 | 供給源は予約ハブ正規化（TableCheck CRM・Direct・手入力）。消費先は出力違い：FR-26=キッチンチップ／FR-47=物理ラベル／FR-57=特別仕込みタスク／FR-58=事前確認メッセージ。**単一ソース→多出力**で重複ではない |

> 留意：上記は重複ではないが「**単一ソースの一元化**」が崩れると二重管理になる。実装時、席別アレルギー/VIPは必ず予約ハブ(FR-34)正規化を唯一の入口にすること（FR-26/47は供給源にTableCheck CRMを追記済み・整合OK）。

### 3.2 文書上の二重掲載（意図的）
- **FR-16** は §4 本表と §4.6 HACCPモードに二重掲載。§4.6側に「（§4の既出）」と注記済み＝意図的な再掲。ID重複ではない。

### 3.3 画面の世代重複（旧世代→新世代に置換済み・探求記録として保持）
| 旧（初期/探求） | 新（確定/正） | 備考 |
|---|---|---|
| redesign-A-bigcard / B-kanban / C-focus（2色・初期3案） | redesign2-1-ink / 2-passsheet / 2-3-oneaccent（確定3テーマ） | 探求記録。索引で「初期世代」と明示済み |
| p1-wireframe-settings（初期・統合設定 FR-14/15/10） | settings-home＋5サブ（staff-sections/service-periods/prep-defaults/billing-data/devices） | **旧版**。索引で「置換済み」注記を推奨（下記4） |
| p0-wireframe-service-setup（FR-02） | reservation-hub（FR-34が昇格・統合） | FR-34が「本日のサービス設定を昇格統合」と定義。service-setupは初期版 |
| v0.2ティール世代（onboarding/todaytask/template-editor/dashboard/haccp-checklist） | （確定テーマ未適用） | 内容は有効だが配色が旧い。再描画は任意 |

---

## 4. ドキュメント整合の小修正リスト（✅ 反映済み）

| # | 箇所 | 対応 | 状態 |
|---|---|---|---|
| a | design/README, 要件§12, gallery | p1-wireframe-settings に「初期版・設定ホーム(FR-52)＋5サブへ分割置換」注記 | ✅ |
| b | design/README, 要件§12, gallery | p0-wireframe-service-setup に「初期版・予約ハブ(FR-34)へ統合」注記 | ✅ |
| c | 要件§12 haccp-checklist | FR-16/51 → **FR-16** に統一（温度記録FR-51は haccp-settings/modes-settings 側）| ✅ |

> 画面・要件の**内容**は整合済み。世代ラベルを索引3箇所（README／§12／gallery）に付与し、旧世代画面の位置づけを明示した。

---

## 5. 推奨アクション（進捗）

1. ✅ **完了**：「閉店・締めフロー」ワイヤー新規1枚（`p2-wireframe-close-flow`／FR-33/23/08 を一括充足）。
2. ✅ **完了**：索引に世代ラベル注記（上記4-a/b/c）。
3. （残）P2.5/P3着手時に FR-30/29/18/12/44 を各画面の付随UI（モーダル/タブ/設定枠）として後付け。**新規の独立画面は不要**寄り。

> 結論：**v1.3 の要件×画面は整合**（53/58が専用ワイヤー、残り5件は全て優先度C＋後段/将来）。S優先の未充足はゼロになった。
