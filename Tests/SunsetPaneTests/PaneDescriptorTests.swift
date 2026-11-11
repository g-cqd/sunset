import Foundation
import Testing

@testable import SunsetPane

/// What is saved to bring a pane's content back, whatever it is.
@Suite("Pane descriptor") struct PaneDescriptorTests {
    private func window() -> (Workspace, PaneID, PaneID) {
        var workspace = Workspace()
        let first = workspace.add().pane
        let second = workspace.add().pane
        return (workspace, first, second)
    }

    @Test func `a window's contents survive the session file, each with its kind and what it needs`() throws {
        let (workspace, first, second) = window()
        let saved = SavedWindow(
            workspace: workspace,
            contents: [
                first: .terminal(directory: "/tmp"), second: PaneDescriptor(kind: "note", state: ["text": "milk\neggs"])
            ]
        )
        let data = try SavedSession(windows: [saved]).encoded()
        let read = try #require(SavedSession(data: data)?.windows.first)
        #expect(read == saved)
        #expect(read.contents[first]?.directory == "/tmp")
        #expect(read.contents[second] == PaneDescriptor(kind: "note", state: ["text": "milk\neggs"]))
    }

    @Test func `a session written before there were kinds reads as terminals in their directories`() throws {
        let (workspace, first, second) = window()
        let ids = workspace.items.map(\.id.uuidString)
        let old = """
            {"version":1,"windows":[{"directories":[{"pane":"\(first.uuidString)","directory":"/Users/me/code"}],
            "workspace":{"items":[{"id":"\(ids[0])","focused":"\(first.uuidString)","layout":{"pane":"\(first.uuidString)"}},
            {"id":"\(ids[1])","focused":"\(second.uuidString)","layout":{"pane":"\(second.uuidString)"}}],"selected":"\(ids[0])"}}]}
            """
        let read = try #require(SavedSession(data: Data(old.utf8))?.windows.first)
        #expect(read.contents == [first: .terminal(directory: "/Users/me/code")])
        #expect(read.workspace.count == 2, "a pane with nothing saved is still a tab: it starts as a new terminal")
    }

    @Test func `a pane that is gone is not written, and a kind nobody knows is kept as it is`() throws {
        let (workspace, first, _) = window()
        let unknown = PaneDescriptor(kind: "hologram", state: ["scene": "7"])
        let saved = SavedWindow(
            workspace: workspace,
            contents: [first: unknown, PaneID(): .terminal(directory: "/gone")]
        )
        let read = try #require(SavedSession(data: try SavedSession(windows: [saved]).encoded())?.windows.first)
        #expect(read.contents == [first: unknown])
    }

    @Test func `a terminal's descriptor has its directory or nothing`() {
        #expect(PaneDescriptor.terminal(directory: nil) == PaneDescriptor(kind: "terminal", state: [:]))
        #expect(PaneDescriptor.terminal(directory: nil).directory == nil)
        #expect(PaneDescriptor(kind: "note", state: ["directory": "/x"]).directory == nil, "only a terminal has one")
    }
}
