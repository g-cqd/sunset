package import Foundation
import SunsetRuntime

/// Rows under a heading in a sidebar list: a day (Today, Yesterday, then each day by its date), a kind, or no heading.
package struct ListGroup<Element> {
    package let title: String?
    package let elements: [Element]

    package init(title: String?, elements: [Element]) {
        self.title = title
        self.elements = elements
    }

    /// `elements` by the day of `date`, in the order they come in (the latest first when they are).
    /// - Complexity: O(n).
    package static func days(
        _ elements: [Element],
        by date: (Element) -> Date,
        now: Date = Runtime.live.now(),
        calendar: Calendar = .current
    ) -> [Self] {
        var order: [Date] = []
        var byDay: [Date: [Element]] = [:]
        for element in elements {
            let day = calendar.startOfDay(for: date(element))
            if byDay[day] == nil { order.append(day) }
            byDay[day, default: []].append(element)
        }
        return order.map { Self(title: dayTitle($0, now: now, calendar: calendar), elements: byDay[$0] ?? []) }
    }

    package static func dayTitle(_ day: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
            calendar.isDate(day, inSameDayAs: yesterday)
        {
            return "Yesterday"
        }
        return day.formatted(date: .complete, time: .omitted)
    }
}
