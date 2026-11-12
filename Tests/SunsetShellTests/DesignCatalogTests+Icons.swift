import SwiftUI

@testable import SunsetShell

/// Candidate symbols for the folder, the sidebar pin, downloads and the private marker (owner's guidance 8 and 1), each in a 28 pt
/// rounded square as the sidebar draws its buttons, and at a row's glyph size.
extension DesignCatalogTests {
    private func symbols(_ names: [(String, String)], filled: Bool = false) -> [CatalogSheet.Example] {
        names.map { label, name in
            CatalogSheet.Example(
                label: label,
                view: AnyView(
                    HStack(spacing: 14) {
                        Image(systemName: name).font(.system(size: 13)).frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.primary.opacity(0.1))
                            )
                        Image(systemName: name).font(.system(size: 15)).frame(width: 18, height: 18)
                        Text(name).font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                )
            )
        }
    }

    var icons: CatalogSheet {
        CatalogSheet(
            title: "Symbol candidates",
            note:
                "Today: folder / folder.fill (closed / open), sidebar.left (filled when pinned), arrow.down.circle (downloads), the word "
                + "\"Private\". Each candidate as a sidebar button (28) and as a row glyph (15 in 18).",
            columns: [
                .init(
                    title: "Folder: closed → open",
                    examples: symbols([
                        ("today closed", "folder"), ("today open", "folder.fill"),
                        ("A closed", "folder"), ("A open", "folder.badge.minus"),
                        ("B closed", "chevron.right"), ("B open", "chevron.down"),
                        ("C closed", "rectangle.stack"), ("C open", "rectangle.stack.fill"),
                        ("D closed", "square.stack"), ("D open", "list.bullet.indent")
                    ])
                ),
                .init(
                    title: "Sidebar: hides → kept",
                    examples: symbols([
                        ("today hides", "sidebar.left"), ("today kept", "sidebar.left"),
                        ("A hides", "rectangle.leadinghalf.inset.filled"), ("A kept", "sidebar.leading"),
                        ("B hides", "pin"), ("B kept", "pin.fill"),
                        ("C hides", "sidebar.squares.leading"), ("C kept", "sidebar.leading")
                    ])
                ),
                .init(
                    title: "Downloads",
                    examples: symbols([
                        ("today", "arrow.down.circle"), ("A", "tray.and.arrow.down"), ("B", "arrow.down.to.line"),
                        ("C", "square.and.arrow.down"), ("D", "tray.full")
                    ])
                ),
                .init(
                    title: "Private marker",
                    examples: symbols([
                        ("A", "theatermasks.fill"), ("B", "eyeglasses"), ("C", "sunglasses.fill"), ("D", "eye.slash"),
                        ("E", "hand.raised.fill"), ("F", "lock.shield.fill"), ("G", "moon.fill")
                    ])
                )
            ],
            width: 330
        )
    }
}
