import Engine
import PrepFlowData
import SwiftUI

@MainActor
final class BoardStore: ObservableObject {
    @Published private(set) var completed: Set<String>
    @Published private(set) var catalog: CatalogTemplate
    @Published private(set) var service: ServiceDaySettings
    @Published private(set) var simulation: SimulationSummary

    private let database: PrepFlowDatabase?
    private let tenantID: String
    private let restaurantID = "restaurant-hayashi"
    private let sectionOwnerID = "section-oyakata"
    private let serviceCoverID = "cover-omakase"
    private var eventSequence = 0
    private var catalogSequence = 0
    private var wasteSequence = 0

    init(
        completed: Set<String> = ["sake", "shari", "neta"],
        catalog: CatalogTemplate = .seed,
        service: ServiceDaySettings = .seed,
        simulation: SimulationSummary = .seed,
        database: PrepFlowDatabase? = AppDatabaseFactory.makeDatabase(),
        tenantID: String = "tenant-local"
    ) {
        self.completed = completed
        self.catalog = catalog
        self.service = service
        self.simulation = simulation
        self.database = database
        self.tenantID = tenantID
        syncNikiriRollup()
        persistCatalogSeed()
        persistServiceSeed()
    }

    var nikiriRollupStatus: TaskStatus {
        rollup(TaskNode(id: "nikiri", children: focusTaskNodes)).status ?? .notStarted
    }

    var eta: ETA {
        etaProjection(now: "17:25", t0: "18:00", remainingDurationsMin: [15, 15, 17])
    }

    var selectedCatalogTask: CatalogPrepTask {
        task(id: catalog.selectedTaskID) ?? CatalogTemplate.seed.dishes[0].components[1].tasks[0]
    }

    var nikiriTask: PrepTask {
        (task(id: "task-nikiri") ?? selectedCatalogTask).engineTask
    }

    var nikiriQuantity: Quantity {
        calcQty(nikiriTask, covers: service.omakaseCovers)
    }

    var nikiriSchedule: Scheduled {
        schedule(task: nikiriTask, serviceDate: service.date, t0: service.openTime, closedDates: [])
    }

    var covers: Int {
        service.totalCovers
    }

    var serviceTime: String {
        service.openTime
    }

    func selectTask(_ id: String) {
        guard task(id: id) != nil else {
            return
        }
        catalog.selectedTaskID = id
    }

    func addDish() {
        catalogSequence += 1
        let dish = CatalogDish(id: "dish-custom-\(catalogSequence)", name: "新しい料理 \(catalogSequence)", components: [], sort: catalog.dishes.count)
        catalog.dishes.append(dish)
        persistDish(dish)
    }

    func addComponent() {
        guard let dishIndex = selectedDishIndex else {
            return
        }
        catalogSequence += 1
        let component = CatalogComponent(id: "component-custom-\(catalogSequence)", name: "構成要素 \(catalogSequence)", tasks: [], sort: catalog.dishes[dishIndex].components.count)
        catalog.dishes[dishIndex].components.append(component)
        persistComponent(component, dishID: catalog.dishes[dishIndex].id)
    }

    func addTask() {
        guard let selectedPath else {
            return
        }
        catalogSequence += 1
        let task = CatalogPrepTask(
            id: "task-custom-\(catalogSequence)",
            name: "サブ仕込み \(catalogSequence)",
            coeffPerCover: 1,
            unit: "個",
            sectionName: "親方",
            sort: catalog.dishes[selectedPath.dish].components[selectedPath.component].tasks.count
        )
        catalog.dishes[selectedPath.dish].components[selectedPath.component].tasks.append(task)
        catalog.selectedTaskID = task.id
        persistTask(task, componentID: catalog.dishes[selectedPath.dish].components[selectedPath.component].id)
    }

