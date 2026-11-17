import Foundation
import SunsetPane
import Testing

@testable import SunsetShell

/// A Space's editor, and what a window does when the last tab of its Space closes (the owner, 2026-11-17).
@MainActor
@Suite("Editing a Space, and its last tab")
struct SpaceEditingTests {
    private func spaces() -> SpacesModel { SpacesModel(makeFavorites: { FavoritesModel() }) }

    private func window(on spaces: SpacesModel, made: MadeContents) -> TabsModel {
        let tabs = TabsModel()
        tabs.makeContent = { descriptor in
            let content = FakeContent(descriptor)
            made.all.append(content)
            return content
        }
        tabs.show(space: spaces.spaces[0], in: spaces)
        return tabs
    }

    // MARK: The editor (the owner, 2026-11-17: three fields, Save and Cancel)

    @Test func `a new Space is made when its editor is saved, not before; cancelled, nothing was made`() throws {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        window.newTab()
        window.newSpace()
        var draft = try #require(window.spaceDraft)
        #expect(draft.space == nil && draft.name == "Space 2" && draft.icon == .symbol("2.circle") && draft.tint == nil)
        #expect(spaces.spaces.count == 1 && spaces.spaces[0].space.name.isEmpty, "nothing yet")
        window.spaceDraft = nil
        #expect(spaces.spaces.count == 1)
        window.newSpace()
        draft = try #require(window.spaceDraft)
        draft.name = "  Work "
        draft.icon = .emoji("\u{1F680}")
        draft.tint = IconColor(red: 0x0A, green: 0x84, blue: 0xFF)
        window.save(draft)
        #expect(window.spaceDraft == nil && spaces.spaces.map(\.space.name) == ["Home", "Work"])
        let work = spaces.spaces[1]
        #expect(
            work.space.icon == .emoji("\u{1F680}") && work.space.tint == IconColor(red: 0x0A, green: 0x84, blue: 0xFF)
        )
        #expect(window.space === work && window.bar != nil, "shown, with the command bar: it has no tab")
        #expect(work.saved().space.look?["tint"] == "#0A84FF")
    }

    @Test func `an edited Space changes when it is saved, and only then; a blank name is not saved`() throws {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        let work = spaces.add(from: spaces.spaces[0])
        window.edit(space: work)
        var draft = try #require(window.spaceDraft)
        #expect(draft.space == work.space.id && draft.name == "Space 2")
        draft.name = "Work"
        draft.tint = IconColor(red: 255, green: 0, blue: 0)
        #expect(work.space.name == "Space 2" && work.space.tint == nil, "the draft is not the Space")
        window.save(draft)
        #expect(work.space.name == "Work" && work.space.tint == IconColor(red: 255, green: 0, blue: 0))
        window.edit(space: work)
        draft = try #require(window.spaceDraft)
        draft.name = "   "
        draft.tint = nil
        #expect(!draft.canSave)
        window.save(draft)
        #expect(work.space.name == "Work" && work.space.tint != nil && window.spaceDraft != nil, "still being edited")
    }

    // MARK: The last tab (the owner, 2026-11-17)

    @Test func `the last tab of a Space closes: the window stays, on an empty Space; unless told to close with it`()
        throws
    {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        var closed = 0
        window.onEmpty = { closed += 1 }
        window.newTab()
        window.close(item: try #require(window.workspace.selectedID))
        #expect(closed == 0 && window.workspace.isEmpty && made.all[0].stopped)
        window.newTab()
        made.all[1].onExit()
        #expect(closed == 0, "a shell that ends is a tab that closes")
        window.closesWithLastTab = true
        window.newTab()
        window.close(item: try #require(window.workspace.selectedID))
        #expect(closed == 1)
        // A window that is not among the Spaces (one tab a window, a private one) closes with its last tab, as before.
        let alone = TabsModel()
        alone.makeContent = { FakeContent($0) }
        var gone = 0
        alone.onEmpty = { gone += 1 }
        alone.newTab()
        alone.close(item: try #require(alone.workspace.selectedID))
        #expect(gone == 1)
    }
}
