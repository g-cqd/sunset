import Foundation
import SwiftUI
import Testing

@testable import SunsetShell

/// Mock-ups for the Documents section of the sidebar (roadmap 0030 step ST-5): where it sits, how it is headed, what an open
/// document looks like. Drawn with plain shapes for the owner to choose from; nothing here is the built section.
extension DesignCatalogTests {
    enum DocumentTrail {
        case none, close, unload, chevronDown, chevronUp, plus
        case count(Int)
    }

    struct DocumentRowLook {
        var second: String?
        var fill = 0.0
        var stroke = false
        var trail = DocumentTrail.none
        var indent = 0.0
        var edited = false
        var dim = false
    }

    func documentRow(_ title: String, _ symbol: String, _ look: DocumentRowLook = DocumentRowLook()) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        return HStack(spacing: 7) {
            Image(systemName: symbol).font(.system(size: 13)).frame(width: 18, height: 18)
                .foregroundStyle(look.dim ? .secondary : .primary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13)).lineLimit(1)
                if let second = look.second {
                    Text(second).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            if look.edited { Circle().fill(.primary.opacity(0.7)).frame(width: 6, height: 6) }
            Spacer(minLength: 0)
            documentTrail(look.trail)
        }
        .padding(.leading, 8 + look.indent)
        .padding(.trailing, 6)
        .frame(height: look.second == nil ? 32 : 40)
        .background(shape.fill(.primary.opacity(look.fill)))
        .overlay { if look.stroke { shape.strokeBorder(.primary.opacity(0.12), lineWidth: 0.5) } }
    }

    @ViewBuilder private func documentTrail(_ trail: DocumentTrail) -> some View {
        let box = RoundedRectangle(cornerRadius: 4, style: .continuous).fill(.primary.opacity(0.1))
        switch trail {
            case .none: EmptyView()
            case .close:
                Image(systemName: "xmark").font(.system(size: 9, weight: .semibold)).frame(width: 20, height: 20)
                    .background(box)
            case .unload:
                Image(systemName: "minus").font(.system(size: 9, weight: .semibold)).frame(width: 20, height: 20)
                    .background(box)
            case .chevronUp:
                Image(systemName: "chevron.up").font(.system(size: 9, weight: .semibold))
                    .frame(width: 20, height: 20)
            case .count(let count):
                Text("\(count)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    .padding(.trailing, 4)
        }
    }

    func documentHeader(_ title: String, plus: Bool = true) -> some View {
        HStack(spacing: 4) {
            Text(title).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold)).foregroundStyle(.tertiary)
            Spacer(minLength: 0)
            if plus {
                Image(systemName: "plus").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.leading, 8).padding(.trailing, 6).frame(height: 22)
    }

    var documentLine: some View {
        Rectangle().fill(.primary.opacity(0.12)).frame(height: 0.5).padding(.horizontal, 8).frame(height: 6)
    }

    /// The top of every mock sidebar: two Favorites, then the line.
    @ViewBuilder var documentFavorites: some View {
        documentRow("Projects", "folder", DocumentRowLook(dim: true))
        documentRow("Sunset", "terminal", DocumentRowLook(fill: 0.06, indent: 14))
        documentRow("Swift Forums", "globe")
    }

    /// The bottom of every mock sidebar: the window's own tabs.
    @ViewBuilder func documentTabs(with document: Bool = false, selected: Bool = true) -> some View {
        documentRow(
            "fish",
            "terminal",
            DocumentRowLook(fill: selected ? 0.14 : 0.06, stroke: selected, trail: selected ? .close : .none)
        )
        documentRow("Example Domain", "globe", DocumentRowLook(fill: 0.06))
        if document {
            documentRow(
                "Harbour notes",
                "doc.text",
                DocumentRowLook(fill: 0.14, stroke: true, trail: .close, edited: true)
            )
        }
    }

    @ViewBuilder func documentList(indent: Double = 0, open: Bool = false, dates: Bool = false) -> some View {
        documentRow(
            "Harbour notes",
            "doc.text",
            DocumentRowLook(second: dates ? "Today, 14:02" : nil, fill: open ? 0.06 : 0, indent: indent)
        )
        documentRow("Release plan", "doc.text", DocumentRowLook(second: dates ? "Yesterday" : nil, indent: indent))
        documentRow("Login flow", "flowchart", DocumentRowLook(second: dates ? "12 November" : nil, indent: indent))
        documentRow("Untitled", "doc.plaintext", DocumentRowLook(second: dates ? "3 November" : nil, indent: indent))
    }

    func documentSidebar(@ViewBuilder _ content: () -> some View) -> AnyView {
        AnyView(VStack(spacing: 4) { content() }.padding(4).background(Color(white: 0.09)))
    }

    /// The panel variant C opens: a field, then the documents with their dates.
    var documentPanel: AnyView {
        AnyView(
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(.secondary)
                    Text("Search Documents").font(.system(size: 12)).foregroundStyle(.tertiary)
                    Spacer(minLength: 0)
                    Image(systemName: "plus").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8).frame(height: 26)
                .background(Capsule().fill(.primary.opacity(0.08)))
                documentList(dates: true)
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(white: 0.17)))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.primary.opacity(0.12), lineWidth: 0.5)
            }
        )
    }

    var documentsSection: CatalogSheet {
        CatalogSheet(
            title: "The Documents section of the sidebar (mock-up, ST-5)",
            note:
                "Under the Favorites, above the window's tabs. A: a small heading with a + (new document) and a chevron that folds it. "
                + "B: one row that looks and folds like a Favorites folder, the documents indented under it. C: one row; a click opens "
                + "a panel with a search field and the dates, as the history panel does. D: as A, but only the latest few, then a row "
                + "that opens C's panel for the rest. Icons: Markdown, Mermaid diagram, plain text.",
            columns: [
                .init(
                    title: "A heading",
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
                        ),
                        .init(
                            label: "folded",
                            view: documentSidebar {
                                documentFavorites
                                documentLine
                                documentHeader("Documents")
                                documentLine
                                documentTabs()
                            }
                        )
                    ]
                ),
                .init(
                    title: "B folder",
                    examples: [
                        .init(
                            label: "",
                            view: documentSidebar {
                                documentFavorites
                                documentLine
                                documentRow("Documents", "doc.on.doc", DocumentRowLook(trail: .chevronUp, dim: true))
                                documentList(indent: 14)
                                documentLine
                                documentTabs()
                            }
                        ),
                        .init(
                            label: "folded",
                            view: documentSidebar {
                                documentFavorites
                                documentLine
                                documentRow("Documents", "doc.on.doc", DocumentRowLook(trail: .count(4), dim: true))
                                documentLine
                                documentTabs()
                            }
                        )
                    ]
                ),
                .init(
                    title: "C one row, a panel",
                    examples: [
                        .init(
                            label: "",
                            view: documentSidebar {
                                documentFavorites
                                documentLine
                                documentRow("Documents", "doc.on.doc", DocumentRowLook(trail: .count(4)))
                                documentLine
                                documentTabs()
                            }
                        ), .init(label: "its panel", view: documentPanel)
                    ]
                ),
                .init(
                    title: "D heading, latest 3",
                    examples: [
                        .init(
                            label: "",
                            view: documentSidebar {
                                documentFavorites
                                documentLine
                                documentHeader("Documents")
                                documentRow("Harbour notes", "doc.text")
                                documentRow("Release plan", "doc.text")
                                documentRow("Login flow", "flowchart")
                                documentRow(
                                    "All Documents\u{2026}",
                                    "ellipsis",
                                    DocumentRowLook(trail: .count(27), dim: true)
                                )
                                documentLine
                                documentTabs()
                            }
                        )
                    ]
                )
            ],
            width: 221
        )
    }

    @Test func `the Documents section, drawn for the owner`() throws {
        guard let folder = ProcessInfo.processInfo.environment["SUNSET_CATALOG"].map({ URL(fileURLWithPath: $0) })
        else { return }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        #expect(documentsSection.write(to: folder.appending(path: "st5-documents.png")))
        #expect(documentsOpen.write(to: folder.appending(path: "st5-open.png")))
    }
}
