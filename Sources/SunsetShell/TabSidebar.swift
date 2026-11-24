import AemiSDR
import SunsetMetrics
import SunsetPane
package import SwiftUI
import UniformTypeIdentifiers

/// The sidebar: the tabs of the window, listed vertically (the same `Workspace` the built-in bar shows), and nothing else. It has no background of its own
/// (the window's own colour or material shows through, with the window's settings) and is not a system list: the rows are `SidebarRow`s in a scroll view whose
/// content starts below the traffic lights and scrolls beneath them, fading out there. A click selects a tab, a drag reorders them.
package struct TabSidebar: View {
    /// The ends fade out, or are cut (`appearance.ends`).
    @Environment(\.fadesEnds) var fadesEnds
    var tabs: TabsModel
    let settings: ShellSettings
    /// The list alone, of a Space the window is sliding to (`SpaceSlide`): looked at, not acted on.
    var isPreview = false
    /// The pin button was pressed: the sidebar is to stay beside the content, or to hide and float (`sidebar.autoHide`, which the app owns).
    let togglePin: () -> Void
    /// Beside the pin, toward the traffic lights: the extensions' buttons.
    let headerExtras: AnyView?
    /// The floating panel: its traffic lights are a little further from the corner.
    var floating = false
    /// The floating panel's corner radius: the pin button's corner towards the panel's is concentric with it (same gap to both edges).
    var panelRadius: Double?
    /// The window's corner radius: docked, the button at its bottom corner is concentric with it.
    var windowRadius = ConcentricRadius.standardWindow
    /// What the app puts at the top, under the window's buttons (the address of the focused page).
    var accessory: AnyView?
    /// What the app puts under the accessory: calls to action; the rows start below it, as tall as it is.
    var notices: AnyView?
    /// What the app puts at the bottom, against the window's edge (the + button and downloads).
    var bottomBar: AnyView?
    /// How many buttons high the bar is: two while the downloads' button is above the Library's glyph.
    var bottomBarRows = 1
    /// What the app puts above the bar (the Now Playing cards); the rows end above it, as tall as it is.
    var footer: AnyView?
    @State var footerHeight = 0.0
    /// The row a drag is over, and what a drop there would do.
    @State var rowDrop: (owner: Workspace.ItemID, place: TabDropAction)?
    /// The gap between tabs a drag is over (before the tab at this index): the rows beside it move apart.
    @State var gapRoom: Int?
    @State private var rowSizes: [Workspace.ItemID: CGSize] = [:]
    @State private var rowFrames: [Workspace.ItemID: CGRect] = [:]
    /// Index of the row whose close button was just clicked, while the pointer remains inside the sidebar.
    @State private var closingSlot: Int?
    /// How far Today's tabs are scrolled down: the fade at their top grows with it.
    @State var scrolledBy = 0.0
    /// How tall this list's Pinned grid and Favorites are: their places in the neighbour's column while sliding.
    @State var keptHeights = (pinned: 0.0, favorites: 0.0)
    /// How tall the calls to action under the field are.
    @State var noticesHeight = 0.0
    @Environment(\.accent) var accentStyle

    var margin: Double {
        settings.sidebar.padding
    }
    /// The metrics the tabs draw with: the docked ones, or the floating panel's own.
    var layout: ShellSettings.Layout {
        floating ? settings.layout.floatingTabs : settings.layout
    }
    var header: SidebarHeader {
        SidebarHeader(layout: layout, margin: margin, floating: floating)
    }
    /// Where the rows start: below the window's buttons, and the accessory with a gap.
    private var topInset: Double {
        header.height + accessoryInset + noticesInset
    }

    package init(
        tabs: TabsModel,
        settings: ShellSettings,
        floating: Bool = false,
        panelRadius: Double? = nil,
        windowRadius: Double = ConcentricRadius.standardWindow,
        accessory: AnyView? = nil,
        notices: AnyView? = nil,
        bottomBar: AnyView? = nil,
        bottomBarRows: Int = 1,
        footer: AnyView? = nil,
        headerExtras: AnyView? = nil,
        togglePin: @escaping () -> Void
    ) {
        self.headerExtras = headerExtras
        self.bottomBarRows = bottomBarRows
        self.footer = footer
        self.accessory = accessory
        self.notices = notices
        self.bottomBar = bottomBar
        self.tabs = tabs
        self.settings = settings
        self.floating = floating
        self.panelRadius = panelRadius
        self.windowRadius = windowRadius
        self.togglePin = togglePin
    }

    package var body: some View {
        if isPreview { list } else { whole }
    }

    private var whole: some View {
        VStack(spacing: layout.tabSpacing) {
            // One scroll view for the Pinned grid, the Favorites and Today's tabs: in a short window it takes what the
            // header and the bottom bar leave, and never pushes them out. The swipe between Spaces moves each part, with
            // the neighbour's beside them.
            ScrollView {
                VStack(spacing: layout.tabSpacing) {
                    // Still while the swipe is to a Space that shows the same.
                    pinnedPart
                        .onGeometryChange(for: Double.self, of: { Double($0.size.height) }) { keptHeights.pinned = $0 }
                        .offset(x: tabs.slide.beside?.shares(.pinned) == true ? 0 : tabs.slide.shift)
                    favoritesPart
                        .onGeometryChange(for: Double.self, of: { Double($0.size.height) }) {
                            keptHeights.favorites = $0
                        }
                        .offset(x: tabs.slide.beside?.shares(.favorites) == true ? 0 : tabs.slide.shift)
                    today
                        .offset(x: tabs.slide.shift)
                }
            }
            .bouncesOnlyWhenScrolling()
            .scrollIndicators(.never)
            // Scrolled to its end, the last row clears the fade above the bottom bar (n134: it was faded).
            .contentMargins(
                .bottom,
                FootFade.margin(margin, faded: bottomBar != nil) + bottomInset,
                for: .scrollContent
            )
            .onScrollGeometryChange(for: Double.self, of: { Double($0.contentOffset.y + $0.contentInsets.top) }) {
                scrolledBy = max($1, 0)
            }
            // Rows that scroll past either end fade out: an alpha mask, no blur.
            .mask { fade }
        }
        // The neighbour's list, a column of its own from the top.
        .overlay(alignment: .top) { besideColumn }
        // Swiping between Spaces, cut and faded at the sidebar's sides, not under the panes; the fade comes and goes in
        // its own time.
        .mask { LateralFade(sliding: tabs.slide.masks || tabs.slide.beside != nil || tabs.slide.shift != 0) }
        .padding(.top, topInset)
        .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frame in
            if !isPreview { tabs.sidebarFrame = frame }
        }
        .onGeometryChange(for: Double.self, of: { Double($0.size.width) }) { width in
            tabs.slide.width = width
            tabs.slide.duration = layout.animation
            tabs.runSlide = SpaceSlide.animated
            tabs.withoutAnimation = SpaceSlide.plain
        }
        .background { SpaceSwipeCatcher(tabs: tabs, animation: layout.smooth, library: swipeLibrary) }
        .gesture(WindowDragGesture())
        // On the sidebar's empty area (a row's own menu wins over it).
        .inkedContextMenu {
            Button("New Folder") { tabs.newFolder() }
            Button("New Tab") { tabs.newTab() }
        }
        .modifier(EscapeClearsMarks(tabs: tabs))
        .onHover { inside in if !inside { closingSlot = nil } }
        .overlay(alignment: settings.sidebar.side == .left ? .topTrailing : .topLeading) { pinButton }
        .overlay(alignment: .top) { accessoryView }
        .overlay(alignment: .top) { noticesView }
        .overlay(alignment: .bottom) { bottomBarView }
        .environment(\.sectionSeparators, settings.sidebar.separators)
    }

    @ViewBuilder private func rowContent(_ item: Workspace.Item) -> some View {
        let armed = tabs.isCloseArmed(item.id)
        if item.isSplit {
            SidebarGroupRow(
                item: item,
                tabs: tabs,
                selected: tabs.isSelected(item.id),
                marked: tabs.isMarked(.tab(item.id)),
                armed: armed,
                layout: layout
            )
        } else {
            let slot = tabs.workspace.items.firstIndex(where: { $0.id == item.id })
            let custom = tabs.custom(for: item)
            SidebarRow(
                model: tabs.contents[item.focused],
                selected: tabs.isSelected(item.id),
                armed: armed,
                keepCloseVisible: slot != nil && slot == closingSlot,
                name: custom.name,
                icon: custom.icon,
                // A restored tab that waits has no content yet: its row reads what it starts from.
                saved: tabs.pendingDescriptor(item.focused),
                parts: settings.tabs.bar.parts,
                layout: layout,
                marked: tabs.isMarked(.tab(item.id)),
                awake: tabs.keepsAwake(item: item.id) != nil,
                stopAwake: { tabs.keepAwake(item: item.id, until: nil) },
                renaming: renaming(.tab(item.id)),
                close: {
                    closingSlot = slot
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        tabs.close(item: item.id)
                    }
                }
            )
        }
    }

    func row(_ item: Workspace.Item) -> some View {
        rowContent(item)
            .onGeometryChange(for: CGSize.self, of: \.size) { rowSizes[item.id] = $0 }
            .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { rowFrames[item.id] = $0 }
            .overlay {
                if rowDrop?.owner == item.id, let action = rowDrop?.place {
                    rowDropOverlay(action)
                }
            }
            .offset(y: roomOffset(item.id))
            .animation(layout.smooth, value: roomOffset(item.id))
            .onHover { inside in
                if inside {
                    if let slot = tabs.workspace.items.firstIndex(where: { $0.id == item.id }), closingSlot != slot {
                        closingSlot = nil
                    }
                    tabs.hoveredItem = item.id
                    tabs.hoveredRowFrame = rowFrames[item.id]
                } else if tabs.hoveredItem == item.id {
                    tabs.hoveredItem = nil
                }
            }
            .rowDragAndDrop(tabs, row: .tab(item.id), owner: item.id, size: rowSizes[item.id], active: $rowDrop)
            .inkedContextMenu { TabRowMenu(tabs: tabs, item: item.id, animation: layout.smooth) }
    }

    /// The in-place name of a row while it is being renamed.
    private func renaming(_ row: RowTarget) -> (start: String, done: (String?) -> Void)? {
        guard tabs.renamingRow == row else { return nil }
        return (
            tabs.name(of: row), { name in if let name { tabs.rename(row, to: name) } else { tabs.renamingRow = nil } }
        )
    }
}
