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
    @State private var rowDrop: (item: Workspace.ItemID, action: TabDropAction)?
    @State private var rowSizes: [Workspace.ItemID: CGSize] = [:]
    /// Index of the row whose close button was just clicked, while the pointer remains inside the sidebar (`n27`).
    @State private var closingSlot: Int?

    private var margin: Double { settings.sidebar.padding }
    /// The metrics the tabs draw with: the docked ones, or the floating panel's own.
    private var layout: ShellSettings.Layout { floating ? settings.layout.floatingTabs : settings.layout }
    private var header: SidebarHeader { SidebarHeader(layout: layout, margin: margin, floating: floating) }
    private var topInset: Double { header.height }

    package init(
        tabs: TabsModel,
        settings: ShellSettings,
        floating: Bool = false,
        panelRadius: Double? = nil,
        togglePin: @escaping () -> Void
    ) {
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
        .scrollIndicators(.never)
        .contentMargins(.top, topInset, for: .scrollContent)
        .contentMargins(.bottom, margin, for: .scrollContent)
        .onHover { inside in if !inside { closingSlot = nil } }
        .mask { fade }
        .overlay(alignment: settings.sidebar.side == .left ? .topTrailing : .topLeading) { pinButton }
    }

    /// Content that scrolls up past the traffic lights fades out over the height of the strip they sit in; rows at rest start below it, untouched.
    private var fade: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: max(topInset - 4, 0))
            Color.black
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
                } else if tabs.hoveredItem == item.id {
                    tabs.hoveredItem = nil
                }
            }
            .onTapGesture { tabs.select(item: item.id) }
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
                Button("Rename Tab…") { tabs.beginRename(item: item.id) }
                Button("Add to Favorites") { tabs.keep(item: item.id) }
                Button("Close Tab") { tabs.close(item: item.id) }
                Button("Close Other Tabs") { tabs.closeOthers(than: item.id) }
                    .disabled(tabs.workspace.count < 2)
            }
    }

    /// Pins the sidebar beside the terminal (`sidebar.autoHide` off) or lets it hide and float: the sidebar symbol, filled while the sidebar is open
    /// (pinned) and outlined while it only appears on hover. Its container is a rounded square the size of the hit box, highlighted under the pointer like a
    /// tab, with its trailing edge on the tabs' trailing edge and its middle on the traffic lights'.
    private var pinButton: some View {
        PinButton(
            pinned: !settings.sidebar.autoHide,
            layout: layout,
            radius: pinRadius,
            size: panelRadius == nil ? CGSize(width: header.dockedButtonSize, height: header.dockedButtonHeight) : nil
        ) {
            togglePin()
        }
        .padding(
            settings.sidebar.side == .left ? .trailing : .leading,
            pinGap + (panelRadius == nil ? header.dockedButtonInset : 0)
        )
        .padding(.top, panelRadius == nil ? header.dockedButtonInset : header.buttonTop)
    }

    /// The pin button's distance from the panel's top and from its edge: the same, so that their corners share a centre (docked: the container is flush with the terminal card's top and with the tabs' edge).
    private var pinGap: Double { panelRadius == nil ? layout.tabSideInset : header.buttonTop }
    private var pinRadius: Double {
        guard let panelRadius else { return layout.pinButtonRadius }
        return ConcentricRadius.inner(outer: panelRadius, inset: pinGap)
    }

    /// Shows what dropping on this row will do: an insertion line at the top or bottom edge for reordering, or a left/right half highlight for splitting.
    @ViewBuilder private func rowDropOverlay(_ action: TabDropAction) -> some View {
        let accent = Color(nsColor: .controlAccentColor)
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
                    shape.fill(accent.opacity(0.22))
                        .overlay { shape.strokeBorder(accent.opacity(0.75), lineWidth: 1.5) }
                        .frame(width: half, height: proxy.size.height)
                        .offset(x: edge == .right ? half : 0)
                }
                .allowsHitTesting(false)
        }
    }
}
