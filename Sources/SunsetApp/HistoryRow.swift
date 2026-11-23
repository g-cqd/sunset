import AppKit
import Foundation
import SunsetMetrics
import SunsetShell
import SunsetWeb
import SwiftUI

/// A page in the history panel: its title and address; a click opens it in the focused page, Cmd-click in a new tab; its menu.
struct HistoryRow: View {
    let entry: HistoryEntry
    let layout: LayoutMetrics
    /// The window's profile, whose kept site icons are shown.
    var profile: UUID?
    /// Its title and its address.
    private static let lines = 2
    @State private var hovered = false

    /// The site's icon when one is kept (n120), else a globe.
    private var glyph: PaneGlyph {
        FaviconStore.shared.image(forPage: entry.url, profile: profile)?.panePicture.map(PaneGlyph.image)
            ?? .symbol("globe")
    }

    var body: some View {
        // A sidebar row of a page that is not open: its glyph and two lines, no fill at rest.
        HStack(spacing: GlyphSpacing.toText) {
            PaneGlyphView(glyph: glyph)
            VStack(alignment: .leading, spacing: Design.Space.hair) {
                Text(entry.title.isEmpty ? AddressChoice.shortAddress(entry.url) : entry.title).lineLimit(1)
                Text(AddressChoice.shortAddress(entry.url))
                    .code()
                    .font(Design.Text.detail)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .modifier(
            LibraryRowFrame(layout: layout, lines: Self.lines, fill: hovered ? Design.Fill.hover : 0, hovered: $hovered)
        )
        .onTapGesture { AppActions.shared.openFromHistory(entry.url, newTab: NSEvent.modifierFlags.contains(.command)) }
        // One element that can be pressed through accessibility: a tap gesture alone is not reached by VoiceOver's press.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { AppActions.shared.openFromHistory(entry.url, newTab: false) }
        .help(entry.url)
        .contextMenu {
            // In a new tab with Option, as ⌘-click does.
            Button("Open") { AppActions.shared.openFromHistory(entry.url, newTab: false) }
                .modifierKeyAlternate(.option) {
                    Button("Open in New Tab") { AppActions.shared.openFromHistory(entry.url, newTab: true) }
                }
            Button("Copy Address") { Clipboard.copyAndSay(entry.url, isLink: true, what: "Copied the address") }
            Divider()
            Button("Delete from History", role: .destructive) { AppHistory.shared?.delete(entry.url) }
        }
    }
}
