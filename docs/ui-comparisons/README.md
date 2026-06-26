# UI Comparisons

目的: UI PR で「正本ワイヤー」「実装スクショ」「High Fidelity流れ順」の対応を残し、ASCIIでは合っているが見た目が違う状態を防ぐ。

## PRに残すもの

| 項目 | 保存/記載先 |
| --- | --- |
| 正本ワイヤーPNG | `design/<wire>.png` |
| 実装スクショ | snapshot出力または実機/シミュのスクショ |
| 横並び比較 | `docs/ui-comparisons/<test>.<wire>.comparison.png` |
| High Fidelity対応 | PR本文の `design/high-fidelity-user-flow.png` 該当画面番号/範囲 |
| ASCII対応 | `docs/ascii-user-flow-screens.md` の画面番号 |

## 主要比較ファイル

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

## 更新ルール

1. UI構造を変える時は、先に `design/` のワイヤーを更新する。
2. 実装後に snapshot を更新する。
3. 正本ワイヤーPNGと実装スクショを横並びにして `docs/ui-comparisons/` へ保存する。
4. PR本文に `docs/ascii-user-flow-screens.md` の画面番号と `design/high-fidelity-user-flow.png` の該当箇所を記載する。
5. `docs/flow-qa.md` のユーザー流れで「親画面から開く -> 操作する -> 戻る」を確認する。
