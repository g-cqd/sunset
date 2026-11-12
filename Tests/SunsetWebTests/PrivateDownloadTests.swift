import Foundation
import Testing

@testable import SunsetWeb

@Suite("A private page's downloads") @MainActor struct PrivateDownloadTests {
    @Test func `listed, but never written to the list's file`() {
        let path = NSTemporaryDirectory() + "downloads-\(UUID().uuidString).json"
        let center = DownloadCenter()
        center.path = path
        let item = DownloadItem(source: nil, origin: nil, name: "secret.zip")
        item.isPrivate = true
        center.insert(item)
        center.insert(DownloadItem(source: nil, origin: nil, name: "plain.zip"))
        #expect(center.items.count == 2)
        let read = DownloadCenter()
        read.path = path
        #expect(read.items.map(\.name) == ["plain.zip"])
    }
}
