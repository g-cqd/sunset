import MarkdownLookKit
import SunsetDocuments
import SunsetShell
import SwiftUI

/// A JSON document drawn as a tree: objects and arrays fold, the root open; scalars said in a line in the colour of their
/// kind. Text that is not JSON (yet: it is being typed) says so. Drawn again from the text as it is edited.
struct DataDocumentView: View {
    let content: DocumentContent

    var body: some View {
        let source = content.document.source
        if let tree = DataTree(source.text) {
            List {
                OutlineGroup(tree.children ?? [tree], id: \.id, children: \.children) { node in
                    DataNodeRow(node: node)
                }
            }
            .listStyle(.inset)
            .id(source.revision)
        } else {
            ContentUnavailableView(
                "Not JSON",
                systemImage: "curlybraces",
                description: Text("Show Source to see where it goes wrong.")
            )
        }
    }
}
