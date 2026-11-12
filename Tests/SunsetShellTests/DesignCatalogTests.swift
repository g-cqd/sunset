import Foundation
import SunsetMetrics
import SunsetPane
import SwiftUI
import Testing

@testable import SunsetShell

/// The design catalog (design 0003, migration step 3): every row and button variant, today's and proposed, drawn off-screen for the owner.
/// Runs only with `SUNSET_CATALOG=<folder>`; otherwise it does nothing. Hover cannot be forced from outside a view; `keepCloseVisible` draws
/// the same fill and close button a hovered row has.
@MainActor @Suite("Design catalog") struct DesignCatalogTests {
    private let folder = ProcessInfo.processInfo.environment["SUNSET_CATALOG"].map { URL(fileURLWithPath: $0) }

    private func content(_ title: String, detail: String? = nil, symbol: String = "terminal") -> FakeContent {
        let content = FakeContent()
        content.glyphValue = .symbol(symbol)
        content.title = title
        content.detail = detail
        return content
    }

    /// The rows of one layout: every state of a tab, one line and two.
    private func tabRows(_ layout: LayoutMetrics, oneLine proposed: LayoutMetrics? = nil) -> [CatalogSheet.Example] {
        let one = proposed ?? layout
        func row(
            _ label: String,
            _ model: FakeContent,
            layout: LayoutMetrics,
            directory: Bool = false,
            selected: Bool = false,
            hover: Bool = false,
            marked: Bool = false,
            armed: Bool = false,
            dimmed: Bool = false,
            button: SidebarRow.Button = .close
        ) -> CatalogSheet.Example {
            CatalogSheet.Example(
                label: label,
                view: AnyView(
                    SidebarRow(
                        model: model,
                        selected: selected,
                        armed: armed,
                        keepCloseVisible: hover,
                        showIcon: true,
                        showTitle: true,
                        showDirectory: directory,
                        showProgress: true,
                        layout: layout,
                        button: button,
                        dimmed: dimmed,
                        marked: marked
                    ) {}
                )
            )
        }
        let shell = content("zsh", detail: "~/Projects/sunset")
        let page = content("Example Domain", detail: "example.com", symbol: "globe")
        return [
            row("1 line", shell, layout: one),
            row("1 line selected", shell, layout: one, selected: true),
            row("1 line hover", shell, layout: one, hover: true),
            row("selected + hover", shell, layout: one, selected: true, hover: true),
            row("marked (multi)", shell, layout: one, marked: true),
            row("armed (busy close)", shell, layout: one, armed: true),
            row("kept, not open", page, layout: one, dimmed: true, button: .delete),
            row("2 lines", shell, layout: layout, directory: true),
            row("2 lines selected", shell, layout: layout, directory: true, selected: true),
            row("2 lines hover", page, layout: layout, directory: true, hover: true),
            CatalogSheet.Example(label: "in the sidebar", view: AnyView(stack(one, layout)))
        ]
    }

    /// Rows as the sidebar stacks them (its spacing and side inset), one line and two, one selected.
    private func stack(_ one: LayoutMetrics, _ two: LayoutMetrics) -> some View {
        let rows: [(FakeContent, Bool, Bool)] = [
            (content("zsh", detail: "~/Projects/sunset"), false, false),
            (content("Example Domain", detail: "example.com", symbol: "globe"), true, false),
            (content("vim", detail: "~/notes"), false, false),
            (content("zsh", detail: "~/Projects/sunset"), false, true),
            (content("Docs", detail: "developer.apple.com", symbol: "globe"), false, true)
        ]
        return VStack(spacing: one.tabSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                SidebarRow(
                    model: row.0,
                    selected: row.1,
                    showIcon: true,
                    showTitle: true,
                    showDirectory: row.2,
                    showProgress: true,
                    layout: row.2 ? two : one
                ) {}
            }
        }
        .padding(.horizontal, one.tabSideInset)
        .padding(.vertical, 8)
        .background(Color(white: 0.09))
    }

    @Test func `the rows and buttons, drawn for the owner`() throws {
        guard let folder else { return }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let docked = LayoutMetrics()
        var dockedProposed = docked
        dockedProposed.tabPaddingVertical = 6
        let floating = docked.floatingTabs
        var floatingProposed = floating
        floatingProposed.tabPaddingVertical = 6
        let rows = CatalogSheet(
            title: "Sidebar tab rows",
            note:
                "Today and proposed (n66: one-line rows 26 → 32, the glyph's ink 9 pt from the top and bottom as from the leading edge; "
                + "two-line rows unchanged). Floating: the panel's own keys (tab spacing 3, side inset 4); proposed: the same rule.",
            columns: [
                .init(title: "Docked, today", examples: tabRows(docked)),
                .init(title: "Docked, proposed", examples: tabRows(docked, oneLine: dockedProposed)),
                .init(title: "Floating, today", examples: tabRows(floating)),
                .init(title: "Floating, proposed", examples: tabRows(floating, oneLine: floatingProposed))
            ],
            width: 221
        )
        #expect(rows.write(to: folder.appending(path: "rows-sidebar.png")))
        #expect(buttons.write(to: folder.appending(path: "buttons.png")))
        #expect(groups(docked, dockedProposed).write(to: folder.appending(path: "rows-groups.png")))
        #expect(fields.write(to: folder.appending(path: "fields.png")))
        #expect(barButtons.write(to: folder.appending(path: "bar-buttons.png")))
        #expect(icons.write(to: folder.appending(path: "icons.png")))
        #expect(tree.write(to: folder.appending(path: "tree.png")))
        #expect(rowDetails.write(to: folder.appending(path: "row-details.png")))
        #expect(splits.write(to: folder.appending(path: "splits.png")))
        let favorites = try JSONEncoder().encode(Self.catalogFavorites())
        try favorites.write(to: FileManager.default.temporaryDirectory.appending(path: "catalog-favorites.json"))
    }
}
