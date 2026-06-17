import Engine
import Foundation

struct CatalogTemplate: Equatable {
    var id: String
    var courseName: String
    var dishes: [CatalogDish]
    var selectedTaskID: String

    static let seed = CatalogTemplate(
        id: "course-omakase",
        courseName: "本日のおまかせ・握り",
        dishes: [
            CatalogDish(
                id: "dish-omakase",
                name: "おまかせ握り",
                components: [
                    CatalogComponent(
                        id: "component-shari",
                        name: "シャリ",
                        tasks: [
                            CatalogPrepTask(id: "task-shari", name: "米を炊く・赤酢で合わせる", coeffPerCover: 1, unit: "升", sectionName: "シャリ場", sort: 0),
                        ],
                        sort: 0
                    ),
                    CatalogComponent(
                        id: "component-nikiri",
                        name: "煮切り・ツメ",
                        tasks: [
                            CatalogPrepTask(
                                id: "task-nikiri",
                                name: "煮切り仕込み",
                                coeffPerCover: 14,
                                yieldPercent: 100,
                                roundStep: 10,
                                unit: "ml",
                                durationMin: 40,
                                leadMinBeforeOpen: 180,
                                sectionName: "親方",
                                instruction: "酒・みりんを煮切り、たまり・濃口を加えてひと煮立ち。塩度ととろみを確認し冷暗所へ。",
                                sort: 0
                            ),
                        ],
                        sort: 1
                    ),
                    CatalogComponent(
                        id: "component-neta",
                        name: "ネタの仕込み",
                        tasks: [
                            CatalogPrepTask(id: "task-neta", name: "白身の昆布締め・赤身の漬け", coeffPerCover: 1, unit: "貫", sectionName: "親方", sort: 0),
                        ],
                        sort: 2
                    ),
                ],
                sort: 0
            ),
        ],
        selectedTaskID: "task-nikiri"
    )
}

struct CatalogDish: Identifiable, Equatable {
    var id: String
    var name: String
    var components: [CatalogComponent]
    var sort: Int
}

struct CatalogComponent: Identifiable, Equatable {
    var id: String
    var name: String
    var tasks: [CatalogPrepTask]
    var sort: Int
}

struct CatalogPrepTask: Identifiable, Equatable {
    var id: String
    var name: String
    var scaleMode: ScaleMode = .perCover
    var coeffPerCover: Double
    var yieldPercent: Double = 100
    var roundStep: Double = 10
    var unit: String
    var durationMin: Int = 40
    var leadMinBeforeOpen: Int = 180
    var sectionName: String
    var instruction: String = ""
    var sort: Int

    var engineTask: PrepTask {
        PrepTask(
            id: id,
            scaleMode: scaleMode,
            coeffPerCover: coeffPerCover,
            yield: max(yieldPercent, 1) / 100,
            roundStep: roundStep,
            unit: unit,
            durationMin: durationMin,
            leadMinBeforeOpen: leadMinBeforeOpen
        )
    }
}
