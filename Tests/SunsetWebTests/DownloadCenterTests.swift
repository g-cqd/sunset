import Foundation
import SunsetTestSupport
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

@Suite("The list of downloads") @MainActor struct DownloadCenterTests {
    /// The wall time of these tests, and of the lists they make (ADR-0087).
    static let now = TestTime.epoch
    private let time = TestTime()

    private func makeCenter() -> DownloadCenter {
        let center = DownloadCenter()
        center.runtime = time.runtime
        return center
    }

    func finishedItem(_ name: String, daysAgo: Double) -> DownloadItem {
        let item = DownloadItem(source: URL(string: "https://a.com/\(name)"), origin: nil, name: name)
        item.state = .finished
        item.finished = Self.now.addingTimeInterval(-daysAgo * 86_400)
        return item
    }

    @Test func `the list is kept in its file, latest first; a download cut by a quit comes back paused`() throws {
        let path = NSTemporaryDirectory() + "downloads-\(UUID().uuidString)/state.sqlite"
        let center = makeCenter()
        center.table = try TestState.table("downloads", at: path)
        center.insert(finishedItem("old.zip", daysAgo: 2))
        let cut = DownloadItem(source: nil, origin: nil, name: "big.iso")
        cut.resumeData = Data([1, 2, 3])
        center.insert(cut)
        let read = makeCenter()
        read.table = try TestState.table("downloads", at: path)
        #expect(read.items.map(\.name) == ["big.iso", "old.zip"])
        #expect(read.items[0].state == .paused && read.items[0].canResume)
    }

    @Test func `finished downloads older than the setting keeps are not read back`() throws {
        let path = NSTemporaryDirectory() + "downloads-\(UUID().uuidString)/state.sqlite"
        let center = makeCenter()
        center.table = try TestState.table("downloads", at: path)
        center.insert(finishedItem("week.zip", daysAgo: 3))
        center.insert(finishedItem("today.zip", daysAgo: 0.1))
        let read = makeCenter()
        read.settings.keep = .day
        read.table = try TestState.table("downloads", at: path)
        #expect(read.items.map(\.name) == ["today.zip"])
    }

    @Test func `the kept durations`() {
        let now = Self.now
        let settings = DownloadSettings(keep: .week)
        #expect(settings.keeps(finishedAt: now.addingTimeInterval(-6 * 86_400), now: now))
        #expect(!settings.keeps(finishedAt: now.addingTimeInterval(-8 * 86_400), now: now))
        #expect(DownloadSettings(keep: .byHand).keeps(finishedAt: .distantPast, now: now))
        #expect(!DownloadSettings(keep: .untilQuit).keeps(finishedAt: now, now: now))
    }

    @Test func `the whole progress of what runs`() {
        let center = makeCenter()
        let a = DownloadItem(source: nil, origin: nil, name: "a")
        a.received = 50
        a.expected = 100
        let b = DownloadItem(source: nil, origin: nil, name: "b")
        b.received = 0
        b.expected = 300
        center.insert(a)
        center.insert(b)
        #expect(center.progress == 0.125)
    }
}
