# golden/ — Engine の決定論テストベクタ（数値仕様の単一ソース）

`packages/Engine`（純Swift）の関数は、ここの JSON を**唯一の正**として実装・検証する（TDD）。
ワイヤーフレームの数値は説明用で相互に厳密一致しないため、**矛盾したら本ディレクトリが優先**。
将来 Web/Android へ移植する際も同じベクタを使う（言語非依存）。

## 使い方（Codex）
1. `packages/Engine/Tests/EngineTests/` で各 JSON を読み、`cases[]` を回して `expect` と突き合わせる。
2. JSON は SwiftPM のリソースとして同梱（`Package.swift` の `.copy("golden")` か、テストターゲットの resources）。`Bundle.module` で読む。
3. 浮動小数の比較は `abs(a-b) <= 1e-6`。時刻は "HH:mm" 文字列で比較。

## ファイル ↔ 関数 ↔ FR
| ファイル | 関数 | FR |
|---|---|---|
| `calc_qty.json` | `calcQty` | FR-03/37 |
| `aggregate_subrecipes.json` | `aggregateSubrecipes` | FR-38 |
| `diff_plan.json` | `diffPlan` | FR-19/34/55 |
| `schedule.json` | `schedule` | FR-06/40/41 |
| `rollup.json` | `rollup` | FR-05 |
| `eta_projection.json` | `etaProjection` | FR-59 |
| `self_correct.json` | `selfCorrect` | FR-09 |
| `apply_carryover.json` | `applyCarryover` | FR-42 |

## 共通ルール（`docs/engine-api.md` が正式定義）
- 単位は各 task に付随（ml/升/貫/L/食 等）。Engineは単位変換しない（同一単位で計算）。
- `round_nearest(x, step)`：最近接の step 倍へ。0.5 ちょうどは切上げ。
- `ceil_batch(covers, covers_per_batch)`：`ceil(covers / covers_per_batch)`。
- per_cover 合計：`round_nearest(covers * coeff_per_cover / yield, round_step)`。
- diff の `raw_delta`：`delta_covers * coeff_per_cover / yield`（丸めなし）。`new_total` は `calcQty(new_covers)` で再計算。
- `schedule`：`start = T0 - lead_min_before_open`、`finish = start + duration_min`。日跨ぎは `prep_day_offset` を負に、定休日はスキップ。
- 純関数：`Date()`・乱数・I/O を関数内で使わない（すべて引数で受ける）。

## 代表シナリオ（鮨 はやし・6/11 夜 14名）
煮切り(per_cover 14.0/yield1.0/step10)→200ml ／ シャリ(fixed_batch 7名/1.0升)→2.0升 ／ ネタ(per_portion 1貫)→14貫 ／ だし(fixed_batch 7名/2.5L)→5.0L ／ 着手：煮切り15:00・ネタ13:30 ／ 卓3(6名)取消→−84ml ／ 着地予測：残47分・開店まで35分→18:12(+12分)。
