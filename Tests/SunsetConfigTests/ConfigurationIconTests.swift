import Foundation
import Testing

@testable import SunsetConfig

/// The app's icon (`appearance.icon`, n142): Auto by default, following the time of day through the four skies (`App/<Name>.icon`),
/// or one of the four chosen directly.
@Suite("Configuration: the app's icon")
struct ConfigurationIconTests {
    @Test func `Auto by default; every choice written and read back`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.appearance.icon == .auto)
        #expect(Configuration.Appearance.Icon.skies.map(\.assetName) == ["Dawn", "Sunset", "Twilight", "Dusk"])
        for icon in Configuration.Appearance.Icon.allCases {
            var chosen = Configuration()
            chosen.appearance.icon = icon
            let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: chosen))
            #expect(back.issues.isEmpty && back.configuration.appearance.icon == icon)
        }
        let read = try ConfigurationParser.parse(#"{"appearance":{"icon":"dusk"}}"#)
        #expect(read.configuration.appearance.icon == .dusk)
        #expect(!(try ConfigurationParser.parse(#"{"appearance":{"icon":"noon"}}"#).issues.isEmpty))
        #expect(ConfigurationKeys.all.contains("appearance.icon") && SettingsOption.named("appearance.icon") != nil)
    }

    @Test func `Auto picks the sky for the hour of day, and each fixed choice stays itself`() {
        typealias Icon = Configuration.Appearance.Icon
        for (hour, expected) in [
            (0, Icon.dusk), (4, .dusk),
            (5, .dawn), (11, .dawn),
            (12, .sunset), (18, .sunset),
            (19, .twilight), (20, .twilight),
            (21, .dusk), (23, .dusk)
        ] {
            #expect(Icon.forHour(hour) == expected, "hour \(hour)")
            #expect(Icon.auto.resolved(hour: hour) == expected, "auto at \(hour)")
        }
        for fixed in Icon.skies {
            #expect(fixed.resolved(hour: 3) == fixed && fixed.resolved(hour: 15) == fixed)
        }
    }

    @Test func `seconds until the next transition of the day`() throws {
        typealias Icon = Configuration.Appearance.Icon
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let morning = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 4, minute: 30))
        )
        let noon = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 11, minute: 0))
        )
        let night = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 23, minute: 0))
        )
        // 4:30 -> 5:00 (30 min), 11:00 -> 12:00 (60 min), 23:00 -> 05:00 next day (6 h).
        #expect(Icon.secondsUntilNextChange(from: morning, in: calendar) == 30 * 60)
        #expect(Icon.secondsUntilNextChange(from: noon, in: calendar) == 60 * 60)
        #expect(Icon.secondsUntilNextChange(from: night, in: calendar) == 6 * 3600)
    }
}
