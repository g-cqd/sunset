import Foundation
import SunsetTestSupport
import Testing

@testable import SunsetCore

/// By hand, release (SUNSET_LINK_PROBE=1): 200,000 distinct links fed, each over the last; the time, and the table at the end.
@Suite("link table probe", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_LINK_PROBE"] != nil))
struct LinkTableSpeedProbe {
    @Test func `many links`() {
        var t = Terminal(columns: 120, rows: 40)
        let input = (0 ..< 200_000)
            .map { "\u{1B}[1;1H\u{1B}]8;;https://example.com/page/\($0)\u{1B}\\x\u{1B}]8;;\u{1B}\\" }.joined()
        let spent = Stopwatch.time { t.feed(input) }
        print("LINKS", spent, "addresses kept", t.screen.links.addresses.count)
    }
}
