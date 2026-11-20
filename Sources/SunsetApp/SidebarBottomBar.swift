import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetWeb
import SwiftUI

/// The bottom of the sidebar (R2's + button, t137, web step f, roadmap 0031), mirroring the pin at the top: the + on the corner nearest the panes
/// (the owner's sketch E); at the window's edge the Library's glyph, which widens the sidebar by its rail, and above it the
/// downloads while there are any (the owner's notes n60, n61: where they stay when the Library opens, above the way back);
/// all the sidebar's buttons (`SidebarIconButton`). The Spaces are in the middle (`SpacesRow`), once there are two. A click on + makes a tab of the focused kind; its menu
/// (right-click or long press) has every kind.
struct SidebarBottomBar: View {
    let side: Configuration.Side
    let tabs: TabsModel
    /// `sidebar.library`: the Library's glyph is there.
    let library: Bool
    /// Between two buttons side by side: the rows' spacing, as between the Library rail's buttons (the owner, 2026-11-17:
    /// the downloads' button was flush against the Library's).
    let spacing: Double
    private let downloads = DownloadCenter.shared

    init(side: Configuration.Side, tabs: TabsModel, library: Bool, spacing: Double) {
        self.side = side
        self.tabs = tabs
        self.library = library
        self.spacing = spacing
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if side == .left {
                edge
            } else {
                plus
            }
            // The Spaces, centred between the two ends (R4; the owner, 2026-11-17): there once a second exists. The row
            // takes the width between the buttons; with one Space it is not there and the width is left empty.
            Spacer(minLength: 0)
            SpacesRow(tabs: tabs)
            Spacer(minLength: 0)
            if side == .left {
                plus
            } else {
                edge
            }
        }
    }

    /// How many buttons high the bar is: two while the downloads' button is above the Library's glyph.
    static func rows(library: Bool, downloads: Bool) -> Int {
        library && downloads ? 2 : 1
    }

    /// The window's edge: the downloads above the Library's glyph, which is at the corner.
    private var edge: some View {
        VStack(spacing: spacing) {
            downloadsButton
            libraryButton
        }
    }

    @ViewBuilder private var libraryButton: some View {
        // No Library when no section of it is of a scope that is on.
        if library, SidebarSection.rail(for: tabs.scopes).count > 1 {
            SidebarIconButton(symbol: "books.vertical", help: "Library") {
                tabs.sections.toggleLibrary()
            }
            .accessibilityLabel("Library")
            .environment(\.sidebarButtonCorner, corner)
        }
    }

    /// The window's bottom corner the bar ends at: the button there is concentric with it (the owner, 2026-11-15).
    private var corner: SidebarButtonCorner {
        side == .left ? .bottomLeading : .bottomTrailing
    }

    @ViewBuilder private var downloadsButton: some View {
        // Without the Library's glyph the downloads are at the window's corner.
        if !downloads.items.isEmpty { DownloadsButton().environment(\.sidebarButtonCorner, library ? nil : corner) }
    }

    private var plus: some View {
        SidebarIconButton(
            symbol: "plus",
            help: "New Tab (right-click for its kind)",
            menu: AnyView(kinds),
            action: { AppActions.shared.newTab() }
        )
    }

    @ViewBuilder private var kinds: some View {
        let scopes = tabs.scopes
        NewKindButtons(scopes: scopes)
        if scopes.web {
            Button("New Private Tab") { AppActions.shared.newTab(kind: PaneContentKinds.newPrivatePage) }
        }
        if scopes.documents {
            Divider()
            Button("New Document") { AppActions.shared.newDocument() }
            Button("Open File\u{2026}") { AppActions.shared.openFile() }
        }
        Divider()
        Button("New Space") { tabs.newSpace() }.disabled(tabs.spaces == nil)
    }
}
