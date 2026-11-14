import SwiftUI

@testable import SunsetShell

/// Mock-ups of an open document in the sidebar (roadmap 0030 step ST-5), for the owner to choose from.
extension DesignCatalogTests {
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

    var documentsOpen: CatalogSheet {
        CatalogSheet(
            title: "A document that is open (mock-up, ST-5)",
            note:
                "1: it opens as a tab among the window's tabs (it can be split, kept as a Favorite, restored with the session); its row "
                + "in Documents gets the faint fill an open Favorite has, and a click on it shows that tab. 2: as a Favorite does, it "
                + "opens in place: its row in Documents is the tab (a minus closes the pane, the document stays). 3: Documents lists "
                + "only what is not open; an open document is a tab and nothing else. The dot is \"edited, not saved yet\".",
            columns: [
                .init(
                    title: "1 a tab, marked in Documents",
                    examples: [
                        .init(
                            label: "",
                            view: documentSidebar {
                                documentFavorites
                                documentLine
                                documentHeader("Documents")
                                documentList(open: true)
                                documentLine
                                documentTabs(with: true, selected: false)
                            }
                        )
                    ]
                ),
                .init(
                    title: "2 in place, as a Favorite",
                    examples: [
                        .init(
                            label: "",
                            view: documentSidebar {
                                documentFavorites
                                documentLine
                                documentHeader("Documents")
                                documentRow(
                                    "Harbour notes",
                                    "doc.text",
                                    DocumentRowLook(fill: 0.14, stroke: true, trail: .unload, edited: true)
                                )
                                documentRow("Release plan", "doc.text")
                                documentRow("Login flow", "flowchart")
                                documentRow("Untitled", "doc.plaintext")
                                documentLine
                                documentTabs(selected: false)
                            }
                        )
                    ]
                ),
                .init(
                    title: "3 a tab, and gone from Documents",
                    examples: [
                        .init(
                            label: "",
                            view: documentSidebar {
                                documentFavorites
                                documentLine
                                documentHeader("Documents")
                                documentRow("Release plan", "doc.text")
                                documentRow("Login flow", "flowchart")
                                documentRow("Untitled", "doc.plaintext")
                                documentLine
                                documentTabs(with: true, selected: false)
                            }
                        )
                    ]
                )
            ],
            width: 221
        )
    }
}
