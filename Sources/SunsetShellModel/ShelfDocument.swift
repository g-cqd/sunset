package import Foundation

/// A document of the store as the sidebars list it: what its row shows and is ordered by.
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
    /// The path of a file on disk that was opened lately; nil for a document of the store. Such a row is listed with the
    /// documents and is not one: it cannot be deleted from here, and its dates are when it was opened.
    package var file: String?

    package init(id: UUID, title: String, kind: Kind, created: Date, modified: Date) {
        self.id = id
        self.title = title
        self.kind = kind
        self.created = created
        self.modified = modified
    }

    /// A file opened lately, as a row among the documents: named by its file's name, of the kind its extension says.
    /// - Parameters:
    ///   - path: the file.
    ///   - opened: when it was last opened here.
    package init(file path: String, opened: Date) {
        let name = (path as NSString).lastPathComponent
        let kind: Kind =
            switch (name as NSString).pathExtension.lowercased() {
                case "md", "markdown", "mdown", "mkd", "mkdn", "mdwn": .markdown
                case "mmd", "mermaid": .diagram
                default: .text
            }
        self.init(id: Self.identity(of: path), title: name, kind: kind, created: opened, modified: opened)
        file = path
    }

    /// The same for the same path, in every run: a list keeps its row for a file while its date changes.
    private static func identity(of path: String) -> UUID {
        // FNV-1a, twice with two bases: 128 bits that only have to tell the paths of one list apart.
        func hash(_ basis: UInt64) -> UInt64 {
            path.utf8.reduce(basis) { ($0 ^ UInt64($1)) &* 0x0000_0100_0000_01B3 }
        }
        let (high, low) = (hash(0xCBF2_9CE4_8422_2325), hash(0x8422_2325_CBF2_9CE4))
        var bytes: [UInt8] = []
        for shift in stride(from: 56, through: 0, by: -8) {
            bytes.append(UInt8(truncatingIfNeeded: high >> UInt64(shift)))
        }
        for shift in stride(from: 56, through: 0, by: -8) {
            bytes.append(UInt8(truncatingIfNeeded: low >> UInt64(shift)))
        }
        return UUID(
            uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9],
                bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
            )
        )
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
