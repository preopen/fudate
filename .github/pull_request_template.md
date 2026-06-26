## Summary

- 

## UI Fidelity

- [ ] 対応する正本ワイヤーを確認した: `design/<file>.png`
- [ ] 実装スクショと正本ワイヤーPNGの横並び比較を添付した: `docs/ui-comparisons/<file>.comparison.png`
- [ ] `design/high-fidelity-user-flow.png` の該当画面番号/範囲を確認した:
- [ ] ASCII流れ順との差分なし: `docs/ascii-user-flow-screens.md`
- [ ] Liquid Glass は機能層のみ、カード/数値/テーブル/アラートは不透明
- [ ] 朱は時間/NOW/遅延/期限/緊急のみ
- [ ] 色/フォント/角丸/間隔は DesignTokens 経由のみ

## Local Verification

- [ ] `swift test --package-path packages/Engine`
- [ ] `swift test --package-path packages/Data`
- [ ] `cd apps/ios && xcodegen generate`
- [ ] `xcodebuild build -project PrepFlow.xcodeproj -scheme PrepFlow -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5),OS=26.5'`
- [ ] `xcodebuild test -project PrepFlow.xcodeproj -scheme PrepFlow -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5),OS=26.5' -only-testing:PrepFlowSnapshotTests`
- [ ] `swiftlint --strict`
- [ ] `swiftformat --lint .`
- [ ] `rg -n 'Color\(red:|#[0-9A-Fa-f]{6}|\.font\(\.system' apps/ios/Sources` returns 0 matches

## Notes

- Missing secrets / local fallback:
- Simulator/device used:
