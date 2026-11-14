import Foundation
import Testing

@testable import SunsetWeb

@Suite("A private page's downloads") @MainActor struct PrivateDownloadTests {
    @Test func `listed, but never kept`() throws {
        let path = NSTemporaryDirectory() + "downloads-\(UUID().uuidString)/state.sqlite"
        let center = DownloadCenter()
        center.table = try TestState.table("downloads", at: path)
        let item = DownloadItem(source: nil, origin: nil, name: "secret.zip")
        item.isPrivate = true
        center.insert(item)
        center.insert(DownloadItem(source: nil, origin: nil, name: "plain.zip"))
        #expect(center.items.count == 2)
        let read = DownloadCenter()
        read.table = try TestState.table("downloads", at: path)
        #expect(read.items.map(\.name) == ["plain.zip"])
    }
}
