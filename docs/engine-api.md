# Engine API 契約（`packages/Engine` 純Swift）

| 項目 | 内容 |
|---|---|
| 版 | v1.0 / 2026-06-12 |
| 位置づけ | `architecture.md §3` の正式版。**この契約と `golden/*.json` を満たすよう Codex が実装**する |
| 鉄則 | 純関数・I/Oなし・値型・Swift 6 strict concurrency。`Date()`／乱数／ネットワーク／DB を関数内で呼ばない（すべて引数で受ける）。`Foundation` の `Date`/`Calendar` 依存も避け、時刻は分・文字列で扱う |

> 下の型・シグネチャは**確定仕様**。名称は変えてよいが、入出力の意味と golden の数値は不変。`golden/` を読むテストを先に通し（TDD）、その後で各UI層から呼ぶ。

## 0. 共通型
```swift
public enum ScaleMode: String, Codable, Sendable { case perCover, perPortion, fixedBatch }
public enum TaskStatus: String, Codable, Sendable { case notStarted, inProgress, done }

public struct PrepTask: Codable, Sendable, Identifiable {
    public let id: String
    public var scaleMode: ScaleMode
    public var coeffPerCover: Double?       // perCover
    public var coeffPerPortion: Double?     // perPortion（1人前あたり）
    public var yield: Double                // 歩留り(0<y<=1)。既定1.0
    public var roundStep: Double?           // perCover の丸め単位（例 10）。nil=丸めなし
    public var coversPerBatch: Int?         // fixedBatch
    public var batchSize: Double?           // fixedBatch（1バッチの量）
    public var unit: String                 // "ml"/"升"/"貫"/"L"/"食" 等。Engineは変換しない
    public var durationMin: Int
    public var leadMinBeforeOpen: Int       // T0 から何分前に「着手」するか
    public var shelfLifeDays: Int?
    public var section: String?
}

public struct Quantity: Codable, Sendable, Equatable {
    public var raw: Double      // 丸め前
    public var total: Double    // 丸め/バッチ後（提供・生産で使う値）
    public var batches: Int?    // fixedBatch のとき
    public var unit: String
}
```

## 1. 純関数（必須・golden 対応）

### `calcQty` — FR-03/37 ／ `golden/calc_qty.json`
```swift
public func calcQty(_ task: PrepTask, covers: Int) -> Quantity
```
- perCover：`raw = Double(covers) * coeffPerCover! / yield`；`total = roundStep.map { roundNearest(raw, $0) } ?? raw`
- perPortion：`total = Double(covers) * coeffPerPortion!`（raw=total・丸めなし）
- fixedBatch：`batches = ceilBatch(covers, coversPerBatch!)`；`total = Double(batches) * batchSize!`
- ヘルパ：`roundNearest(_ x: Double, _ step: Double) -> Double`（最近接の step 倍・0.5切上げ）、`ceilBatch(_ c: Int, _ per: Int) -> Int = Int(ceil(Double(c)/Double(per)))`

### `aggregateSubrecipes` — FR-38 ／ `golden/aggregate_subrecipes.json`
```swift
public func aggregateSubrecipes(_ subrecipe: PrepTask, references: [(course: String, covers: Int)]) -> Quantity
```
- 参照先の covers を合算 → `calcQty(subrecipe, covers: 合算)`。`sources` に "course:covers" を残す（戻り値を拡張するか別構造体で）。

### `diffPlan` — FR-19/34/55 ／ `golden/diff_plan.json`
```swift
public enum PlanChange: Sendable {
    case reservationAdded(deltaCovers: Int, course: String)
    case reservationCancelled(deltaCovers: Int, course: String)   // deltaCovers は負
    case parDepleted(remainingQty: Double, thresholdPct: Double)
}
public struct PlanDiff: Sendable, Equatable {
    public var added: [AddItem]      // 追い仕込み
    public var reduced: [ReduceItem] // 減算・繰越/廃棄候補
}
public func diffPlan(task: PrepTask, currentCovers: Int?, madeTotal: Double?, change: PlanChange) -> PlanDiff
```
- 減：`rawDelta = Double(deltaCovers) * coeffPerCover!/yield`（負）。`newCovers = currentCovers + deltaCovers`。`newTotal = calcQty(task, covers: newCovers).total`。task.status == .done なら `carryoverCandidate = true`。
- 増：`added += [{task.id, qty: deltaCovers*coeff/yield, reason: .reservationIncrease}]`。
- パー閾値割れ：`remainingQty/madeTotal < thresholdPct` なら `added += [{task.id, reason: .parDepleted, belowThreshold: true}]`。

