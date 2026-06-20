public struct TodayPrepStep: Sendable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var durationMin: Int
    public var isDone: Bool

    public init(id: String, title: String, durationMin: Int, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.durationMin = durationMin
        self.isDone = isDone
    }
}

public struct TodayPrepProgress: Sendable, Equatable {
    public var steps: [TodayPrepStep]
    public var completedCount: Int
    public var totalCount: Int
    public var nextStepID: String?
    public var nextStepTitle: String?
    public var remainingMinutes: Int
    public var eta: ETA

    public var isComplete: Bool {
        completedCount == totalCount
    }

    public init(
        steps: [TodayPrepStep],
        completedCount: Int,
        totalCount: Int,
        nextStepID: String?,
        nextStepTitle: String?,
        remainingMinutes: Int,
        eta: ETA
    ) {
        self.steps = steps
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.nextStepID = nextStepID
        self.nextStepTitle = nextStepTitle
        self.remainingMinutes = remainingMinutes
        self.eta = eta
    }
}

public struct TodayPrepUndo: Sendable, Equatable, Identifiable {
    public var id: String
    public var action: String
    public var previousCompletedIDs: [String]
    public var nextCompletedIDs: [String]
    public var message: String

    public init(id: String, action: String, previousCompletedIDs: [String], nextCompletedIDs: [String], message: String) {
        self.id = id
        self.action = action
        self.previousCompletedIDs = previousCompletedIDs
        self.nextCompletedIDs = nextCompletedIDs
        self.message = message
    }
}

public struct TodayPrepOperator: Sendable, Equatable, Identifiable {
    public var id: String
    public var displayName: String
    public var sectionName: String

    public init(id: String, displayName: String, sectionName: String) {
        self.id = id
        self.displayName = displayName
        self.sectionName = sectionName
    }
}

public struct TodayPrepOperatorWorkload: Sendable, Equatable, Identifiable {
    public var id: String
    public var operatorID: String
    public var displayName: String
    public var sectionName: String
    public var assignedCount: Int
    public var completedCount: Int
    public var remainingMinutes: Int
    public var nextStepID: String?
    public var nextStepTitle: String?
    public var activeStepID: String?
    public var activeStepTitle: String?
    public var statusText: String

    public var isComplete: Bool {
        assignedCount == completedCount
    }

    public init(
        id: String,
        operatorID: String,
        displayName: String,
        sectionName: String,
        assignedCount: Int,
        completedCount: Int,
        remainingMinutes: Int,
        nextStepID: String?,
        nextStepTitle: String?,
        activeStepID: String?,
        activeStepTitle: String?,
        statusText: String
    ) {
        self.id = id
        self.operatorID = operatorID
        self.displayName = displayName
        self.sectionName = sectionName
        self.assignedCount = assignedCount
        self.completedCount = completedCount
        self.remainingMinutes = remainingMinutes
        self.nextStepID = nextStepID
        self.nextStepTitle = nextStepTitle
        self.activeStepID = activeStepID
        self.activeStepTitle = activeStepTitle
        self.statusText = statusText
    }
}

public struct TodayPrepCompletion: Sendable, Equatable {
    public var taskID: String
    public var completedBy: String
    public var checkedAt: String
    public var completedIDs: [String]

    public init(taskID: String, completedBy: String, checkedAt: String, completedIDs: [String]) {
        self.taskID = taskID
        self.completedBy = completedBy
        self.checkedAt = checkedAt
        self.completedIDs = completedIDs
    }
}

public struct TodayPrepActual: Sendable, Equatable, Identifiable {
    public var id: String
    public var taskID: String
    public var plannedMinutes: Int
    public var actualMinutes: Int
    public var varianceMinutes: Int
    public var startedAt: String
    public var checkedAt: String

    public init(
        id: String,
        taskID: String,
        plannedMinutes: Int,
        actualMinutes: Int,
        varianceMinutes: Int,
        startedAt: String,
        checkedAt: String
    ) {
        self.id = id
        self.taskID = taskID
        self.plannedMinutes = plannedMinutes
        self.actualMinutes = actualMinutes
        self.varianceMinutes = varianceMinutes
        self.startedAt = startedAt
        self.checkedAt = checkedAt
    }
}

public struct TodayPrepHold: Sendable, Equatable, Identifiable {
    public var id: String
    public var stepID: String
    public var reason: String
    public var pausedAt: String
    public var resumedAt: String?

    public var isActive: Bool {
        resumedAt == nil
    }

