import Foundation

/// Role: Camp. One planted stake. A day accepts a single stake on the occupied camp only.
struct CampStake: Identifiable, Equatable, Sendable {
    var id: UUID
    var campID: String
    var choreName: String
    var dayKey: Int
    var value: Int
    var plantedAt: Date

    init(
        id: UUID = UUID(),
        campID: String,
        choreName: String,
        dayKey: Int,
        value: Int,
        plantedAt: Date
    ) {
        self.id = id
        self.campID = campID
        self.choreName = choreName
        self.dayKey = dayKey
        self.value = value
        self.plantedAt = plantedAt
    }
}

/// Role: Camp. Day keys are Int YYYYMMDD from Calendar.startOfDay in the user's zone.
enum CairnDay {
    static func key(for date: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: start)
        let month = calendar.component(.month, from: start)
        let day = calendar.component(.day, from: start)
        return year * 10_000 + month * 100 + day
    }

    static func start(from key: Int, calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = key / 10_000
        parts.month = (key / 100) % 100
        parts.day = key % 100
        guard let date = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: date)
    }

    static func previous(of key: Int, calendar: Calendar) -> Int? {
        guard let start = start(from: key, calendar: calendar),
              let prior = calendar.date(byAdding: .day, value: -1, to: start)
        else { return nil }
        return Self.key(for: prior, calendar: calendar)
    }

    static func weekKey(for date: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: date)
        let year = calendar.component(.yearForWeekOfYear, from: start)
        let week = calendar.component(.weekOfYear, from: start)
        return year * 100 + week
    }
}
