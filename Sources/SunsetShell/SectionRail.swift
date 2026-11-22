import SunsetMetrics
import SunsetPane
package import SwiftUI

/// The Library's rail: the sections as glyphs laid out vertically on the window's edge side of the sidebar, the one shown
/// filled; Tabs, the first, goes back to the tabs, as does the arrow at its foot, which is where the Library's glyph was.
/// Above the arrow, the gear of the settings.
package struct SectionRail: View {
    let selection: SidebarSection
    /// The Library's lists, from the top: none while the Library is not offered (the gear and the way back are still there).
    var sections = SidebarSection.rail
    let buttons: SidebarButtons
    /// Opens Help: its glyph above the gear; nil, none.
    var help: (() -> Void)?
    /// The downloads' button (the app's), between the gear and the way back while there are downloads: where it is above
    /// the Library's glyph when the Library is closed; nil, none.
    var downloads: AnyView?
    /// The rail is at the window's leading edge: its foot is at that bottom corner, whose button is concentric with it.
    var leading = false
    let choose: (SidebarSection) -> Void

    package init(
        selection: SidebarSection,
        sections: [SidebarSection] = SidebarSection.rail,
        buttons: SidebarButtons,
        leading: Bool = false,
        help: (() -> Void)? = nil,
        downloads: AnyView? = nil,
        choose: @escaping (SidebarSection) -> Void
    ) {
        self.help = help
        self.downloads = downloads
        self.selection = selection
        self.sections = sections
        self.buttons = buttons
        self.leading = leading
        self.choose = choose
    }

    /// The space between the rail and the list beside it.
    package static let gutter = Design.Space.m

    /// How much wider the sidebar is while the rail shows: a button, its gap to the window's edge, and the gutter to the
    /// list. The list keeps the width the tabs have.
    package static func width(_ buttons: SidebarButtons) -> Double {
        buttons.metrics.size.width + buttons.gap + gutter
    }

    /// What the rail's foot holds, from the top.
    package enum Foot: Sendable { case help, settings, downloads, back }

    /// The foot's glyphs, from the top: Help above the gear, the downloads under it, the way back last, at the corner.
    static func foot(hasHelp: Bool, hasDownloads: Bool = false) -> [Foot] {
        (hasHelp ? [.help] : []) + [.settings] + (hasDownloads ? [.downloads] : []) + [.back]
    }

    /// The way back points at the edge the sidebar closes to, at a bar: left for a sidebar on the left, right for one
    /// on the right.
    static func closeSymbol(leading: Bool) -> String {
        leading ? "arrow.left.to.line" : "arrow.right.to.line"
    }

    package var body: some View {
        VStack(spacing: buttons.layout.tabSpacing) {
            ForEach(sections, id: \.self) { section in glyph(section) }
            Spacer(minLength: 0)
            // Help and the settings, above the way back.
            ForEach(Self.foot(hasHelp: help != nil, hasDownloads: downloads != nil), id: \.self) { part in
                switch part {
                    case .help:
                        SidebarIconButton(help: "Help") {
                            help?()
                        } label: {
                            SidebarSymbol(name: PaneDescriptor.helpSymbol, filled: false).foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Help")
                    case .settings: glyph(.settings)
                    case .downloads: downloads
                    case .back:
                        SidebarIconButton(symbol: Self.closeSymbol(leading: leading), help: "Back to the Tabs (Escape)")
                        {
                            choose(.tabs)
                        }
                        .accessibilityLabel("Back to the Tabs")
                        .environment(\.sidebarButtonCorner, leading ? .bottomLeading : .bottomTrailing)
                }
            }
        }
        .environment(\.sidebarButtonMetrics, buttons.metrics)
        .padding(.top, buttons.header.height)
        .padding(.bottom, buttons.bottom)
    }

    private func glyph(_ section: SidebarSection) -> some View {
        SidebarIconButton(help: section.title) {
            choose(section)
        } label: {
            SidebarSymbol(name: section.symbol, filled: false)
                .foregroundStyle(section == selection ? .primary : .secondary)
        }
        .background(
            RoundedRectangle(cornerRadius: buttons.metrics.radius, style: .continuous)
                .fill(.primary.opacity(section == selection ? Design.Fill.selected : 0))
        )
        .accessibilityLabel(section.title)
        .accessibilityAddTraits(section == selection ? .isSelected : [])
    }
}
