import Foundation
import SunsetTestSupport
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// Seen on screen 2026-11-20: Download Video did nothing. For a film WebKit does not make a download: it hands its bytes to
/// the UI delegate (`_webView:saveDataToFile:suggestedFilename:mimeType:originatingURL:`, probed), which Sunset's did not
/// answer. They are saved as a download is: the folder, a free name, quarantined, in the list, finished.
@Suite("A film saved from the page's menu") @MainActor struct SavedMediaTests {
    @Test func `its bytes go to the folder under a free name, listed as finished`() async throws {
        let folder = URL(filePath: NSTemporaryDirectory()).appending(path: "saved-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("there".utf8).write(to: folder.appending(path: "clip.mp4"))
        let center = DownloadCenter()
        center.runtime = TestTime().runtime
        let source = try #require(URL(string: "https://a.com/media/clip.mp4"))
        let saved = await center.save(
            DownloadCenter.Saved(
                data: Data("film".utf8),
                name: "clip.mp4",
                source: source,
                origin: URL(string: "https://a.com/"),
                isPrivate: false
            ),
            folder: folder,
            asks: false
        )
        let item = try #require(saved)
        let written = try #require(item.destination)
        #expect(written.lastPathComponent == "clip-2.mp4", "the name already there is kept")
        #expect(try Data(contentsOf: written) == Data("film".utf8))
        #expect(item.state == .finished && center.items.first === item)
    }
}
