import Foundation

/// How far back Clear History goes.
enum ClearSpan: CaseIterable {
    case lastHour, today, todayAndYesterday, all

    var title: String {
        switch self {
            case .lastHour: "The last hour"
            case .today: "Today"
            case .todayAndYesterday: "Today and yesterday"
            case .all: "All history"
        }
    }

    func start(now: Date = Date(), calendar: Calendar = .current) -> Date {
        switch self {
            case .lastHour: now.addingTimeInterval(-3_600)
            case .today: calendar.startOfDay(for: now)
            case .todayAndYesterday: calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) ?? now
            case .all: .distantPast
        }
    }
}
