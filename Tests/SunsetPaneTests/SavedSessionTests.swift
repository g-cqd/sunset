import Foundation
import Testing

@testable import SunsetPane

@Suite("Saved session") struct SavedSessionTests {
    /// Three tabs, the middle one split in three, the first selected.
    private func sample() -> Workspace {
        var workspace = Workspace()
        workspace.add()
        let middle = workspace.add()
        workspace.add()
        workspace.select(item: middle.item)
        let b = workspace.addPane(beside: middle.pane, edge: .right)
        if let b { workspace.addPane(beside: b, edge: .bottom) }
        workspace.setRatio(0.3, at: [], in: middle.item)
        workspace.select(index: 0)
        return workspace
    }

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
    }

    @Test func `a layout reads back as itself, ratios and axes included`() throws {
        let layout = try #require(sample().items[1].layout as SplitLayout?)
        #expect(try roundTrip(layout) == layout)
    }

    @Test func `a workspace reads back as itself: order, selection, focus and layouts`() throws {
        var workspace = sample()
        workspace.focus(pane: workspace.items[1].panes[1])
        workspace.select(index: 2)
        #expect(try roundTrip(workspace) == workspace)
        #expect(try roundTrip(Workspace()) == Workspace())
    }

    @Test func `the text form is stable JSON with a version`() throws {
        let text = String(
            decoding: try SavedSession(windows: [SavedWindow(workspace: sample())]).encoded(),
            as: UTF8.self
        )
        #expect(text.contains("\"version\":1") || text.contains("\"version\" : 1"))
        #expect(text.contains("\"horizontal\""))
    }

    @Test func `a workspace whose focused pane is not in its tab is refused`() throws {
        var data = try JSONSerialization.jsonObject(with: JSONEncoder().encode(sample())) as? [String: Any] ?? [:]
        var items = data["items"] as? [[String: Any]] ?? []
        items[0]["focused"] = UUID().uuidString
        data["items"] = items
        let bad = try JSONSerialization.data(withJSONObject: data)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Workspace.self, from: bad) }
    }

    @Test func `a pane in two tabs, or a selected tab that does not exist, is refused`() throws {
        var data = try JSONSerialization.jsonObject(with: JSONEncoder().encode(sample())) as? [String: Any] ?? [:]
        data["selected"] = UUID().uuidString
        let missing = try JSONSerialization.data(withJSONObject: data)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Workspace.self, from: missing) }
        var items =
            (try JSONSerialization.jsonObject(with: JSONEncoder().encode(sample())) as? [String: Any])?["items"]
            as? [[String: Any]] ?? []
        items[1]["layout"] = items[0]["layout"]
        items[1]["focused"] = items[0]["focused"]
        let twice = try JSONSerialization.data(withJSONObject: ["items": items, "selected": items[0]["id"] ?? ""])
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Workspace.self, from: twice) }
    }

    @Test func `a session reads back with each window's pane directories`() throws {
        let workspace = sample()
        let pane = workspace.allPanes[0]
        let session = SavedSession(windows: [SavedWindow(workspace: workspace, directories: [pane: "/tmp/x"])])
        let back = try #require(SavedSession(data: try session.encoded()))
        #expect(back == session && back.windows[0].directories[pane] == "/tmp/x")
    }

    @Test func `nonsense, an empty file and another version read as no session`() {
        #expect(SavedSession(data: Data()) == nil)
        #expect(SavedSession(data: Data("[1,2".utf8)) == nil)
        #expect(SavedSession(data: Data(#"{"version":99,"windows":[]}"#.utf8)) == nil)
    }

    @Test func `a window that is damaged is dropped and the others are kept`() throws {
        let good = try JSONSerialization.jsonObject(
            with: SavedSession(windows: [SavedWindow(workspace: sample())]).encoded()
        )
        let windows = ((good as? [String: Any])?["windows"] as? [Any]) ?? []
        let mixed = try JSONSerialization.data(withJSONObject: [
            "version": 1, "windows": [["workspace": "junk"]] + windows
        ])
        #expect(SavedSession(data: mixed)?.windows.count == 1)
    }

    @Test func `windows with no tabs are not worth saving`() throws {
        let session = SavedSession(windows: [SavedWindow(workspace: Workspace()), SavedWindow(workspace: sample())])
        #expect(session.windows.count == 1)
    }
}
