import SwiftUI

@testable import SunsetShell

/// Round 3 of the review (owner's answers to round 2): more folder and sidebar symbols, downloads drawn as progress with the symbol itself,
/// the initial's place in a kept terminal's picture, and split sub-rows aligned leading (icon and text) or centred (icon only).
extension DesignCatalogTests {
    private func pair(_ label: String, _ first: String, _ second: String) -> CatalogSheet.Example {
        func cell(_ name: String) -> some View {
            Image(systemName: name).font(.system(size: 13)).frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.primary.opacity(0.1)))
        }
        return CatalogSheet.Example(
            label: label,
            view: AnyView(
                HStack(spacing: 10) {
                    cell(first)
                    Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.tertiary)
                    cell(second)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(first).font(.caption2.monospaced())
                        Text(second).font(.caption2.monospaced())
                    }
                    .foregroundStyle(.secondary)
                }
            )
        )
    }

    /// A folder row of the tree, collapsed or expanded, drawn with a symbol pair (`disclosure`: a chevron before the folder).
    private func folderRow(_ collapsed: String, _ expanded: String, disclosure: Bool, open: Bool) -> some View {
        HStack(spacing: 5) {
            if disclosure {
                Image(systemName: open ? "chevron.down" : "chevron.right").font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary).frame(width: 10)
            }
            Image(systemName: open ? expanded : collapsed).font(.system(size: 13)).frame(width: 18, height: 18)
            Text("Projects").font(.system(size: 13))
            Spacer(minLength: 0)
        }
        .padding(.leading, 8).frame(height: 28)
    }

    var folders: CatalogSheet {
        func rows(_ collapsed: String, _ expanded: String, disclosure: Bool = false) -> AnyView {
            AnyView(
                VStack(spacing: 2) {
                    folderRow(collapsed, expanded, disclosure: disclosure, open: false)
                    folderRow(collapsed, expanded, disclosure: disclosure, open: true)
                }
                .background(Color(white: 0.09))
            )
        }
        return CatalogSheet(
            title: "Folders: collapsed → expanded",
            note:
                "In Apple's apps a tree's folder says collapsed or expanded with a disclosure triangle or chevron beside it (Finder, Xcode, "
                + "Mail), not with the folder's picture; the folder stays the same. E to H follow that. A to D change the picture.",
            columns: [
                .init(
                    title: "The picture changes",
                    examples: [
                        pair("A", "folder", "folder.fill"),
                        .init(label: "A in a row", view: rows("folder", "folder.fill")),
                        pair("B", "folder.badge.plus", "folder.badge.minus"),
                        .init(label: "B in a row", view: rows("folder.badge.plus", "folder.badge.minus")),
                        pair("C", "folder.circle", "folder.circle.fill"),
                        .init(label: "C in a row", view: rows("folder.circle", "folder.circle.fill")),
                        pair("D", "rectangle.compress.vertical", "rectangle.expand.vertical"),
                        .init(
                            label: "D in a row",
                            view: rows("rectangle.compress.vertical", "rectangle.expand.vertical")
                        )
                    ]
                ),
                .init(
                    title: "A disclosure mark beside the folder",
                    examples: [
                        pair("E chevron", "chevron.right", "chevron.down"),
                        .init(label: "E in a row", view: rows("folder", "folder", disclosure: true)),
                        .init(label: "F chevron + fill", view: rows("folder", "folder.fill", disclosure: true)),
                        pair("G triangle", "arrowtriangle.right.fill", "arrowtriangle.down.fill"),
                        pair("H circled", "chevron.right.circle", "chevron.down.circle")
                    ]
                )
            ],
            width: 300
        )
    }

    var sidebars: CatalogSheet {
        CatalogSheet(
            title: "The sidebar button: hides → kept",
            note:
                "Rectangles with an inset part for the sidebar. The kept state is drawn filled (today's convention); each pair reads as "
                + "\"the sidebar comes and goes\" → \"the sidebar stays\". The trailing versions mirror for a sidebar on the right.",
            columns: [
                .init(
                    title: "Pairs",
                    examples: [
                        pair("today", "sidebar.leading", "sidebar.leading"),
                        pair("A", "sidebar.leading", "inset.filled.leadingthird.rectangle"),
                        pair(
                            "B",
                            "inset.filled.leadinghalf.arrow.leading.rectangle",
                            "inset.filled.leadingthird.rectangle"
                        ),
                        pair(
                            "C",
                            "arrowtriangle.backward.inset.filled.leadingthird.rectangle",
                            "inset.filled.leadingthird.rectangle"
                        ),
                        pair("D", "sidebar.squares.leading", "inset.filled.leadingthird.rectangle"),
                        pair("E", "rectangle.leadinghalf.filled", "inset.filled.leadinghalf.rectangle"),
                        pair("F", "rectangle", "inset.filled.leadingthird.rectangle")
                    ]
                )
            ],
            width: 520
        )
    }

    var downloads: CatalogSheet {
        func progress(_ value: Double, native: Bool) -> AnyView {
            if native {
                return AnyView(
                    Image(systemName: "arrow.down.circle", variableValue: value).symbolVariableValueMode(.draw)
                        .font(.system(size: 15))
                )
            }
            return AnyView(
                ZStack {
                    Circle().stroke(.primary.opacity(0.25), lineWidth: 1.3)
                    Circle().trim(from: 0, to: value).stroke(style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "arrow.down").font(.system(size: 8, weight: .semibold))
                }
                .frame(width: 15, height: 15)
            )
        }
        func strip(native: Bool) -> AnyView {
            AnyView(
                HStack(spacing: 16) {
                    ForEach([0, 0.25, 0.5, 0.75, 1.0], id: \.self) { value in
                        VStack(spacing: 4) {
                            progress(value, native: native).frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.primary.opacity(0.1))
                                )
                            Text("\(Int(value * 100))%").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            )
        }
        return CatalogSheet(
            title: "Downloads: at rest, and while downloading",
            note:
                "At rest arrow.down.circle. While downloading, the circle is the progress. A: the symbol's own Variable Draw "
                + "(Image(systemName:variableValue:) with symbolVariableValueMode(.draw), macOS 26): the system draws the circle's "
                + "stroke up to the value, if the symbol has draw layers. B: today's DownloadRing (a trimmed circle around arrow.down). "
                + "Animation between values is the symbol's own (A) or a SwiftUI animation (B).",
            columns: [
                .init(title: "A native Variable Draw", examples: [.init(label: "", view: strip(native: true))]),
                .init(title: "B drawn ring (today)", examples: [.init(label: "", view: strip(native: false))])
            ],
            width: 230
        )
    }

    var initials: CatalogSheet {
        func glyph(_ symbol: String, _ initial: String, offset: Double, size: Double) -> some View {
            ZStack {
                Image(systemName: symbol).font(.system(size: 15)).foregroundStyle(.secondary)
                Text(initial).font(.system(size: size, weight: .heavy, design: .rounded)).offset(y: offset)
            }
            .frame(width: 18, height: 18)
        }
        func line(_ symbol: String, _ initial: String, _ offsets: [Double], size: Double) -> AnyView {
            AnyView(
                HStack(spacing: 18) {
                    ForEach(offsets, id: \.self) { offset in
                        VStack(spacing: 3) {
                            glyph(symbol, initial, offset: offset, size: size).scaleEffect(3)
                                .frame(width: 54, height: 54)
                            Text(offset == 0 ? "centre" : String(format: "+%.1f", offset)).font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            )
        }
        return CatalogSheet(
            title: "The initial in a kept terminal's picture (drawn 3×)",
            note:
                "The folder's body is below its tab, so its optical centre is lower than the symbol's frame: the initial moves down. "
                + "The terminal symbol has its own prompt (>_) inside, which an initial collides with: a plain rounded rectangle "
                + "(the terminal's outline, no prompt) holds the initial instead. Each at a few offsets; sizes 7 (today) and 8.",
            columns: [
                .init(
                    title: "Folder (shell in a folder)",
                    examples: [
                        .init(label: "7 pt", view: line("folder", "S", [0, 1, 1.5, 2], size: 7)),
                        .init(label: "8 pt", view: line("folder", "S", [0, 1, 1.5, 2], size: 8))
                    ]
                ),
                .init(
                    title: "Terminal (runs a command)",
                    examples: [
                        .init(label: "terminal, 7 pt", view: line("terminal", "N", [0, 1], size: 7)),
                        .init(label: "rectangle, 7 pt", view: line("rectangle", "N", [0, 0.5], size: 7)),
                        .init(label: "rectangle, 8 pt", view: line("rectangle", "N", [0, 0.5], size: 8))
                    ]
                )
            ],
            width: 320
        )
    }

    var splitAlignment: CatalogSheet {
        func sub(_ title: String, _ symbol: String, iconOnly: Bool, focused: Bool) -> some View {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 12)).frame(width: 16, height: 16)
                if !iconOnly { Text(title).font(.system(size: 12)).lineLimit(1) }
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 24, alignment: iconOnly ? .center : .leading)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous).fill(.primary.opacity(focused ? 0.14 : 0.05))
            )
        }
        func split(iconOnly: Bool, panes: Int) -> AnyView {
            let items = [("zsh", "terminal"), ("example.com", "globe"), ("vim", "terminal")].prefix(panes)
            return AnyView(
                HStack(spacing: 2) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        sub(item.0, item.1, iconOnly: iconOnly, focused: index == 0)
                    }
                }
                .padding(2)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.primary.opacity(0.14)))
                .padding(4).background(Color(white: 0.09))
            )
        }
        return CatalogSheet(
            title: "Split tabs: alignment",
            note:
                "A sub-row with an icon and its title starts at its leading edge; one that only has room for its icon centres it.",
            columns: [
                .init(
                    title: "Icon and title: leading",
                    examples: [
                        .init(label: "two panes", view: split(iconOnly: false, panes: 2)),
                        .init(label: "three panes", view: split(iconOnly: false, panes: 3))
                    ]
                ),
                .init(
                    title: "Icon only: centred",
                    examples: [
                        .init(label: "three panes", view: split(iconOnly: true, panes: 3))
                    ]
                )
            ],
            width: 221
        )
    }
}
