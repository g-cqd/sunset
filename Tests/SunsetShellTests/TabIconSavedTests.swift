import AppKit
import SunsetPane
import SwiftUI
import Testing

@testable import SunsetShell

/// A page not loaded shows its site's icon when the app keeps one (roadmap 0035 H), else the globe; a picture the person
/// gave the tab wins over both.
@MainActor
@Suite("A tab not running, pictured")
struct TabIconSavedTests {
    private let page = PaneDescriptor(kind: "web", state: ["url": "https://a.example/"])

    private func drawn(icon: PaneIcon? = nil, pictures: SavedPictures) throws -> Data {
        let view = TabIcon(model: nil, icon: icon, saved: page).environment(\.savedPicture, pictures)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        return try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
    }

    private var star: SavedPictures {
        SavedPictures(source: 1) { _ in .symbol("star.fill") }
    }

    @Test func `the app's picture for what it would start from is drawn instead of the kind's mark`() throws {
        #expect(try drawn(pictures: star) != drawn(pictures: SavedPictures()))
        #expect(try drawn(pictures: star) == drawn(pictures: SavedPictures(source: 2) { _ in .symbol("star.fill") }))
    }

    @Test func `a picture the person chose wins`() throws {
        let chosen = PaneIcon.symbol("leaf")
        #expect(try drawn(icon: chosen, pictures: star) == drawn(icon: chosen, pictures: SavedPictures()))
    }
}
