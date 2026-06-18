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
