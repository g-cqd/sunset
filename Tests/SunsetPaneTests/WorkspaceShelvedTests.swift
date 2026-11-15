import Foundation
import Testing

@testable import SunsetPane

/// A document dragged, and a window saved while documents had rows of their own under a heading among the tabs (2026-11-15,
/// for a day: the owner took the heading out).
@Suite("Documents and the workspace") struct WorkspaceShelvedTests {
    @Test
    func `a window saved with a tab on a document's row reads with that tab among the tabs, and writes no such mark`()
        throws
    {
        let pane = UUID().uuidString
        let item = UUID().uuidString
        let old =
            #"{"items":[{"id":"\#(item)","layout":{"pane":"\#(pane)"},"focused":"\#(pane)","shelved":true}],"selected":"\#(item)"}"#
        let workspace = try JSONDecoder().decode(Workspace.self, from: Data(old.utf8))
        #expect(workspace.items.count == 1 && workspace.items[0].id.uuidString == item)
        #expect(!String(decoding: try JSONEncoder().encode(workspace), as: UTF8.self).contains("shelved"))
    }

    @Test func `a dragged document travels as text, and a stored document has its descriptor`() {
        let id = UUID()
        #expect(PaneDragPayload(text: PaneDragPayload.document(id).text) == .document(id))
        #expect(PaneDragPayload(text: "document:not-an-id") == nil)
        let descriptor = PaneDescriptor.document(stored: id)
        #expect(descriptor.kind == PaneDescriptor.documentKind && descriptor.storedDocument == id)
        #expect(PaneDescriptor.terminal(directory: nil).storedDocument == nil)
        #expect(PaneDescriptor(kind: "page", state: ["document": id.uuidString]).storedDocument == nil)
    }
}
