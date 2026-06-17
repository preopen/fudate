import Foundation

struct SimulationSummary: Equatable {
    var reductionPercent: Double
    var lossSavingYen: Int
    var stockoutRisks: Int
    var hitRatePercent: Int
    var items: [SimulationItem]

    var reductionText: String {
        "−\(abs(reductionPercent).formatted(.number.precision(.fractionLength(1))))%"
    }

    var lossSavingText: String {
        "¥\(lossSavingYen.formatted())"
    }

    static let seed = SimulationSummary(
        reductionPercent: -12.4,
        lossSavingYen: 38000,
        stockoutRisks: 2,
        hitRatePercent: 88,
        items: [
            SimulationItem(id: "sim-nikiri", name: "煮切り", note: "共有・per_cover", actual: 240, recommended: 200, unit: "ml", deltaLabel: "−40ml", outcome: .save),
            SimulationItem(id: "sim-shari", name: "シャリ", note: "fixed_batch", actual: 2.2, recommended: 2.0, unit: "升", deltaLabel: "−0.2升", outcome: .save),
            SimulationItem(id: "sim-dashi", name: "出汁", note: "fixed_batch", actual: 5.0, recommended: 5.0, unit: "L", deltaLabel: "差なし", outcome: .neutral),
            SimulationItem(id: "sim-yurine", name: "百合根ピュレ", note: "per_cover", actual: 12, recommended: 14, unit: "客", deltaLabel: "＋2客", outcome: .risk),
            SimulationItem(id: "sim-tsume", name: "ツメ", note: "煮切り由来", actual: 110, recommended: 80, unit: "ml", deltaLabel: "−30ml", outcome: .save),
        ]
    )
}

struct SimulationItem: Identifiable, Equatable {
    enum Outcome: Equatable {
        case save
        case risk
        case neutral
    }

    var id: String
    var name: String
    var note: String
    var actual: Double
    var recommended: Double
    var unit: String
    var deltaLabel: String
    var outcome: Outcome

    var actualRatio: Double {
        ratio(actual)
    }

    var recommendedRatio: Double {
        ratio(recommended)
    }

    private func ratio(_ value: Double) -> Double {
        let maximum = max(actual, recommended, 1)
        return value / maximum
    }
}
