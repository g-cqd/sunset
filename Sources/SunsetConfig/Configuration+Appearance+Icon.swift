public import Foundation

extension Configuration.Appearance {
    /// The app's icon (n142): Auto by default, following the time of day through the four skies built into the asset
    /// catalog (`App/<assetName>.icon`), or one of them chosen directly. The proposed skies (`proposed`) can be chosen
    /// too, shown in the picker only while Option is held; Auto does not use them.
    public enum Icon: String, Sendable, Equatable, CaseIterable {
        case auto, sunset, twilight, dawn, dusk, sunrise, morning, noon, afternoon, night

        /// The four skies, in the order of the day (dawn, sunset, twilight, dusk).
        public static let skies: [Self] = [.dawn, .sunset, .twilight, .dusk]

        /// The skies proposed on 2026-11-28, not yet approved: in the order of the day.
        public static let proposed: [Self] = [.sunrise, .morning, .noon, .afternoon, .night]

        /// Its name in the picker.
        public var title: String {
            self == .morning ? "Later morning" : assetName
        }

        /// The icon's name in the asset catalog (the bundle's own for `sunset`, an alternate for the others; `auto`
        /// resolves to one of `skies` first).
        public var assetName: String {
            rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }

        /// The sky for the hour of the day (0...23): dawn in the morning, sunset in the afternoon, twilight in the
        /// evening, dusk at night.
        public static func forHour(_ hour: Int) -> Self {
            switch ((hour % 24) + 24) % 24 {
                case 5 ..< 12: .dawn
                case 12 ..< 19: .sunset
                case 19 ..< 21: .twilight
                default: .dusk
            }
        }

        /// Which of the four skies this choice shows at `hour` (fixed choices stay themselves).
        public func resolved(hour: Int) -> Self {
            self == .auto ? Self.forHour(hour) : self
        }

        /// Which of the four skies this choice shows at `date` in `calendar`.
        public func resolved(at date: Date, in calendar: Calendar = .current) -> Self {
            resolved(hour: calendar.component(.hour, from: date))
        }

        /// Seconds from `date` until the next hour when `forHour` changes (5, 12, 19, 21), at least 1.
        public static func secondsUntilNextChange(from date: Date, in calendar: Calendar = .current) -> TimeInterval {
            let hour = calendar.component(.hour, from: date)
            let boundaries = [5, 12, 19, 21]
            let nextHour = boundaries.first { $0 > hour } ?? boundaries[0]
            let sameDay = nextHour > hour
            let day = sameDay ? date : (calendar.date(byAdding: .day, value: 1, to: date) ?? date)
            var parts = calendar.dateComponents([.year, .month, .day], from: day)
            parts.hour = nextHour
            parts.minute = 0
            parts.second = 0
            guard let target = calendar.date(from: parts) else { return 3600 }
            return max(1, target.timeIntervalSince(date))
        }
    }
}
