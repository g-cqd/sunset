import SunsetMetrics
import SunsetPane
package import SwiftUI
import UniformTypeIdentifiers

/// The sidebar: the tabs of the window, listed vertically (the same `Workspace` the built-in bar shows), and nothing else. It has no background of its own
/// (the window's own colour or material shows through, with the window's settings) and is not a system list: the rows are `SidebarRow`s in a scroll view whose
/// content starts below the traffic lights and scrolls beneath them, fading out there. A click selects a tab, a drag reorders them.
package struct TabSidebar: View {
    let tabs: TabsModel
    let settings: ShellSettings
    /// The pin button was pressed: the sidebar is to stay beside the content, or to hide and float (`sidebar.autoHide`, which the app owns).
    let togglePin: () -> Void
    /// The floating panel: its traffic lights are a little further from the corner.
    var floating = false
    /// The floating panel's corner radius: the pin button's corner towards the panel's is concentric with it (same gap to both edges).
    var panelRadius: Double?
    /// What the app puts at the top, under the window's buttons (the address of the focused page, web step b).
    var accessory: AnyView?
    /// What the app puts at the bottom, against the window's edge (the + button and downloads, R2 and web step f).
    var bottomBar: AnyView?
    @State private var rowDrop: (item: Workspace.ItemID, action: TabDropAction)?
    @State private var rowSizes: [Workspace.ItemID: CGSize] = [:]
    @State private var rowFrames: [Workspace.ItemID: CGRect] = [:]
    /// Index of the row whose close button was just clicked, while the pointer remains inside the sidebar (`n27`).
    @State private var closingSlot: Int?
    @Environment(\.accent) private var accentStyle

    var margin: Double { settings.sidebar.padding }
    /// The metrics the tabs draw with: the docked ones, or the floating panel's own.
    var layout: ShellSettings.Layout { floating ? settings.layout.floatingTabs : settings.layout }
    var header: SidebarHeader { SidebarHeader(layout: layout, margin: margin, floating: floating) }
    /// Where the rows start: below the window's buttons, and the accessory with a gap.
    private var topInset: Double { header.height + accessoryInset }

    package init(
        tabs: TabsModel,
        settings: ShellSettings,
        floating: Bool = false,
        panelRadius: Double? = nil,
        accessory: AnyView? = nil,
        bottomBar: AnyView? = nil,
        togglePin: @escaping () -> Void
    ) {
        self.accessory = accessory
        self.bottomBar = bottomBar
        self.tabs = tabs
        self.settings = settings
        self.floating = floating
        self.panelRadius = panelRadius
        self.togglePin = togglePin
    }

    package var body: some View {
        ScrollView {
            LazyVStack(spacing: layout.tabSpacing) {
                FavoritesSection(tabs: tabs, settings: settings, layout: layout)
                ForEach(tabs.workspace.items) { item in row(item) }
            }
            .padding(.horizontal, layout.tabSideInset)
            .frame(maxWidth: .infinity)
        }
        .gesture(WindowDragGesture())
        // On the sidebar's empty area (a row's own menu wins over it).
        .contextMenu {
            Button("New Folder") { tabs.newFolder() }
            Button("New Tab") { tabs.newTab() }
        }
        .scrollIndicators(.never)
        .modifier(EscapeClearsMarks(tabs: tabs))
        .contentMargins(.top, topInset, for: .scrollContent)
        .contentMargins(.bottom, margin + bottomInset, for: .scrollContent)
        .onHover { inside in if !inside { closingSlot = nil } }
        .mask { fade }
        .overlay(alignment: settings.sidebar.side == .left ? .topTrailing : .topLeading) { pinButton }
        .overlay(alignment: .top) { accessoryView }
        .overlay(alignment: .bottom) { bottomBarView }
    }

    /// Content that scrolls up past the traffic lights fades out over the height of the strip they sit in; rows at rest start below it, untouched.
    private var fade: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: max(topInset - 4, 0))
            Color.black
            // And under the bottom bar.
            if bottomBar != nil {
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: bottomInset + margin)
            }
        }
    }

    @ViewBuilder private func rowContent(_ item: Workspace.Item) -> some View {
        let armed = tabs.isCloseArmed(item.id)
        if item.isSplit {
            SidebarGroupRow(
                item: item,
                tabs: tabs,
                selected: tabs.isSelected(item.id),
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
                showIcon: settings.tabs.bar.showIcon,
                showTitle: settings.tabs.bar.showTitle,
                showDirectory: settings.tabs.bar.showDirectory,
                showProgress: settings.tabs.bar.showProgress,
                layout: layout,
                marked: tabs.isMarked(.tab(item.id)),
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

    private func row(_ item: Workspace.Item) -> some View {
        rowContent(item)
            .onGeometryChange(for: CGSize.self, of: \.size) { rowSizes[item.id] = $0 }
            .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { rowFrames[item.id] = $0 }
            .overlay {
                if rowDrop?.item == item.id, let action = rowDrop?.action {
                    rowDropOverlay(action)
                }
            }
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
            .onTapGesture(count: 2) { tabs.renamingRow = .tab(item.id) }
            .selectionTaps(tabs, row: .tab(item.id)) { tabs.select(item: item.id) }
            .iconPopover(tabs: tabs, row: .tab(item.id))
            .onDrag { tabs.itemProvider(for: .item(item.id)) }
            .onDrop(
                of: [.plainText, .utf8PlainText],
                delegate: TabRowDropDelegate(
                    tabs: tabs,
                    item: item.id,
                    size: rowSizes[item.id] ?? CGSize(width: 180, height: 32),
                    active: $rowDrop
                )
            )
            .contextMenu {
                SelectionMenu(tabs: tabs, row: .tab(item.id))
                Button("Rename") { tabs.renamingRow = .tab(item.id) }
                Button("Change Icon\u{2026}") { tabs.iconRow = .tab(item.id) }
                Button("Add to Favorites") { tabs.keep(item: item.id) }
                Button("New Folder with This Tab") { tabs.newFolder(with: item.id) }
                Button("Close Tab") { tabs.close(item: item.id) }
                Button("Close Other Tabs") { tabs.closeOthers(than: item.id) }
                    .disabled(tabs.workspace.count < 2)
            }
    }

    /// The in-place name of a row while it is being renamed.
    private func renaming(_ row: RowTarget) -> (start: String, done: (String?) -> Void)? {
        guard tabs.renamingRow == row else { return nil }
        return (
            tabs.name(of: row), { name in if let name { tabs.rename(row, to: name) } else { tabs.renamingRow = nil } }
        )
    }

    /// Pins the sidebar beside the terminal (`sidebar.autoHide` off) or lets it hide and float: the sidebar symbol, filled while the sidebar is open
    /// (pinned) and outlined while it only appears on hover. Its container is a rounded square the size of the hit box, highlighted under the pointer like a
    /// tab, with its trailing edge on the tabs' trailing edge and its middle on the traffic lights'.
    /// Shows what dropping on this row will do: an insertion line at the top or bottom edge for reordering, or a left/right half highlight for splitting.
    @ViewBuilder private func rowDropOverlay(_ action: TabDropAction) -> some View {
        let accent = accentStyle.color
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        switch action {
            case .moveBefore:
                VStack {
                    Capsule().fill(accent).frame(height: 2)
                    Spacer(minLength: 0)
                }
                .allowsHitTesting(false)
            case .moveAfter:
                VStack {
                    Spacer(minLength: 0)
                    Capsule().fill(accent).frame(height: 2)
                }
                .allowsHitTesting(false)
            case .split(let edge):
                GeometryReader { proxy in
                    let half = proxy.size.width / 2
                    shape.fill(accent.opacity(Design.Fill.target))
                        .overlay { shape.strokeBorder(accent.opacity(Design.Fill.armedButton), lineWidth: 1.5) }
                        .frame(width: half, height: proxy.size.height)
                        .offset(x: edge == .right ? half : 0)
                }
                .allowsHitTesting(false)
        }
    }
}
