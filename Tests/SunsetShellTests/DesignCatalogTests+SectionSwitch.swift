import Foundation
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Mock-ups of the switch at the foot of a sidebar: six looks for the row of sections, then how it sits with the + of
/// the tab sidebar. Drawn with plain shapes to choose from; nothing is built.
extension DesignCatalogTests {
    /// How a foot's switch is drawn.
    enum FootLook: CaseIterable {
        case leading, spread, dots, labelled, pill, segmented

        var title: String {
            switch self {
                case .leading: "B1 glyphs at the leading end"
                case .spread: "B2 glyphs across the width"
                case .dots: "B3 a dot under the one shown"
                case .labelled: "B4 glyphs with names"
                case .pill: "B5 the one shown says its name"
                case .segmented: "B6 a segmented control"
            }
        }
    }

    static let footSections: [(String, String)] = [
        ("clock", "History"), ("doc.text", "Documents"), ("arrow.down.circle", "Downloads")
    ]
    static let footSidebarSections: [(String, String)] = [
        ("rectangle.stack", "Tabs"), ("doc.text", "Documents"), ("clock", "History"), ("arrow.down.circle", "Downloads")
    ]

    func footGlyph(_ name: String, shown: Bool, size: Double = 12) -> some View {
        Image(systemName: name).font(.system(size: size)).foregroundStyle(shown ? .primary : .secondary)
    }

    func footFill(_ shown: Bool, radius: Double = 5) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous).fill(.primary.opacity(shown ? 0.16 : 0))
    }

    @ViewBuilder
    func footCell(_ section: (String, String), shown: Bool, look: FootLook) -> some View {
        switch look {
            case .leading:
                footGlyph(section.0, shown: shown).frame(width: 28, height: 22).background(footFill(shown))
            case .spread, .segmented:
                footGlyph(section.0, shown: shown).frame(maxWidth: .infinity).frame(height: 22)
                    .background(footFill(shown))
            case .dots:
                VStack(spacing: 4) {
                    footGlyph(section.0, shown: shown)
                    Circle().fill(.primary.opacity(shown ? 0.9 : 0)).frame(width: 3, height: 3)
                }
                .frame(maxWidth: .infinity).frame(height: 30)
            case .labelled:
                VStack(spacing: 2) {
                    footGlyph(section.0, shown: shown, size: 13)
                    Text(section.1).font(.system(size: 9)).foregroundStyle(shown ? .primary : .secondary).lineLimit(1)
                }
                .frame(maxWidth: .infinity).frame(height: 34).background(footFill(shown, radius: 6))
            case .pill:
                HStack(spacing: 4) {
                    footGlyph(section.0, shown: shown)
                    if shown { Text(section.1).font(.system(size: 11, weight: .medium)).fixedSize() }
                }
                .padding(.horizontal, 7).frame(height: 22).background(footFill(shown, radius: 11))
        }
    }

    /// The row of sections at a sidebar's foot.
    func foot(_ sections: [(String, String)], shown: Int, look: FootLook) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                footCell(section, shown: index == shown, look: look)
            }
            if look == .leading || look == .pill { Spacer(minLength: 0) }
        }
        .padding(look == .segmented ? 2 : 0)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.primary.opacity(look == .segmented ? 0.06 : 0))
        )
    }

    func footPanel(_ look: FootLook, shown: Int) -> AnyView {
        let title = Self.footSections[shown].1
        return documentSidebar {
            sectionTitle(title)
            sectionField("Search \(title)")
            if shown == 1 { sectionDocuments } else { sectionHistory }
            if look != .dots { documentLine }
            foot(Self.footSections, shown: shown, look: look)
        }
    }

    var footPlus: some View {
        Image(systemName: "plus").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            .frame(width: 24, height: 22)
    }

    /// The tab sidebar with the switch at its foot; the + is where it is today (`plusLeading`) or at the other end.
    func footSidebar(_ look: FootLook, shown: Int, plusLeading: Bool) -> AnyView {
        documentSidebar {
            if shown == 0 {
                documentFavorites
                documentLine
                documentTabs()
            } else {
                sectionField("Search Documents")
                sectionDocuments
            }
            documentLine
            HStack(spacing: 4) {
                if plusLeading { footPlus }
                foot(Self.footSidebarSections, shown: shown, look: look)
                if !plusLeading { footPlus }
            }
        }
    }

    var sectionFeet: CatalogSheet {
        CatalogSheet(
            title: "The switch at the foot of the opposite panel: six looks (mock-up, 0031)",
            note:
                "Sections: History, Documents, Downloads. B1: small glyphs at the leading end, the one shown filled. B2: the same "
                + "spread over the width. B3: no fill, a dot under the one shown, no line above. B4: each glyph with its name, a "
                + "taller row. B5: only the one shown says its name, in a capsule. B6: the system's segmented look, in a "
                + "trough. Every glyph has its name as a tooltip and to VoiceOver in all six.",
            columns: FootLook.allCases.map { look in
                .init(
                    title: look.title,
                    examples: [
                        .init(label: "History", view: footPanel(look, shown: 0)),
                        .init(label: "Documents", view: footPanel(look, shown: 1))
                    ]
                )
            },
            width: 221
        )
    }

    var sectionFeetSidebar: CatalogSheet {
        let looks: [(String, FootLook, Bool)] = [
            ("T1 + first, then glyphs (B1)", .leading, true), ("T2 glyphs, + at the end (B1)", .leading, false),
            ("T3 the one shown says its name (B5)", .pill, false), ("T4 a dot under the one shown (B3)", .dots, true),
            ("T5 segmented (B6), + at the end", .segmented, false)
        ]
        return CatalogSheet(
            title: "The same switch at the foot of the tab sidebar, with the + (mock-up, 0031)",
            note:
                "Only when the setting puts the switch in the tab sidebar. Sections: Tabs, Documents, History, Downloads. The + "
                + "is at the leading end of the foot today (T1, T4); T2, T3 and T5 move it to the other end so the switch "
                + "starts where the eye does. Under Documents the + makes a document; under Tabs, a tab.",
            columns: looks.map { title, look, plusLeading in
                .init(
                    title: title,
                    examples: [
                        .init(label: "Tabs", view: footSidebar(look, shown: 0, plusLeading: plusLeading)),
                        .init(label: "Documents", view: footSidebar(look, shown: 1, plusLeading: plusLeading))
                    ]
                )
            },
            width: 221
        )
    }

    @Test func `the switch at a sidebar's foot, drawn to choose from`() throws {
        guard let folder = ProcessInfo.processInfo.environment["SUNSET_CATALOG"].map({ URL(fileURLWithPath: $0) })
        else { return }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        #expect(sectionFeet.write(to: folder.appending(path: "sections-foot.png")))
        #expect(sectionFeetSidebar.write(to: folder.appending(path: "sections-foot-sidebar.png")))
    }
}
