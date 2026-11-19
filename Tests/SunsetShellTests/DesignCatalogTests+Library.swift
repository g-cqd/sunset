import Foundation
import SwiftUI
import Testing

@testable import SunsetShell

/// Mock-ups of the Library of the tab sidebar (roadmap 0031, the owner on 2026-11-15): the sidebar's foot keeps its middle
/// for spaces, later; a Library glyph opposite the + extends the sidebar into a variant whose content is chosen by tabs laid
/// out vertically. Drawn with plain shapes for the owner to choose from; nothing is built.
extension DesignCatalogTests {
    /// How the Library's vertical tabs are drawn.
    enum LibraryLook: CaseIterable {
        case tiles, rail, railInside

        var title: String {
            switch self {
                case .tiles: "L1 tiles with names, as Arc"
                case .rail: "L2 a rail of glyphs"
                case .railInside: "L3 a rail, the sidebar keeps its width"
            }
        }

        var stripWidth: Double {
            self == .tiles ? 76 : 30
        }
        var contentWidth: Double {
            self == .railInside ? 221 - 30 - 5 : 221
        }
    }

    static let librarySections: [(String, String)] = [
        ("doc.text", "Documents"), ("clock", "History"), ("arrow.down.circle", "Downloads")
    ]

    /// The foot of the tab sidebar: the Library, room for spaces, the +.
    func libraryFoot(open: Bool = false) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "books.vertical").font(.system(size: 12))
                .foregroundStyle(open ? .primary : .secondary)
                .frame(width: 24, height: 22).background(footFill(open))
            Spacer(minLength: 0)
            HStack(spacing: 7) {
                ForEach(0 ..< 4, id: \.self) { index in
                    Circle().fill(.primary.opacity(index == 0 ? 0.5 : 0.18)).frame(width: 4, height: 4)
                }
            }
            Spacer(minLength: 0)
            footPlus
        }
    }

    @ViewBuilder
    func libraryTab(_ section: (String, String), shown: Bool, look: LibraryLook) -> some View {
        if look == .tiles {
            VStack(spacing: 4) {
                footGlyph(section.0, shown: shown, size: 15)
                Text(section.1).font(.system(size: 9, weight: .medium)).foregroundStyle(shown ? .primary : .secondary)
            }
            .frame(width: look.stripWidth, height: 50).background(footFill(shown, radius: 8))
        } else {
            footGlyph(section.0, shown: shown, size: 13).frame(width: 26, height: 26)
                .background(footFill(shown, radius: 6))
        }
    }

    /// The vertical tabs, with the way back to the tabs at their foot.
    func libraryStrip(shown: Int, look: LibraryLook) -> some View {
        VStack(spacing: look == .tiles ? 6 : 4) {
            ForEach(Array(Self.librarySections.enumerated()), id: \.offset) { index, section in
                libraryTab(section, shown: index == shown, look: look)
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.left").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                .frame(width: 24, height: 22)
        }
        .frame(width: look.stripWidth)
    }

    func library(_ look: LibraryLook, shown: Int) -> AnyView {
        let title = Self.librarySections[shown].1
        return AnyView(
            HStack(alignment: .top, spacing: 5) {
                libraryStrip(shown: shown, look: look)
                Rectangle().fill(.primary.opacity(0.12)).frame(width: 0.5)
                VStack(spacing: 4) {
                    sectionTitle(title)
                    sectionField("Search \(title)")
                    if shown == 0 { sectionDocuments } else { sectionHistory }
                }
                .frame(width: look.contentWidth)
            }
            .fixedSize()
            .padding(4).background(Color(white: 0.09))
        )
    }

    var libraryAtRest: AnyView {
        AnyView(
            documentSidebar {
                documentFavorites
                documentLine
                documentTabs()
                documentLine
                libraryFoot()
            }
            .frame(width: 221)
        )
    }

    var libraryOpposite: AnyView {
        AnyView(footPanel(.segmented, shown: 0).frame(width: 221))
    }

    var librarySheet: CatalogSheet {
        CatalogSheet(
            title: "The Library of the tab sidebar (mock-up, 0031)",
            note:
                "The foot of the tab sidebar keeps its middle for spaces, later (the dots): a Library glyph at one end, the + at "
                + "the other. The Library glyph extends the sidebar: tabs laid out vertically choose what it shows, an arrow "
                + "at their foot goes back to the tabs. L1: tiles with their names, as Arc's Library (looked at on screen). "
                + "L2: a rail of glyphs, the sidebar grows by the rail only. L3: the same rail, the sidebar keeps its width "
                + "and the list is narrower. Only the opposite panel has its switch at its foot (B6).",
            columns: [
                .init(
                    title: "At rest, and the opposite panel",
                    examples: [
                        .init(label: "the tab sidebar", view: libraryAtRest),
                        .init(label: "the opposite panel (B6)", view: libraryOpposite)
                    ]
                )
            ]
                + LibraryLook.allCases.map { look in
                    .init(
                        title: look.title,
                        examples: [
                            .init(label: "Documents", view: library(look, shown: 0)),
                            .init(label: "History", view: library(look, shown: 1))
                        ]
                    )
                },
            width: 320
        )
    }

    @Test func `the Library of the tab sidebar, drawn for the owner`() throws {
        guard let folder = ProcessInfo.processInfo.environment["SUNSET_CATALOG"].map({ URL(fileURLWithPath: $0) })
        else { return }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        #expect(librarySheet.write(to: folder.appending(path: "sections-library.png")))
    }
}
