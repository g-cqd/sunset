import SwiftUI

@testable import SunsetShell

/// Round 4 of the review: a folder row with its disclosure mark at the trailing edge (where a tab's close button is, on hover), the mark's
/// variants; symbols for a kept terminal that runs a command (no initial); the folder's initial at 6.5 pt, 1.75 pt down.
extension DesignCatalogTests {
    /// A folder row as it would be: the folder (filled when expanded), the name, the mark in the close button's 20 pt square 6 from the edges.
    private func folderRow(_ mark: (Bool) -> AnyView, expanded: Bool, hover: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: expanded ? "folder.fill" : "folder").font(.system(size: 13)).frame(width: 18, height: 18)
            Text("Projects").font(.system(size: 13)).lineLimit(1)
            Spacer(minLength: 0)
            mark(expanded).frame(width: 20, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous).fill(.primary.opacity(hover ? 0.1 : 0))
                )
                .opacity(hover ? 1 : 0)
        }
        .padding(.leading, 8).padding(.trailing, 4)
        .frame(height: 28)
        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.primary.opacity(hover ? 0.07 : 0)))
    }

    private func symbolMark(_ collapsed: String, _ expanded: String, size: Double = 9, weight: Font.Weight = .semibold)
        -> (Bool) -> AnyView
    {
        { open in AnyView(Image(systemName: open ? expanded : collapsed).font(.system(size: size, weight: weight))) }
    }

    /// One chevron that turns a quarter (drawn at both ends of the turn).
    private var turningChevron: (Bool) -> AnyView {
        { open in
            AnyView(
                Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold))
                    .rotationEffect(.degrees(open ? 90 : 0))
            )
        }
    }

    var disclosure: CatalogSheet {
        let marks: [(String, (Bool) -> AnyView)] = [
            ("A chevron turns", turningChevron),
            ("B chevron up/down", symbolMark("chevron.down", "chevron.up")),
            ("C compact chevron", symbolMark("chevron.compact.down", "chevron.compact.up", size: 11, weight: .bold)),
            ("D plus / minus", symbolMark("plus", "minus")),
            (
                "E arrows apart / together",
                symbolMark(
                    "arrow.up.and.line.horizontal.and.arrow.down",
                    "arrow.down.and.line.horizontal.and.arrow.up",
                    size: 10
                )
            ),
            (
                "F expand / collapse",
                symbolMark("arrow.up.left.and.arrow.down.right", "arrow.down.right.and.arrow.up.left")
            ),
            ("G triangle", symbolMark("arrowtriangle.right.fill", "arrowtriangle.down.fill", size: 8)),
            (
                "H rectangles",
                symbolMark("rectangle.expand.vertical", "rectangle.compress.vertical", size: 11, weight: .regular)
            )
        ]
        func column(_ name: String, _ mark: @escaping (Bool) -> AnyView) -> CatalogSheet.Column {
            func row(_ expanded: Bool, _ hover: Bool) -> AnyView {
                AnyView(
                    folderRow(mark, expanded: expanded, hover: hover).padding(.horizontal, 2)
                        .background(Color(white: 0.09))
                )
            }
            return .init(
                title: name,
                examples: [
                    .init(label: "collapsed", view: row(false, false)),
                    .init(label: "collapsed, hover", view: row(false, true)),
                    .init(label: "expanded, hover", view: row(true, true))
                ]
            )
        }
        return CatalogSheet(
            title: "Folders: the disclosure mark at the trailing edge, on hover",
            note:
                "Variant F of round 3 (the folder fills when expanded) with the mark where a tab's close button is: a 20 pt square 4 from "
                + "the trailing edge of a 28 pt row, shown on hover; a click on it opens or closes the folder, as a click on the row does. "
                + "\"collapsed\" shows the row at rest (no mark). A turns one chevron a quarter (animated between); the rest swap symbols.",
            columns: marks.prefix(4).map { column($0.0, $0.1) },
            width: 221
        )
    }

    var disclosureMore: CatalogSheet {
        let marks: [(String, (Bool) -> AnyView)] = [
            (
                "E arrows apart / together",
                symbolMark(
                    "arrow.up.and.line.horizontal.and.arrow.down",
                    "arrow.down.and.line.horizontal.and.arrow.up",
                    size: 10
                )
            ),
            (
                "F expand / collapse",
                symbolMark("arrow.up.left.and.arrow.down.right", "arrow.down.right.and.arrow.up.left")
            ),
            ("G triangle", symbolMark("arrowtriangle.right.fill", "arrowtriangle.down.fill", size: 8)),
            (
                "H rectangles",
                symbolMark("rectangle.expand.vertical", "rectangle.compress.vertical", size: 11, weight: .regular)
            )
        ]
        return CatalogSheet(
            title: "Folders: the disclosure mark, more variants",
            note: "Same row; other marks.",
            columns: marks.map { name, mark in
                .init(
                    title: name,
                    examples: [false, true]
                        .map { expanded in
                            .init(
                                label: expanded ? "expanded, hover" : "collapsed, hover",
                                view: AnyView(
                                    folderRow(mark, expanded: expanded, hover: true).padding(.horizontal, 2)
                                        .background(Color(white: 0.09))
                                )
                            )
                        }
                )
            },
            width: 221
        )
    }

    var commandSymbols: CatalogSheet {
        let names = [
            "apple.terminal", "apple.terminal.fill", "terminal.fill", "play.rectangle", "play.square", "bolt",
            "bolt.horizontal",
            "hammer", "gearshape.2", "curlybraces.square", "greaterthan.square", "chevron.forward.2", "command.square",
            "arrow.triangle.2.circlepath"
        ]
        func row(_ name: String) -> AnyView {
            AnyView(
                HStack(spacing: 7) {
                    Image(systemName: name).font(.system(size: 13)).frame(width: 18, height: 18)
                    Text("npm run dev").font(.system(size: 13))
                    Spacer(minLength: 0)
                    Text(name).font(.caption2.monospaced()).foregroundStyle(.secondary)
                }
                .padding(.leading, 8).padding(.trailing, 6).frame(height: 28).background(Color(white: 0.09))
            )
        }
        let folderGlyph = AnyView(
            HStack(spacing: 18) {
                ZStack {
                    Image(systemName: "folder").font(.system(size: 15)).foregroundStyle(.secondary)
                    Text("S").font(.system(size: 6.5, weight: .heavy, design: .rounded)).offset(y: 1.75)
                }
                .frame(width: 18, height: 18).scaleEffect(3).frame(width: 54, height: 54)
                HStack(spacing: 7) {
                    ZStack {
                        Image(systemName: "folder").font(.system(size: 15)).foregroundStyle(.secondary)
                        Text("S").font(.system(size: 6.5, weight: .heavy, design: .rounded)).offset(y: 1.75)
                    }
                    .frame(width: 18, height: 18)
                    Text("sunset").font(.system(size: 13))
                }
            }
        )
        return CatalogSheet(
            title: "A kept terminal that runs a command: symbols with no initial",
            note:
                "The row's glyph and name (the command). And the folder's initial as chosen: 6.5 pt, 1.75 pt down (3× and in a row).",
            columns: [
                .init(title: "Command symbols", examples: names.prefix(7).map { .init(label: "", view: row($0)) }),
                .init(title: "", examples: names.dropFirst(7).map { .init(label: "", view: row($0)) }),
                .init(title: "Folder initial (chosen)", examples: [.init(label: "6.5 pt, +1.75", view: folderGlyph)])
            ],
            width: 300
        )
    }
}
