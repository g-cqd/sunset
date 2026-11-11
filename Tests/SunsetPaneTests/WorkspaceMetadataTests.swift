import Foundation
import Testing

@testable import SunsetPane

/// The name and icon the user gives a tab (`n41`), over what its content says.
@Suite("Workspace metadata") struct WorkspaceMetadataTests {
    @Test func `a tab has no name or icon of its own until it is given one, and nil gives the content's back`() {
        var workspace = Workspace()
        let added = workspace.add()
        #expect(workspace.items[0].customTitle == nil && workspace.items[0].customIcon == nil)
        workspace.setTitle("  Servers \n", for: added.item)
        workspace.setIcon(.symbol("server.rack"), for: added.item)
        #expect(workspace.items[0].customTitle == "Servers")
        #expect(workspace.items[0].customIcon == .symbol("server.rack"))
        workspace.setTitle("   ", for: added.item)
        workspace.setIcon(nil, for: added.item)
        #expect(workspace.items[0].customTitle == nil && workspace.items[0].customIcon == nil)
    }

    @Test func `naming a tab that is not there changes nothing`() {
        var workspace = Workspace()
        _ = workspace.add()
        let before = workspace
        workspace.setTitle("x", for: Workspace.ItemID())
        workspace.setIcon(.emoji("📁"), for: Workspace.ItemID())
        #expect(workspace == before)
    }

    @Test func `a name and an icon survive a saved session, and a session written before them still reads`() throws {
        var workspace = Workspace()
        let added = workspace.add()
        workspace.setTitle("Projects", for: added.item)
        workspace.setIcon(.emoji("📁"), for: added.item)
        let data = try SavedSession(windows: [SavedWindow(workspace: workspace)]).encoded()
        let read = try #require(SavedSession(data: data))
        #expect(read.windows.first?.workspace == workspace)
        #expect(String(decoding: data, as: UTF8.self).contains(#""emoji" : "📁""#))

        var plain = Workspace()
        _ = plain.add()
        let old = try SavedSession(windows: [SavedWindow(workspace: plain)]).encoded()
        #expect(String(decoding: old, as: UTF8.self).contains("customTitle") == false)
        #expect(SavedSession(data: old)?.windows.first?.workspace == plain)
    }

    @Test func `what is typed for an icon is a symbol's name or an emoji, and reads back as it was typed`() {
        #expect(PaneIcon(text: "  server.rack ") == .symbol("server.rack"))
        #expect(PaneIcon(text: "📁") == .emoji("📁"))
        #expect(PaneIcon(text: "👩🏽‍💻 work") == .emoji("👩🏽‍💻"), "the first character, whole, when it is not a name")
        #expect(PaneIcon(text: "é") == .emoji("é"), "any character that no symbol's name has is shown as it is")
        #expect(PaneIcon(text: "   ") == nil && PaneIcon(text: "") == nil)
        #expect(PaneIcon.symbol("bolt.fill").text == "bolt.fill" && PaneIcon.emoji("🚀").text == "🚀")
    }
}
