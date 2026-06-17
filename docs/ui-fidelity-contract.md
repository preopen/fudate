# UI 正本固定 契約（ワイヤーフレームからズレない実装の厳守ルール）

| 項目 | 内容 |
|---|---|
| 版 | v1.0 / 2026-06-17 |
| 正本（Source of Truth） | **`design/` の Liquid Glass ワイヤー（画面）＋ 6本の縦ぎりスライス（動線）**。実装はこれを**再現**する。コードがワイヤーに**先行・逸脱しない** |
| 背景 | 「ワイヤーと実装が時間とともにズレていく」事象を**構造的に防ぐ**ための契約。全UI PRはこの受入を満たすまでマージ不可 |
| 対象 | `apps/ios` の全画面実装（Codex／実装担当） |

---

## 0. 実装担当への厳守命令（コピペでそのまま渡す）
```
【厳守命令：UIは正本ワイヤーから一切ズレないこと】
PrepFlow の UI 実装は、design/ の Liquid Glass ワイヤー（画面）と flow-vertical-slice*／flow-overview-map（動線）を「唯一の正本」とする。
docs/ui-fidelity-contract.md を必ず読み、全画面PRでその受入を満たせ。

絶対規則：
1. 画面を実装する前に、対応する正本ワイヤー（§2の表）を開き、レイアウト構造・要素・配置・余白・順序をそのまま再現する。独自のUIパターン／画面構成／ナビゲーションを発明しない。
2. Liquid Glass は機能層のみ（上部バー／今これ・皿ごと・担当のセグメント切替／T−カウントダウン島／下部アクション／シート）に .glassEffect / GlassEffectContainer で適用。タスクカード・数値・テーブル・アラートは不透明・高コントラスト（A-12）。
3. 朱 #c2410c は「時間 / NOW / 遅延 / 期限・緊急」のみ。進捗バー・選択状態・装飾・通常アイコンに朱を使わない（→ INK）。違反は CI で落とす。
4. 色・フォント・角丸・間隔・モーションは DesignTokens 経由のみ。Color(red:…)／#hex／フォント名／マジック数値のハードコード禁止（grep/lint で検出）。本文フォントは Satoshi。
5. ボードのナビは正本どおり「上部バー＋セグメント切替（今これ/皿ごと/担当）」。サイドバーで3ビューを代替しない（トップレベル画面遷移にスプリットを使う場合も、ボード内の構造は正本を守る）。
6. 各画面 PR に「実機/シミュ スクショ ↔ 正本ワイヤーPNG」の横並び比較を必ず添付し、§3 チェックリスト全項目を満たす。未達はマージ不可。主要画面は swift-snapshot-testing で固定し回帰検知する。
7. UI を変えたくなったら、まず design/ のワイヤーを更新してレビューを通し、その後に実装を追従させる（ワイヤーが先・実装が後＝コードがワイヤーに先行しない）。

最初の是正（現シミュの逸脱）：
① 皿ごと進捗バーの朱 → INK　② 上部バー/カウントダウン/切替へ Liquid Glass を適用　③ サイドバーでの3ビュー → セグメント切替　④ Satoshi 適用　⑤ 「今これ」=焦点＋逆算レールの2列など正本レイアウトを再現。
```

---

## 1. 原則
1. **ワイヤーが正本・実装は追従**。実装の都合で見た目を変えない。変えたい時は §4 の変更管理に従う。
2. **再現の対象**＝レイアウト構造／要素の有無と順序／余白・サイズ感／色の意味づけ／モーションの役割。1px 完全一致は求めないが、**構造と規律は完全一致**。
3. **新規UIパターンの発明を禁止**。必要なら先にワイヤーを起こす。

## 2. 画面 ↔ 正本ワイヤー 対応表
| 画面（apps/ios） | 正本ワイヤー（design/） | Ph |
|---|---|---|
| オンボーディング | `p0-wireframe-onboarding-liquidglass.png/.html` | P0 |
| 活性化サマリー | `p0-wireframe-activation-liquidglass` | P0 |
| 本日のサービス設定 | `p0-wireframe-service-setup-liquidglass` | P0 |
| 仕込みボード「今これ」 | `p0-wireframe-board-liquidglass` | P0 |
| 　└ 着地予測 | `p1-wireframe-board-eta-liquidglass` | P1（ボード内） |
| 　└ 皿ごとビュー | `p1-wireframe-view-dishes-liquidglass` | P0/P1 |
| 　└ 担当ビュー | `p1-wireframe-view-staff-liquidglass` | P1 |
| シミュレーション並走 | `p0-wireframe-simulation-liquidglass` | P0 |
| 設定ホーム | `p1-wireframe-settings-home-liquidglass` | P0(最小)/P1 |
| 締め→翌日 | `p2-wireframe-close-flow-liquidglass` / `…close-nextday…` | P2 |
| 予約ハブ | `p2-wireframe-reservation-hub-liquidglass` | P2 |
| 多店舗 / 信頼性 | `p1-wireframe-multistore-liquidglass` / `…reliability…` | P3 / P0-1 |
| 動線（遷移の正本） | `flow-vertical-slice` / `…-reservations` / `…-modes` / `flow-overview-map` | 全体 |

