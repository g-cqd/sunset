import SwiftUI

@testable import SunsetShell

/// Mock-ups of the guidance's row questions: a prominent look for open entries (regular tabs matching it), a compact tree, the trailing
/// button's inset, split tabs, the monospaced second line, a kept terminal that is not open. Drawn with plain shapes, not `SidebarRow`.
extension DesignCatalogTests {
    enum OpenLook { case today, dot, bar, filled }

    /// One mock row: a glyph, a title, an optional second line, open or not, a close button at an inset.
    func mockRow(
        _ title: String,
        _ symbol: String,
        second: String? = nil,
        open: Bool = true,
        look: OpenLook = .today,
        height: Double = 32,
        closeInset: Double? = nil,
        selected: Bool = false,
        indent: Double = 0,
        mono: Bool = true
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        let dim = look == .today && !open
        let inset = closeInset ?? (height - 20) / 2
        return HStack(spacing: 7) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: symbol).font(.system(size: 13)).frame(width: 18, height: 18)
                if look == .dot, open { Circle().fill(Color.accentColor).frame(width: 6, height: 6).offset(x: 2, y: 2) }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13, weight: look == .bar && open ? .semibold : .regular)).lineLimit(1)
                if let second {
                    Text(second).font(mono ? .caption.monospaced() : .caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "xmark").font(.system(size: 9, weight: .semibold)).frame(width: 20, height: 20)
                .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(.primary.opacity(0.1)))
        }
        .opacity(dim ? 0.45 : 1)
        .padding(.leading, 8 + indent)
        .padding(.trailing, inset)
        .frame(height: height)
        .background(shape.fill(fill(open: open, look: look, selected: selected)))
        .overlay(alignment: .leading) {
            if look == .bar, open {
                Capsule().fill(Color.accentColor).frame(width: 3, height: height - 12).padding(.leading, 2)
            }
        }
        .overlay { if selected { shape.strokeBorder(.primary.opacity(0.12), lineWidth: 0.5) } }
    }

    private func fill(open: Bool, look: OpenLook, selected: Bool) -> Color {
        if selected { return .primary.opacity(0.14) }
        if look == .filled, open { return .primary.opacity(0.06) }
        return .clear
    }

    private func tree(_ look: OpenLook, compact: Bool = false) -> AnyView {
        let rowHeight = compact ? 28.0 : 32
        let spacing = compact ? 2.0 : 4
        return AnyView(
            VStack(spacing: spacing) {
                mockRow(
                    "Projects",
                    "folder.fill",
                    open: false,
                    look: look == .today ? .today : .filled,
                    height: rowHeight
                )
                .opacity(1)
                mockRow("Form", "globe", open: true, look: look, height: rowHeight, indent: 14)
                mockRow("Build", "terminal", open: false, look: look, height: rowHeight, indent: 14)
                mockRow("Notes", "globe", open: false, look: look, height: rowHeight)
                Divider().padding(.vertical, compact ? 2 : 4)
                mockRow("zsh", "terminal", open: true, look: look, height: 32, selected: true)
                mockRow("Example Domain", "globe", open: true, look: look, height: 32)
            }
            .padding(4).background(Color(white: 0.09))
        )
    }

    var tree: CatalogSheet {
        CatalogSheet(
            title: "Open and not-open entries, and a compact tree (mock-up)",
            note:
                "Today a kept entry that is not open is dimmed. Proposals: nothing is dimmed; an open entry (and every tab below, which is "
                + "open by nature) is marked: A an accent dot on its glyph, B an accent bar at its leading edge and a semibold title, C a "
                + "faint fill. The compact tree keeps the tabs' 32 pt rows below the line, and draws Favorites rows 28 tall with a 2 pt gap: "
                + "the whole row stays the hit area.",
            columns: [
                .init(title: "Today", examples: [.init(label: "dimmed", view: tree(.today))]),
                .init(
                    title: "A dot",
                    examples: [
                        .init(label: "", view: tree(.dot)), .init(label: "compact", view: tree(.dot, compact: true))
                    ]
                ),
                .init(
                    title: "B bar",
                    examples: [
                        .init(label: "", view: tree(.bar)), .init(label: "compact", view: tree(.bar, compact: true))
                    ]
                ),
                .init(
                    title: "C fill",
                    examples: [
                        .init(label: "", view: tree(.filled)),
                        .init(label: "compact", view: tree(.filled, compact: true))
                    ]
                )
            ],
            width: 221
        )
    }

    var rowDetails: CatalogSheet {
        func row(_ view: some View) -> AnyView { AnyView(view.padding(4).background(Color(white: 0.09))) }
        return CatalogSheet(
            title: "Row details (mock-up)",
            note:
                "The close button: today 4 pt from the trailing edge in a 32 pt row (6 from top and bottom); proposed 6 on every side. "
                + "The second line: proportional today, monospaced proposed. A kept terminal not open: today a folder and \"Sunset\"; "
                + "proposed its own picture (terminal + initial when it runs a command, folder + initial when it is a shell in a folder) "
                + "and its command or folder name.",
            columns: [
                .init(
                    title: "Close button",
                    examples: [
                        .init(
                            label: "today (4 trailing)",
                            view: row(mockRow("zsh", "terminal", closeInset: 4, selected: true))
                        ),
                        .init(label: "proposed (6 all)", view: row(mockRow("zsh", "terminal", selected: true))),
                        .init(
                            label: "2 lines, proposed",
                            view: row(
                                mockRow("zsh", "terminal", second: "~/Projects/sunset", height: 36, selected: true)
                            )
                        )
                    ]
                ),
                .init(
                    title: "Second line",
                    examples: [
                        .init(
                            label: "today",
                            view: row(
                                mockRow("zsh", "terminal", second: ".../Projects/sunset", height: 36, mono: false)
                            )
                        ),
                        .init(
                            label: "monospaced",
                            view: row(mockRow("zsh", "terminal", second: ".../Projects/sunset", height: 36))
                        ),
                        .init(
                            label: "page, monospaced",
                            view: row(mockRow("Example Domain", "globe", second: "example.com", height: 36))
                        )
                    ]
                ),
                .init(
                    title: "Kept terminal, not open",
                    examples: [
                        .init(label: "today", view: row(mockRow("Sunset", "folder", open: false))),
                        .init(label: "shell in a folder", view: row(initialRow("sunset", "folder", "S"))),
                        .init(label: "runs a command", view: row(initialRow("npm run dev", "terminal", "N")))
                    ]
                )
            ],
            width: 221
        )
    }

    private func initialRow(_ title: String, _ symbol: String, _ initial: String) -> some View {
        HStack(spacing: 7) {
            ZStack {
                Image(systemName: symbol).font(.system(size: 15)).foregroundStyle(.secondary)
                Text(initial).font(.system(size: 7, weight: .heavy, design: .rounded))
                    .offset(y: symbol == "folder" ? 1 : 0)
            }
            .frame(width: 18, height: 18)
            Text(title).font(.system(size: 13)).lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.leading, 8).frame(height: 32)
    }

    var splits: CatalogSheet {
        func sub(_ title: String, _ symbol: String, iconOnly: Bool, focused: Bool) -> some View {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 12)).frame(width: 16, height: 16)
                if !iconOnly { Text(title).font(.system(size: 12)).lineLimit(1) }
            }
            .padding(.horizontal, iconOnly ? 4 : 6).frame(maxWidth: .infinity, minHeight: 24)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous).fill(.primary.opacity(focused ? 0.14 : 0.05))
            )
        }
        func split(inset: Double, iconOnly: Bool, panes: Int = 2) -> AnyView {
            let items = [("zsh", "terminal"), ("example.com", "globe"), ("vim", "terminal")].prefix(panes)
            return AnyView(
                HStack(spacing: inset == 6 ? 4 : 2) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        sub(item.0, item.1, iconOnly: iconOnly, focused: index == 0)
                    }
                }
                .padding(inset)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.primary.opacity(0.14)))
                .padding(4).background(Color(white: 0.09))
            )
        }
        return CatalogSheet(
            title: "Split tabs (mock-up)",
            note:
                "Today the container pads its sub-rows 6. Proposed: 2 (the sub-rows' corner 4 nests in the row's 6 at 2), gaps 2. When a "
                + "sub-row is narrower than its title needs, only its icon (or initial) is shown.",
            columns: [
                .init(
                    title: "Two panes",
                    examples: [
                        .init(label: "today (6)", view: split(inset: 6, iconOnly: false)),
                        .init(label: "proposed (2)", view: split(inset: 2, iconOnly: false))
                    ]
                ),
                .init(
                    title: "Three panes, narrow",
                    examples: [
                        .init(label: "names", view: split(inset: 2, iconOnly: false, panes: 3)),
                        .init(label: "icons only", view: split(inset: 2, iconOnly: true, panes: 3))
                    ]
                )
            ],
            width: 221
        )
    }
}
