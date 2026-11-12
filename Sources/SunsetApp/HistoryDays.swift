import Foundation
import SunsetWeb

/// The history panel's sections: Today, Yesterday, then each day by its date, latest first.
struct HistoryDays {
    let title: String
    let entries: [HistoryEntry]

    static func group(_ entries: [HistoryEntry], now: Date = Date(), calendar: Calendar = .current) -> [Self] {
        var order: [Date] = []
        var byDay: [Date: [HistoryEntry]] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.lastVisit)
            if byDay[day] == nil { order.append(day) }
            byDay[day, default: []].append(entry)
        }
        return order.map { Self(title: title(of: $0, now: now, calendar: calendar), entries: byDay[$0] ?? []) }
    }

    static func title(of day: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
            calendar.isDate(day, inSameDayAs: yesterday)
        {
            return "Yesterday"
        }
        return day.formatted(date: .complete, time: .omitted)
    }
}
