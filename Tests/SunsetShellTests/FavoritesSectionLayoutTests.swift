import AppKit
import Foundation
import SwiftUI
import Testing

@testable import SunsetPane
@testable import SunsetShell
@testable import SunsetShellModel

/// Separators were drawn across the tabs of the sidebar. The Favorites and the line under them were two views side by
/// side in the sidebar's stack; a modifier that measures them (added for the slide) laid the two over each other, the
/// line across the middle of the rows.
@MainActor @Suite("The Favorites and their line")
struct FavoritesSectionLayoutTests {
    @Test func `measured or not, the line stays under the rows`() throws {
        var kept = Favorites()
        for _ in 0 ..< 3 {
            let pane = PaneID()
            _ = kept.addEntry(home: Favorites.Home(layout: .pane(pane), focused: pane))
        }
        let favorites = FavoritesModel()
        favorites.restore(SavedFavorites(favorites: kept, contents: [:]))
        let harness = TabsHarness(favorites: favorites)
        let layout = ShellSettings().layout
        func height(_ view: some View) throws -> Double {
            let renderer = ImageRenderer(content: view.frame(width: 240))
            return Double(try #require(renderer.cgImage).height) / renderer.scale
        }
        let plain = try height(
            VStack(spacing: 0) { FavoritesSection(tabs: harness.tabs, settings: ShellSettings(), layout: layout) }
        )
        let measured = try height(
            VStack(spacing: 0) {
                FavoritesSection(tabs: harness.tabs, settings: ShellSettings(), layout: layout)
                    .onGeometryChange(for: Double.self, of: { Double($0.size.height) }) { _ in }
            }
        )
        #expect(measured == plain, "\(measured) measured, \(plain) not")
        #expect(plain > SectionSeparator.room * 2)
    }
}
