import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetWeb
import SwiftUI

/// The bottom of the sidebar (R2's + button, t137, web step f, roadmap 0031), mirroring the pin at the top: the + on the corner nearest the panes
/// (the owner's sketch E); at the window's edge the Library's glyph, which widens the sidebar by its rail, then downloads while there are any; all
/// the sidebar's buttons (`SidebarIconButton`). The middle is left free (spaces, later). A click on + makes a tab of the focused kind; its menu
/// (right-click or long press) has every kind.
struct SidebarBottomBar: View {
    let side: Configuration.Side
    let tabs: TabsModel
    /// `sidebar.library`: the Library's glyph is there.
    let library: Bool
    private let downloads = DownloadCenter.shared

    init(side: Configuration.Side, tabs: TabsModel, library: Bool) {
        self.side = side
        self.tabs = tabs
        self.library = library
    }

    var body: some View {
        HStack(spacing: 0) {
            if side == .left {
                libraryButton
                downloadsButton
            } else {
                plus
            }
            Spacer(minLength: 0)
            if side == .left {
                plus
            } else {
                downloadsButton
                libraryButton
            }
        }
    }

    @ViewBuilder private var libraryButton: some View {
        if library {
            SidebarIconButton(symbol: "books.vertical", help: "Library: Documents, History, Downloads") {
                tabs.sections.toggleLibrary()
            }
            .accessibilityLabel("Library")
        }
    }

    @ViewBuilder private var downloadsButton: some View {
        if !downloads.items.isEmpty { DownloadsButton() }
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
        Button("New Terminal Tab") { AppActions.shared.newTab(kind: PaneDescriptor.terminal(directory: nil)) }
        Button("New Web Page") { AppActions.shared.newTab(kind: PaneContentKinds.newPage) }
        Button("New Private Tab") { AppActions.shared.newTab(kind: PaneContentKinds.newPrivatePage) }
    }
}