    public init(id: String, stepID: String, reason: String, pausedAt: String, resumedAt: String? = nil) {
        self.id = id
        self.stepID = stepID
        self.reason = reason
        self.pausedAt = pausedAt
        self.resumedAt = resumedAt
    }
}

public struct TodayPrepCheck: Sendable, Equatable, Identifiable {
    public var id: String
    public var stepID: String
    public var title: String
    public var detail: String

    public init(id: String, stepID: String, title: String, detail: String) {
        self.id = id
        self.stepID = stepID
        self.title = title
        self.detail = detail
    }
}

public struct TodayPrepReadiness: Sendable, Equatable {
    public var stepID: String?
    public var requiredCount: Int
    public var completedCount: Int
    public var remainingTitles: [String]

    public var canComplete: Bool {
        requiredCount == completedCount
    }

    public init(stepID: String?, requiredCount: Int, completedCount: Int, remainingTitles: [String]) {
        self.stepID = stepID
        self.requiredCount = requiredCount
        self.completedCount = completedCount
        self.remainingTitles = remainingTitles
    }
}

public struct TodayPrepAssistProposal: Sendable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var detail: String
    public var actionLabel: String
    public var suggestedOperatorID: String?
    public var suggestedOperatorName: String?
    public var savesMinutes: Int
    public var shortfallMinutes: Int

    public init(
        id: String,
        title: String,
        detail: String,
        actionLabel: String,
        suggestedOperatorID: String?,
        suggestedOperatorName: String?,
        savesMinutes: Int,
        shortfallMinutes: Int
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.actionLabel = actionLabel
        self.suggestedOperatorID = suggestedOperatorID
        self.suggestedOperatorName = suggestedOperatorName
        self.savesMinutes = savesMinutes
        self.shortfallMinutes = shortfallMinutes
    }
}

public struct DirectAllotment: Sendable, Equatable, Identifiable {
    public var id: String
    public var serviceDayID: String
    public var slot: String
    public var allottedCovers: Int
    public var bookedCovers: Int

    public init(id: String, serviceDayID: String, slot: String, allottedCovers: Int, bookedCovers: Int = 0) {
        self.id = id
        self.serviceDayID = serviceDayID
        self.slot = slot
        self.allottedCovers = allottedCovers
        self.bookedCovers = bookedCovers
    }
}

public struct DirectBookingDecision: Sendable, Equatable {
    public var status: DirectBookingStatus
    public var confirmedCovers: Int
    public var waitlistCovers: Int
    public var remainingAllotment: Int
    public var reason: String

    public init(status: DirectBookingStatus, confirmedCovers: Int, waitlistCovers: Int, remainingAllotment: Int, reason: String) {
        self.status = status
        self.confirmedCovers = confirmedCovers
        self.waitlistCovers = waitlistCovers
        self.remainingAllotment = remainingAllotment
        self.reason = reason
    }
}

public struct DirectNoShowSettlement: Sendable, Equatable, Identifiable {
    public var id: String
    public var bookingID: String
    public var status: DirectBookingStatus
    public var forfeitsDeposit: Bool
    public var prepImpactCovers: Int

    public init(id: String, bookingID: String, status: DirectBookingStatus, forfeitsDeposit: Bool, prepImpactCovers: Int) {
        self.id = id
        self.bookingID = bookingID
        self.status = status
        self.forfeitsDeposit = forfeitsDeposit
        self.prepImpactCovers = prepImpactCovers
    }
}

public struct DirectWaitlistPromotion: Sendable, Equatable, Identifiable {
    public var id: String
    public var directBookingID: String
    public var status: DirectBookingStatus
    public var promotedCovers: Int
    public var remainingAllotment: Int
    public var reason: String

    public init(
        id: String,
        directBookingID: String,
        status: DirectBookingStatus,
        promotedCovers: Int,
        remainingAllotment: Int,
        reason: String
    ) {
        self.id = id
        self.directBookingID = directBookingID
        self.status = status
        self.promotedCovers = promotedCovers
        self.remainingAllotment = remainingAllotment
        self.reason = reason
    }
}

public enum GuestSignalKind: String, Sendable, Equatable {
    case allergy
    case vip
    case special
}

public struct GuestSignal: Sendable, Equatable, Identifiable {
    public var id: String
    public var reservationID: String
    public var kind: GuestSignalKind
    public var text: String

    public init(id: String, reservationID: String, kind: GuestSignalKind, text: String) {
        self.id = id
        self.reservationID = reservationID
        self.kind = kind
        self.text = text
    }
}

