import Foundation
import Testing

@testable import SunsetPane

/// A tab drawn at its document's row under the Documents heading (roadmap 0031, 0030 step ST-5), and a document dragged.
@Suite("A tab on its document's row") struct WorkspaceShelvedTests {
    @Test func `a tab is among the tabs until it is put on its document's row, and that is kept with the window`()
        throws
    {
        var workspace = Workspace()
        let first = workspace.add().item
        let second = workspace.add().item
        #expect(workspace.items.allSatisfy { !$0.shelved })
        workspace.shelve(item: second, true)
        #expect(workspace.items.map(\.shelved) == [false, true])

        let data = try JSONEncoder().encode(workspace)
        let back = try JSONDecoder().decode(Workspace.self, from: data)
        #expect(back.items.map(\.shelved) == [false, true] && back.items.map(\.id) == [first, second])
        workspace.shelve(item: second, false)
        #expect(!String(decoding: try JSONEncoder().encode(workspace), as: UTF8.self).contains("shelved"))
    }

    @Test func `a window saved before there was a Documents heading reads with every tab among the tabs`() throws {
        let pane = UUID().uuidString
        let item = UUID().uuidString
        let old =
            #"{"items":[{"id":"\#(item)","layout":{"pane":"\#(pane)"},"focused":"\#(pane)"}],"selected":"\#(item)"}"#
        let workspace = try JSONDecoder().decode(Workspace.self, from: Data(old.utf8))
        #expect(workspace.items.count == 1 && workspace.items[0].shelved == false)
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
