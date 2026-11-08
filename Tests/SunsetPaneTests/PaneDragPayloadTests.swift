import Foundation
import Testing

@testable import SunsetPane

@Suite("Drag payload") struct PaneDragPayloadTests {
    @Test func `a tab and a pane have text forms that read back as themselves`() {
        let item = Workspace.ItemID()
        let pane = PaneID()
        #expect(PaneDragPayload(text: PaneDragPayload.item(item).text) == .item(item))
        #expect(PaneDragPayload(text: PaneDragPayload.pane(pane).text) == .pane(pane))
        #expect(PaneDragPayload.item(item).text != PaneDragPayload.pane(item).text, "the same id is not the same thing")
    }

    @Test func `text that is not a payload reads as nothing`() {
        #expect(PaneDragPayload(text: "") == nil)
        #expect(PaneDragPayload(text: "hello") == nil)
        #expect(PaneDragPayload(text: "item:not-a-uuid") == nil)
        #expect(PaneDragPayload(text: "tab:" + UUID().uuidString) == nil)
    }

    @Test func `a bare id, as the sidebar wrote it before panes, is a tab`() {
        let id = UUID()
        #expect(PaneDragPayload(text: id.uuidString) == .item(id))
    }
}