    func updateSelectedTask(
        name: String? = nil,
        coeffPerCover: Double? = nil,
        yieldPercent: Double? = nil,
        durationMin: Int? = nil,
        leadMinBeforeOpen: Int? = nil,
        instruction: String? = nil
    ) {
        guard let selectedPath else {
            return
        }

        var task = catalog.dishes[selectedPath.dish].components[selectedPath.component].tasks[selectedPath.task]
        task.name = name ?? task.name
        task.coeffPerCover = coeffPerCover ?? task.coeffPerCover
        task.yieldPercent = yieldPercent ?? task.yieldPercent
        task.durationMin = durationMin ?? task.durationMin
        task.leadMinBeforeOpen = leadMinBeforeOpen ?? task.leadMinBeforeOpen
        task.instruction = instruction ?? task.instruction
        catalog.dishes[selectedPath.dish].components[selectedPath.component].tasks[selectedPath.task] = task
        persistTaskUpdate(task)
    }

    func updateOmakaseCovers(_ covers: Int) {
        service.omakaseCovers = max(0, covers)
        persistServiceCover()
    }

    func updateOtherCovers(_ covers: Int) {
        service.otherCovers = max(0, covers)
        persistServiceCover()
    }

    func updateOpenTime(_ openTime: String) {
        service.openTime = openTime
        persistServiceDayUpdate()
    }

    func recordNikiriWaste(madeQty: Double = 240, leftoverQty: Double = 40) {
        wasteSequence += 1
        try? database?.create(.wasteLog, values: [
            "id": "waste-nikiri-\(wasteSequence)",
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "prep_task_id": "task-nikiri",
            "covers": String(service.omakaseCovers),
            "planned_qty": numberString(nikiriQuantity.total),
            "made_qty": numberString(madeQty),
            "leftover_qty": numberString(leftoverQty),
            "waste_reason": "overmade",
            "carryover_to_next": "1",
            "unit": "ml",
            "recorded_by": "local-ipad",
        ])
    }

    func applySimulationCoefficients() {
        selectTask("task-nikiri")
        updateSelectedTask(coeffPerCover: 12, yieldPercent: selectedCatalogTask.yieldPercent)
    }

    func toggle(_ id: String) {
        if id == "nikiri" {
            markAllNowDone()
            return
        }

        if completed.contains(id) {
            completed.remove(id)
        } else {
            completed.insert(id)
        }
        syncNikiriRollup()
        persistOfflineEvent(taskID: id)
    }

    func markAllNowDone() {
        completed.formUnion(["sake", "tare", "rest"])
        syncNikiriRollup()
        persistOfflineEvent(taskID: "nikiri")
    }

    private var focusTaskNodes: [TaskNode] {
        ["sake", "tare", "rest"].map { id in
            TaskNode(id: id, status: completed.contains(id) ? .done : .notStarted)
        }
    }

    private var selectedDishIndex: Int? {
        selectedPath?.dish ?? (catalog.dishes.isEmpty ? nil : 0)
    }

    private var selectedPath: (dish: Int, component: Int, task: Int)? {
        for dishIndex in catalog.dishes.indices {
            for componentIndex in catalog.dishes[dishIndex].components.indices {
                let tasks = catalog.dishes[dishIndex].components[componentIndex].tasks
                if let taskIndex = tasks.firstIndex(where: { $0.id == catalog.selectedTaskID }) {
                    return (dishIndex, componentIndex, taskIndex)
                }
            }
        }
        return nil
    }

    private func task(id: String) -> CatalogPrepTask? {
        for dish in catalog.dishes {
            for component in dish.components {
                if let task = component.tasks.first(where: { $0.id == id }) {
                    return task
                }
            }
        }
        return nil
    }

    private func syncNikiriRollup() {
        if nikiriRollupStatus == .done {
            completed.insert("nikiri")
        } else {
            completed.remove("nikiri")
        }
    }

    private func persistOfflineEvent(taskID: String) {
        eventSequence += 1
        try? database?.create(.eventLog, values: [
            "id": "offline-checkoff-\(eventSequence)",
            "tenant_id": tenantID,
            "type": "task.completed",
            "payload": "{\"task_id\":\"\(taskID)\",\"status\":\"\(nikiriRollupStatus.rawValue)\"}",
            "occurred_at": "2026-06-17T09:00:00Z",
            "actor": "local-ipad",
        ])
    }