### `schedule` — FR-06/40/41 ／ `golden/schedule.json`
```swift
public struct Scheduled: Sendable, Equatable { public var taskId: String; public var prepDayOffset: Int; public var start: String; public var finish: String; public var skipped: [String] }
public func schedule(task: PrepTask, serviceDate: String, t0: String, closedDates: Set<String>) -> Scheduled
```
- `startMinutes = t0Min - leadMinBeforeOpen`；負になった分だけ `prepDayOffset` を進め（−1日=−1440分）日内 [0,1440) に正規化。
- `prepDate = serviceDate + prepDayOffset`。`prepDate ∈ closedDates` の間は1日前へ送り `skipped` に積む。
- `start = HHmm(startMinutes)`；`finish = HHmm(startMinutes + durationMin)`。

### `rollup` — FR-05 ／ `golden/rollup.json`
```swift
public func rollup(_ node: TaskNode) -> TaskNode   // 子の状態から親 status を再計算（全done→done／一部着手→inProgress／全未→notStarted）
```

### `etaProjection` — FR-59 ／ `golden/eta_projection.json`
```swift
public struct ETA: Sendable, Equatable { public var landing: String; public var delayMin: Int; public var timeToOpenMin: Int; public var shortfallMin: Int; public var status: ETAStatus }
public enum ETAStatus: String, Sendable { case onTrack, tight, atRisk }
public func etaProjection(now: String, t0: String, remainingDurationsMin: [Int], bufferMin: Int = 0) -> ETA
```
- `landingMin = nowMin + remaining.sum()`；`delayMin = landingMin - t0Min`；`timeToOpenMin = t0Min - nowMin`；`shortfall = max(0, delayMin)`。status：`delay<=0` onTrack／`delay<=buffer` tight／else atRisk。P0は直列（並行最適化＝FR-60は未採用）。

### `selfCorrect` — FR-09 ／ `golden/self_correct.json`
```swift
public struct WasteRecord: Codable, Sendable { public var serviceDate: String; public var covers: Int; public var made: Double; public var leftover: Double; public var exclude: Bool }
public struct CoeffSuggestion: Sendable, Equatable { public var taskId: String; public var current: Double; public var suggested: Double; public var samplesUsed: Int }
public func selfCorrect(taskId: String, currentCoeffPerCover: Double, history: [WasteRecord], lookback: Int) -> CoeffSuggestion
```
- `exclude==false` の直近 `lookback` 件で `usedPerCover = (made-leftover)/covers` の平均 → 小数1桁丸め＝`suggested`。

### `applyCarryover` — FR-42 ／ `golden/apply_carryover.json`
```swift
public func applyCarryover(plan: [(task: String, base: Double, unit: String)], leftovers: [(task: String, qty: Double, expired: Bool)]) -> [(task: String, adjusted: Double, unit: String)]
```
- `expired==false` の繰越のみ `adjusted = max(0, base - qty)`。

## 2. 生成器（P0で必要・goldenは任意、ユニットテストで担保）
```swift
public func generateInstances(sources: GenerationSources, day: ServiceDayContext) -> [TaskInstance]  // FR-17/31/32/40
```
- コース由来＋定期＋業務フローの3源から当日 TaskInstance を生成（A-2：日次オープン時に実体化して保存）。

## 3. テスト方針（WS1 受入）
- `golden/*.json` 全 case が green。浮動小数 `1e-6`、時刻は文字列一致。
- 追加で：丸め境界（195/205, 0.5tie）、空配列、yield=0 ガード（不正入力は `precondition` か `Result`）。
- `Engine` ターゲットは **`Foundation` 最小依存・プラットフォーム非依存**（iOS/macOS両方でテストが回る＝CIが速い）。