public struct SpecialPrepTask: Sendable, Equatable, Identifiable {
    public var id: String
    public var reservationID: String
    public var title: String
    public var note: String

    public init(id: String, reservationID: String, title: String, note: String) {
        self.id = id
        self.reservationID = reservationID
        self.title = title
        self.note = note
    }
}

public struct AllergenLabel: Sendable, Equatable, Identifiable {
    public var id: String
    public var reservationID: String
    public var seatRef: String
    public var displayText: String
    public var language: String

    public init(id: String, reservationID: String, seatRef: String, displayText: String, language: String = "ja") {
        self.id = id
        self.reservationID = reservationID
        self.seatRef = seatRef
        self.displayText = displayText
        self.language = language
    }
}

public struct GuestMessage: Sendable, Equatable, Identifiable {
    public var id: String
    public var reservationID: String
    public var language: String
    public var body: String
    public var status: String

    public init(id: String, reservationID: String, language: String, body: String, status: String = "draft") {
        self.id = id
        self.reservationID = reservationID
        self.language = language
        self.body = body
        self.status = status
    }
}

public struct LarderAlert: Sendable, Equatable, Identifiable {
    public var id: String
    public var labelID: String
    public var prepTaskID: String
    public var qty: Double
    public var unit: String
    public var expireAt: String
    public var level: String

    public init(id: String, labelID: String, prepTaskID: String, qty: Double, unit: String, expireAt: String, level: String) {
        self.id = id
        self.labelID = labelID
        self.prepTaskID = prepTaskID
        self.qty = qty
        self.unit = unit
        self.expireAt = expireAt
        self.level = level
    }
}

public struct LarderUse: Sendable, Equatable, Identifiable {
    public var id: String
    public var labelID: String
    public var prepTaskID: String
    public var qty: Double
    public var unit: String
    public var expireAt: String

    public init(id: String, labelID: String, prepTaskID: String, qty: Double, unit: String, expireAt: String) {
        self.id = id
        self.labelID = labelID
        self.prepTaskID = prepTaskID
        self.qty = qty
        self.unit = unit
        self.expireAt = expireAt
    }
}

public struct LarderConsumptionPlan: Sendable, Equatable {
    public var uses: [LarderUse]
    public var requestedQty: Double
    public var plannedQty: Double
    public var shortfallQty: Double
    public var unit: String

    public init(uses: [LarderUse], requestedQty: Double, plannedQty: Double, shortfallQty: Double, unit: String) {
        self.uses = uses
        self.requestedQty = requestedQty
        self.plannedQty = plannedQty
        self.shortfallQty = shortfallQty
        self.unit = unit
    }
}

public struct ServiceReplaySummary: Sendable, Equatable {
    public var state: ServiceSyncState
    public var acceptedEventIDs: [String]
    public var ignoredDuplicateEventIDs: [String]

    public init(state: ServiceSyncState, acceptedEventIDs: [String], ignoredDuplicateEventIDs: [String]) {
        self.state = state
        self.acceptedEventIDs = acceptedEventIDs
        self.ignoredDuplicateEventIDs = ignoredDuplicateEventIDs
    }
}

public struct PassSeatFlag: Sendable, Equatable, Identifiable {
    public var id: String
    public var reservationID: String
    public var seatRef: String
    public var kind: GuestSignalKind
    public var displayText: String

    public init(id: String, reservationID: String, seatRef: String, kind: GuestSignalKind, displayText: String) {
        self.id = id
        self.reservationID = reservationID
        self.seatRef = seatRef
        self.kind = kind
        self.displayText = displayText
    }
}

public struct ServicePassState: Sendable, Equatable {
    public var firedCovers: Int
    public var heldCovers: Int
    public var seatFlags: [PassSeatFlag]
    public var recommendation: String

    public init(firedCovers: Int, heldCovers: Int, seatFlags: [PassSeatFlag], recommendation: String) {
        self.firedCovers = firedCovers
        self.heldCovers = heldCovers
        self.seatFlags = seatFlags
        self.recommendation = recommendation
    }
}

public struct StoreServiceSummary: Sendable, Equatable, Identifiable {
    public var id: String
    public var restaurantName: String
    public var serviceDate: String
    public var remainingCovers: Int
    public var recommendation: String

    public init(id: String, restaurantName: String, serviceDate: String, remainingCovers: Int, recommendation: String) {
        self.id = id
        self.restaurantName = restaurantName
        self.serviceDate = serviceDate
        self.remainingCovers = remainingCovers
        self.recommendation = recommendation
    }
}
