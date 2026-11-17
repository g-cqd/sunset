import Foundation
import Testing

@testable import SunsetPane

/// The session file since Spaces (roadmap 0021 step S-a; ADR-0045): the Spaces in one order, each with its Favorites and its
/// tabs, and the windows as views of them. Reading never fails a launch, and what is read holds together: a pane is in one
/// place, a view shows a Space that exists and selects what that Space has.
@Suite("The session, by Spaces")
struct SpacesSessionTests {
    private func tabs(_ count: Int) -> Workspace {
        var workspace = Workspace()
        for _ in 0 ..< count { workspace.add(after: .end) }
        return workspace
    }

    private func space(_ name: String, tabs count: Int) -> SavedSpace {
        let workspace = tabs(count)
        let contents = Dictionary(
            uniqueKeysWithValues: workspace.allPanes.map { ($0, PaneDescriptor.terminal(directory: "/" + name)) }
        )
        return SavedSpace(space: Space(name: name), tabs: workspace, contents: contents)
    }

    @Test func `it reads back as itself: the Spaces in their order, what each holds, and the views`() throws {
        var work = space("Work", tabs: 3)
        work.space.icon = .symbol("hammer", color: nil)
        work.space.profile = UUID()
        work.space.look = ["tint": "orange"]
        var favorites = Favorites()
        let pane = PaneID()
        let made1 = favorites.addEntry(home: Favorites.Home(layout: .pane(pane), focused: pane))
        let kept = try #require(made1)
        work.favorites = SavedFavorites(favorites: favorites)
        let home = space("", tabs: 1)
        let views = [
            SavedView(space: work.space.id, selected: work.tabs.items[2].id),
            SavedView(space: work.space.id, selected: nil),
            SavedView(space: home.space.id, selected: home.tabs.items[0].id)
        ]
        let session = SpacesSession(spaces: [work, home], views: views)
        let text = String(decoding: try session.encoded(), as: UTF8.self)
        #expect(text.contains("\"version\" : 3"))
        let read = try #require(SpacesSession(data: Data(text.utf8)))
        #expect(read == session)
        #expect(read.spaces.map(\.space.name) == ["Work", ""] && read.views == views)
        #expect(
            read.spaces[0].space.look == ["tint": "orange"] && read.profiles[0].favorites.favorites.entry(kept) != nil
        )
        #expect(read.spaces[0].contents.count == 3)
    }

    @Test func `when a Space's tabs were stopped is kept with it, and only while it has tabs`() throws {
        var waiting = space("Waiting", tabs: 1)
        waiting.stopped = Date(timeIntervalSince1970: 1_794_000_000)
        var empty = space("Empty", tabs: 0)
        empty.stopped = Date(timeIntervalSince1970: 5)
        let read = try #require(SpacesSession(data: try SpacesSession(spaces: [waiting, empty], views: []).encoded()))
        #expect(read.spaces[0].stopped == Date(timeIntervalSince1970: 1_794_000_000) && read.spaces[1].stopped == nil)
    }

    /// The owner, 2026-11-17: a Space has a colour, which tints the window that shows it.
    @Test
    func `a Space's tint is kept in its look, as a colour; what is not one is no tint; mixed into a window's tint`() {
        var space = Space(name: "Work")
        #expect(space.tint == nil && space.look == nil)
        space.tint = IconColor(red: 0x0A, green: 0x84, blue: 0xFF)
        #expect(space.look == ["tint": "#0A84FF"] && space.tint == IconColor(red: 0x0A, green: 0x84, blue: 0xFF))
        space.look?["material"] = "glass"
        space.tint = nil
        #expect(space.look == ["material": "glass"], "what else the look holds is left")
        space.look = ["tint": "blue"]
        #expect(space.tint == nil)
        // A third of the Space's colour in the window's own tint: tinted, not painted.
        #expect(IconColor(red: 255, green: 0, blue: 90).mixed(into: [0, 0, 0], share: 1.0 / 3) == [85, 0, 30])
        #expect(IconColor(red: 0, green: 0, blue: 0).mixed(into: [255, 255, 255], share: 0.5) == [128, 128, 128])
        #expect(
            IconColor(red: 9, green: 9, blue: 9).mixed(into: [1, 2], share: 0.5) == [9, 9, 9],
            "no tint to mix into"
        )
    }

    @Test func `there is always a Space: nothing saved is one Space with nothing in it and no window`() {
        let empty = SpacesSession(spaces: [], views: [])
        #expect(empty.spaces.count == 1 && empty.spaces[0].tabs.isEmpty && empty.views.isEmpty)
        #expect(empty.spaces[0].space.name.isEmpty)
        #expect(SpacesSession(data: Data("not json".utf8)) == nil)
        #expect(SpacesSession(data: Data(#"{"version": 99, "spaces": [], "windows": []}"#.utf8)) == nil)
    }

    /// The tabs of a Space have no selection of their own: each view has its own.
    @Test func `a view selects what its Space has, and a view of no Space is left out`() {
        let work = space("Work", tabs: 2)
        let other = space("Other", tabs: 1)
        let session = SpacesSession(
            spaces: [work, other],
            views: [
                SavedView(space: work.space.id, selected: other.tabs.items[0].id),
                SavedView(space: UUID(), selected: nil),
                SavedView(space: other.space.id, selected: other.tabs.items[0].id, entry: UUID())
            ]
        )
        #expect(session.views.count == 2)
        #expect(session.views[0].selected == nil, "a tab of another Space is not selected here")
        #expect(session.views[1].selected == other.tabs.items[0].id && session.views[1].entry == nil)
        // What a window shows of it: the Space's tabs, with the view's selection.
        let shown = session.workspace(for: session.views[1])
        #expect(shown?.items == other.tabs.items && shown?.selectedID == other.tabs.items[0].id)
        #expect(session.workspace(for: session.views[0])?.selectedID == nil)
        #expect(session.workspace(for: SavedView(space: UUID(), selected: nil)) == nil)
    }

    /// What is kept (the profile's Favorites, ADR-0055, as its Pinned grid) holds its panes before any Space does.
    @Test
    func `a pane is in one place: of two Spaces that hold it the first keeps it; a tab gives way to a kept entry`()
        throws
    {
        let first = space("First", tabs: 2)
        var second = space("Second", tabs: 1)
        var stolen = second.tabs
        stolen.insert(first.tabs.items[0], at: 0)
        second = SavedSpace(space: second.space, tabs: stolen, contents: second.contents)
        var favorites = Favorites()
        let made2 = favorites.keep(first.tabs.items[1], contents: [:])
        let kept = try #require(made2)
        var third = space("Third", tabs: 0)
        third.favorites = SavedFavorites(favorites: favorites)
        let session = SpacesSession(spaces: [first, second, third, first], views: [])
        #expect(session.spaces.map(\.space.name) == ["First", "Second", "Third"], "a Space is there once")
        #expect(
            session.spaces[0].tabs.items.map(\.id) == [first.tabs.items[0].id],
            "its second tab is the kept entry's"
        )
        #expect(session.spaces[1].tabs.count == 1)
        #expect(session.profiles[0].favorites.favorites.entry(kept)?.isOpen == true)
    }

    @Test func `a damaged Space or view is left out, the rest is read`() throws {
        let good = space("Good", tabs: 1)
        let session = SpacesSession(spaces: [good, space("Bad", tabs: 1)], views: [SavedView(space: good.space.id)])
        var file = try #require(try JSONSerialization.jsonObject(with: session.encoded()) as? [String: Any])
        var spaces = try #require(file["spaces"] as? [[String: Any]])
        spaces[1]["tabs"] = ["items": "not a list"]
        file["spaces"] = spaces
        file["windows"] = (file["windows"] as? [Any] ?? []) + [["space": 12]]
        let read = try #require(SpacesSession(data: try JSONSerialization.data(withJSONObject: file)))
        #expect(read.spaces.map(\.space.name) == ["Good"] && read.views.count == 1)
    }

    @Test func `more Spaces than the limit are not read`() {
        let many = (0 ..< SpacesSession.maximumSpaces + 5).map { space("S\($0)", tabs: 0) }
        #expect(SpacesSession(spaces: many, views: []).spaces.count == SpacesSession.maximumSpaces)
    }

    // MARK: A session of before

    /// Versions 1 and 2 had windows with their own tabs, and one Favorites: they become one Space, unnamed.
    @Test func `a session of before becomes one Space: the windows' tabs in the windows' order, a view each`() throws {
        var first = tabs(2)
        first.select(index: 0)
        var second = tabs(3)
        second.select(index: 2)
        var favorites = Favorites()
        let made3 = favorites.keep(tabs(1).items[0], contents: [:])
        let kept = try #require(made3)
        var third = Workspace()
        third.select(entry: kept)
        let directories = Dictionary(
            uniqueKeysWithValues: (first.allPanes + second.allPanes).enumerated()
                .map {
                    ($1, PaneDescriptor.terminal(directory: "/d\($0)"))
                }
        )
        let old = SavedSession(
            windows: [first, second, third].map { SavedWindow(workspace: $0, contents: directories) },
            favorites: SavedFavorites(favorites: favorites)
        )
        let read = try #require(SpacesSession(data: try old.encoded()))
        #expect(read.spaces.count == 1 && read.spaces[0].space.name.isEmpty)
        let space = read.spaces[0]
        #expect(space.tabs.items == first.items + second.items)
        #expect(space.contents == directories && read.profiles[0].favorites.favorites.entry(kept)?.isOpen == true)
        #expect(
            read.views == [
                SavedView(space: space.space.id, selected: first.items[0].id),
                SavedView(space: space.space.id, selected: second.items[2].id),
                SavedView(space: space.space.id, selected: nil, entry: kept)
            ]
        )
        // Written again, it is of this version, and reads back the same.
        #expect(SpacesSession(data: try read.encoded()) == read)
    }

    @Test func `a file of version 1, with pane directories, is still read`() throws {
        let workspace = tabs(1)
        let pane = workspace.allPanes[0]
        let window: [String: Any] = [
            "workspace": try JSONSerialization.jsonObject(with: JSONEncoder().encode(workspace)),
            "directories": [["pane": pane.uuidString, "directory": "/old"]]
        ]
        let file = try JSONSerialization.data(withJSONObject: ["version": 1, "windows": [window]])
        let read = try #require(SpacesSession(data: file))
        #expect(read.spaces[0].contents[pane] == .terminal(directory: "/old") && read.views.count == 1)
    }
}
