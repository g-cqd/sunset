import Foundation
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Mock-ups for sections in the sidebars: the switch between History, Documents and the rest, in the panel opposite the
/// tabs and in the tab sidebar itself. Drawn with plain shapes to choose from; nothing is built.
extension DesignCatalogTests {
    static let sectionGlyphs = ["clock", "doc.text", "arrow.down.circle"]
    static let sidebarGlyphs = ["rectangle.stack", "doc.text", "clock"]

    func sectionTitle(_ title: String, menu: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(title).font(.system(size: 13, weight: .semibold))
            if menu {
                Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "sidebar.left").font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8).frame(height: 26)
    }

    func sectionField(_ placeholder: String) -> some View {
        Text(placeholder).font(.system(size: 12)).foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8).frame(height: 24)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.primary.opacity(0.08)))
    }

    /// A row of glyphs, one filled: the switch. `wide` spreads them over the width, as a segmented control does.
    func sectionSwitch(_ glyphs: [String], selected: Int, wide: Bool = true) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(glyphs.enumerated()), id: \.offset) { index, glyph in
                Image(systemName: glyph).font(.system(size: 12))
                    .foregroundStyle(index == selected ? .primary : .secondary)
                    .frame(maxWidth: wide ? .infinity : 28).frame(height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(.primary.opacity(index == selected ? 0.16 : 0))
                    )
            }
            if !wide { Spacer(minLength: 0) }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.primary.opacity(wide ? 0.06 : 0)))
    }

    func sectionDay(_ title: String) -> some View {
        Text(title).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 8).frame(height: 20)
    }

    @ViewBuilder var sectionHistory: some View {
        sectionDay("Today")
        documentRow("Swift Forums", "globe", DocumentRowLook(second: "forums.swift.org"))
        documentRow("Example Domain", "globe", DocumentRowLook(second: "example.com"))
        sectionDay("Yesterday")
        documentRow("WebKit", "globe", DocumentRowLook(second: "webkit.org"))
    }

    @ViewBuilder var sectionDocuments: some View {
        sectionDay("Today")
        documentRow("Harbour notes", "doc.text", DocumentRowLook(second: "14:02"))
        sectionDay("Yesterday")
        documentRow("Release plan", "doc.text", DocumentRowLook(second: "18:40"))
        sectionDay("Earlier")
        documentRow("Login flow", "flowchart", DocumentRowLook(second: "12 November"))
    }

    /// The menu a sort button opens.
    var sectionSortMenu: AnyView {
        let names = ["Last changed", "Last created", "Name", "Kind", "Open First"]
        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).opacity(index == 0 ? 1 : 0)
                        Text(name).font(.system(size: 13))
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8).frame(height: 24)
                }
            }
            .padding(4).frame(width: 150)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color(white: 0.2)))
        )
    }

    func sectionPanel(_ index: Int, documents: Bool) -> AnyView {
        let title = documents ? "Documents" : "History"
        let selected = documents ? 1 : 0
        return documentSidebar {
            sectionTitle(title, menu: index == 0)
            if index == 1 { sectionSwitch(Self.sectionGlyphs, selected: selected) }
            sectionField("Search \(title)")
            if documents { sectionDocuments } else { sectionHistory }
            if index == 2 {
                documentLine
                sectionSwitch(Self.sectionGlyphs, selected: selected, wide: false)
            }
        }
    }

    var sectionsOpposite: CatalogSheet {
        let titles = ["P1 the title is a menu", "P2 a switch under the title", "P3 glyphs at the bottom"]
        return CatalogSheet(
            title: "The panel opposite the tabs, with sections (mock-up, 0031)",
            note:
                "Today this panel is the history only. Sections here: History, Documents, Downloads. P1: a click on the title "
                + "opens a menu of the sections. P2: a segmented row of glyphs under the title. P3: the glyphs at the bottom, "
                + "where Arc has its Library icon (its help centre; not looked at on screen). Each lists by day, as the history does.",
            columns: titles.enumerated()
                .map { index, title in
                    .init(
                        title: title,
                        examples: [
                            .init(label: "History", view: sectionPanel(index, documents: false)),
                            .init(label: "Documents", view: sectionPanel(index, documents: true))
                        ]
                    )
                },
            width: 221
        )
    }

    var sectionsSidebar: CatalogSheet {
        CatalogSheet(
            title: "The tab sidebar, with the documents (mock-up, 0031)",
            note:
                "S1: what you chose at ST-5: a Documents heading between the Favorites and the tabs, which a setting hides. S2: the "
                + "sidebar has the switch (Tabs, Documents, History) and shows one section at a time; the opposite panel is then "
                + "not needed. S3: as S2 with the switch at the bottom, beside the +. The menu is what the sort button of a "
                + "Documents list opens.",
            columns: [
                .init(
                    title: "S1 a heading among the tabs",
                    examples: [
                        .init(
                            label: "",
                            view: documentSidebar {
                                documentFavorites
                                documentLine
                                documentHeader("Documents")
                                documentList()
                                documentLine
                                documentTabs()
                            }
                        )
                    ]
                ),
                .init(
                    title: "S2 a switch at the top",
                    examples: [
                        .init(
                            label: "Tabs",
                            view: documentSidebar {
                                sectionSwitch(Self.sidebarGlyphs, selected: 0)
                                documentFavorites
                                documentLine
                                documentTabs()
                            }
                        ),
                        .init(
                            label: "Documents",
                            view: documentSidebar {
                                sectionSwitch(Self.sidebarGlyphs, selected: 1)
                                sectionField("Search Documents")
                                sectionDocuments
                            }
                        )
                    ]
                ),
                .init(
                    title: "S3 a switch at the bottom",
                    examples: [
                        .init(
                            label: "Documents",
                            view: documentSidebar {
                                sectionField("Search Documents")
                                sectionDocuments
                                documentLine
                                HStack(spacing: 0) {
                                    sectionSwitch(Self.sidebarGlyphs, selected: 1, wide: false)
                                    Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.secondary).frame(width: 24, height: 22)
                                }
                            }
                        ), .init(label: "sorting", view: sectionSortMenu)
                    ]
                )
            ],
            width: 221
        )
    }

    @Test func `the sections of the sidebars, drawn to choose from`() throws {
        guard let folder = ProcessInfo.processInfo.environment["SUNSET_CATALOG"].map({ URL(fileURLWithPath: $0) })
        else { return }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        #expect(sectionsOpposite.write(to: folder.appending(path: "sections-opposite.png")))
        #expect(sectionsSidebar.write(to: folder.appending(path: "sections-sidebar.png")))
    }
}
