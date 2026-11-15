package import Foundation

/// A document of the store as the sidebars list it (roadmap 0030 step ST-5, 0031): what its row shows and is ordered by.
package struct ShelfDocument: Identifiable, Sendable, Equatable {
    package enum Kind: Int, Sendable, CaseIterable {
        case markdown, diagram, text

        /// The heading of its group when the documents are ordered by kind.
        package var title: String {
            switch self {
                case .markdown: "Markdown"
                case .diagram: "Diagrams"
                case .text: "Text"
            }
        }

        /// An SF Symbol.
        package var symbol: String {
            switch self {
                case .markdown: "doc.text"
                case .diagram: "flowchart"
                case .text: "doc.plaintext"
            }
        }
    }

    package let id: UUID
    package var title: String
    package var kind: Kind
    package var created: Date
    package var modified: Date

    package init(id: UUID, title: String, kind: Kind, created: Date, modified: Date) {
        self.id = id
        self.title = title
        self.kind = kind
        self.created = created
        self.modified = modified
    }

    /// The documents whose title holds every word of `query`, whatever the case and the accents; all of them for no word.
    /// The text of a document is not searched: it is sealed, and is not read to list it.
    package static func matching(_ query: String, in documents: [Self]) -> [Self] {
        let words = query.split(whereSeparator: \.isWhitespace)
        guard !words.isEmpty else { return documents }
        return documents.filter { document in
            words.allSatisfy {
                document.title.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
        }
    }
}