    private func persistServiceSeed() {
        try? database?.create(.serviceDay, values: [
            "id": service.id,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "date": service.date,
            "service_period": "dinner",
            "open_time": service.openTime,
            "note": "P0 manual covers",
        ])
        persistServiceCover()
        for reservation in service.reservations {
            persistReservation(reservation)
        }
    }

    private func persistServiceDayUpdate() {
        try? database?.update(.serviceDay, id: service.id, tenantID: tenantID, values: [
            "open_time": service.openTime,
        ])
    }

    private func persistServiceCover() {
        try? database?.create(.serviceCover, values: [
            "id": serviceCoverID,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "course_template_id": catalog.id,
            "covers": String(service.omakaseCovers),
        ])
        try? database?.update(.serviceCover, id: serviceCoverID, tenantID: tenantID, values: [
            "covers": String(service.omakaseCovers),
        ])
    }

    private func persistReservation(_ reservation: ManualReservation) {
        try? database?.create(.reservation, values: [
            "id": reservation.id,
            "tenant_id": tenantID,
            "service_day_id": service.id,
            "source": "manual",
            "visit_time": reservation.visitTime,
            "covers": String(reservation.covers),
            "course_template_id": catalog.id,
            "course_text": catalog.courseName,
            "party_name": reservation.partyName,
            "structured": "1",
        ])
    }

    private func persistCatalogSeed() {
        try? database?.create(.restaurant, values: [
            "id": restaurantID,
            "tenant_id": tenantID,
            "name": "鮨 はやし",
            "seats": "14",
        ])
        try? database?.create(.section, values: [
            "id": sectionOwnerID,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "name": "親方",
            "sort": "0",
        ])
        try? database?.create(.courseTemplate, values: [
            "id": catalog.id,
            "tenant_id": tenantID,
            "restaurant_id": restaurantID,
            "name": catalog.courseName,
        ])
        for dish in catalog.dishes {
            persistDish(dish)
            for component in dish.components {
                persistComponent(component, dishID: dish.id)
                for task in component.tasks {
                    persistTask(task, componentID: component.id)
                }
            }
        }
    }

    private func persistDish(_ dish: CatalogDish) {
        try? database?.create(.dish, values: [
            "id": dish.id,
            "tenant_id": tenantID,
            "course_template_id": catalog.id,
            "name": dish.name,
            "sort": String(dish.sort),
        ])
    }

    private func persistComponent(_ component: CatalogComponent, dishID: String) {
        try? database?.create(.component, values: [
            "id": component.id,
            "tenant_id": tenantID,
            "dish_id": dishID,
            "name": component.name,
            "sort": String(component.sort),
        ])
    }

    private func persistTask(_ task: CatalogPrepTask, componentID: String) {
        try? database?.create(.prepTask, values: taskValues(task, componentID: componentID))
    }

    private func persistTaskUpdate(_ task: CatalogPrepTask) {
        try? database?.update(.prepTask, id: task.id, tenantID: tenantID, values: [
            "name": task.name,
            "coeff_per_cover": numberString(task.coeffPerCover),
            "yield": numberString(task.yieldPercent / 100),
            "duration_min": String(task.durationMin),
            "lead_min_before_open": String(task.leadMinBeforeOpen),
        ])
    }

    private func taskValues(_ task: CatalogPrepTask, componentID: String) -> [String: String?] {
        [
            "id": task.id,
            "tenant_id": tenantID,
            "component_id": componentID,
            "name": task.name,
            "scale_mode": "per_cover",
            "coeff_per_cover": numberString(task.coeffPerCover),
            "yield": numberString(task.yieldPercent / 100),
            "round_step": numberString(task.roundStep),
            "unit": task.unit,
            "duration_min": String(task.durationMin),
            "lead_min_before_open": String(task.leadMinBeforeOpen),
            "section_id": sectionOwnerID,
            "sort": String(task.sort),
        ]
    }

    private func numberString(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 3)))
    }
}