> 各 `.html` はブラウザで開ける。`.png` を PR の比較画像に使う。

## 3. マージ前チェックリスト（全UI PR・全項目必須）
- [ ] 対応する正本ワイヤーPNGと**実機/シミュのスクショを横並び**で PR に添付した。
- [ ] レイアウト構造（列数・領域・順序）が正本と一致。サイドバーで3ビューを代替していない。
- [ ] **Liquid Glass は機能層のみ**（上部バー/セグメント切替/カウントダウン島/下部操作/シート）。コンテンツは不透明・高コントラスト。
- [ ] **朱は時間/NOW/遅延/期限・緊急のみ**。進捗・選択・装飾に朱が無い。
- [ ] 色/フォント/角丸/間隔/モーションは **DesignTokens 経由**。ハードコード無し。Satoshi 適用。
- [ ] 大タッチ領域・5秒アンドゥ・即時保存＋トースト（破壊的変更のみ確認）。
- [ ] `Reduce Transparency / Increase Contrast` で可読性が保たれる（グラスのフォールバック）。
- [ ] 主要画面の **snapshot テスト**を追加/更新し green。

## 4. 変更管理（ドリフト防止の要）
- UI を変える必要が出たら、**順序は必ず「① design/ のワイヤー更新 → ② レビュー/合意 → ③ 実装追従」**。コードを先に変えない。
- ワイヤー更新は本リポジトリの `design/*.html` を編集し PNG を再レンダリング（`design/render-*.mjs`）して同一PR/先行PRに含める。
- 要件の意味が変わる場合は `docs/requirements.md`（FR）も併せて更新。

## 5. CI による機械的ガード（推奨実装）
1. **色ハードコード検出**：`apps/ios/Sources` に対し `Color(red:` / `#[0-9A-Fa-f]{6}` / `\.font(\.system` を grep し、検出で fail（DesignTokens 経由を強制）。許可リストは DesignTokens 内のみ。
2. **朱の用途検出（半自動）**：朱トークン `Tokens.time` の使用箇所に `// time-use:` 注釈を必須化し、注釈無き使用を fail。
3. **snapshot 回帰**：`pointfreeco/swift-snapshot-testing` で各画面の参照画像を固定。差分で fail（参照は正本ワイヤーに寄せて承認）。
4. **設計リンク存在チェック**：各画面 View ファイル先頭に `// 正本: design/<file>` コメントを必須化し、存在しないファイルを指していたら fail。

## 6. 現時点の是正項目（2026-06-17 シミュから）
| # | 逸脱 | 是正 | 正本 |
|---|---|---|---|
| 1 | 皿ごと進捗バーが朱 | **INK（黒）**へ。朱は時間のみ | view-dishes/staff の `.dbar/.loadbar` は ink |
| 2 | Liquid Glass 未適用（フラット） | 上部バー/カウントダウン/切替/下部操作へ `.glassEffect` | board-liquidglass |
| 3 | サイドバーで3ビュー切替 | ボード内「今これ/皿ごと/担当」**セグメント切替**＋上部バー | board-liquidglass |
| 4 | システムフォント | **Satoshi**（DesignTokens） | 全画面 |
| 5 | 単一リスト | 「今これ」は**焦点＋逆算レールの2列**等、正本レイアウト | board-liquidglass / board-eta |
| 6 | T−カウントダウンの島が無い | 朱tintの**ガラス島**（SERVICE 18:00 / T−） | 全ボード |

> Engine の数値（200ml・15:00・18:12 等）は既に正＝そのまま。**今回の是正は“見た目の正本化”のみ**でロジックは触らない。

## 7. DoD への追加（CODEX_HANDOFF §0 を補強）
- 「P0 縦ぎりB が通る」に加え、**P0 全画面が §3 チェックリストを満たし、正本ワイヤーと構造一致**していること（スクショ比較を PR 履歴に残す）をステージング条件に含める。
