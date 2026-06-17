import Foundation

struct ServiceDaySettings: Equatable {
    var id: String
    var date: String
    var displayDate: String
    var period: String
    var openTime: String
    var omakaseCovers: Int
    var otherCovers: Int
    var reservations: [ManualReservation]

    var totalCovers: Int {
        omakaseCovers + otherCovers
    }

    static let seed = ServiceDaySettings(
        id: "service-2026-06-11-dinner",
        date: "2026-06-11",
        displayDate: "2026/06/11(木)",
        period: "夜",
        openTime: "18:00",
        omakaseCovers: 14,
        otherCovers: 0,
        reservations: [
            ManualReservation(id: "reservation-sato", visitTime: "18:00", partyName: "佐藤 様", note: "記念日・乾杯シャンパン", covers: 2),
            ManualReservation(id: "reservation-suzuki", visitTime: "18:00", partyName: "鈴木 様", note: "メモ：—", covers: 4),
            ManualReservation(id: "reservation-takahashi", visitTime: "18:30", partyName: "高橋 様", note: "アレルギー：甲殻類（参考）", covers: 6),
            ManualReservation(id: "reservation-tanaka", visitTime: "20:00", partyName: "田中 様", note: "電話予約・接待", covers: 2),
        ]
    )
}

struct ManualReservation: Identifiable, Equatable {
    var id: String
    var visitTime: String
    var partyName: String
    var note: String
    var covers: Int
}
