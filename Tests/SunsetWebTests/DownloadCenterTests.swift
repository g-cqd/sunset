import Foundation
import Testing

@testable import SunsetWeb

@Suite("The list of downloads") @MainActor struct DownloadCenterTests {
    func finishedItem(_ name: String, daysAgo: Double) -> DownloadItem {
        let item = DownloadItem(source: URL(string: "https://a.com/\(name)"), origin: nil, name: name)
        item.state = .finished
        item.finished = Date().addingTimeInterval(-daysAgo * 86_400)
        return item
    }

    @Test func `the list is kept in its file, latest first; a download cut by a quit comes back paused`() throws {
        let path = NSTemporaryDirectory() + "downloads-\(UUID().uuidString).json"
        let center = DownloadCenter()
        center.path = path
        center.insert(finishedItem("old.zip", daysAgo: 2))
        let cut = DownloadItem(source: nil, origin: nil, name: "big.iso")
        cut.resumeData = Data([1, 2, 3])
        center.insert(cut)
        let read = DownloadCenter()
        read.path = path
        #expect(read.items.map(\.name) == ["big.iso", "old.zip"])
        #expect(read.items[0].state == .paused && read.items[0].canResume)
    }

    @Test func `finished downloads older than the setting keeps are not read back`() {
        let path = NSTemporaryDirectory() + "downloads-\(UUID().uuidString).json"
        let center = DownloadCenter()
        center.path = path
        center.insert(finishedItem("week.zip", daysAgo: 3))
        center.insert(finishedItem("today.zip", daysAgo: 0.1))
        let read = DownloadCenter()
        read.settings.keep = .day
        read.path = path
        #expect(read.items.map(\.name) == ["today.zip"])
    }

    @Test func `the kept durations`() {
        let now = Date()
        let settings = DownloadSettings(keep: .week)
        #expect(settings.keeps(finishedAt: now.addingTimeInterval(-6 * 86_400), now: now))
        #expect(!settings.keeps(finishedAt: now.addingTimeInterval(-8 * 86_400), now: now))
        #expect(DownloadSettings(keep: .byHand).keeps(finishedAt: .distantPast, now: now))
        #expect(!DownloadSettings(keep: .untilQuit).keeps(finishedAt: now, now: now))
    }

    @Test func `the whole progress of what runs`() {
        let center = DownloadCenter()
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
