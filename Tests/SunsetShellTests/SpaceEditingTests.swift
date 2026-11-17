import Foundation
import SunsetPane
import SwiftUI
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

    // MARK: The slide between Spaces (the owner's note n79)

    /// "When swiping through spaces, we should still see the space we're swiping away, it should still exist until the
    /// end of the snapping": while the list is off its place, the neighbour's list is beside it, and the window is still
    /// on the Space it leaves.
    @Test func `while the list is off its place the neighbour's is beside it, and the Space is not left yet`() throws {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        window.newTab()
        let home = spaces.spaces[0]
        let work = spaces.add(from: home)
        let play = spaces.add(from: home)
        window.show(space: work)
        window.newTab()
        let shown = try #require(window.workspace.selectedID)
        // Fingers to the left: the next Space's list comes from the right.
        window.shift(spaceListTo: -30)
        #expect(window.space === work && window.slide.shift == -30)
        var beside = try #require(window.slide.beside)
        #expect(beside.isNext && beside.tabs.space === play && beside.tabs.workspace.isEmpty)
        #expect(play.viewerCount == 0, "a list to look at, not a window on the Space")
        // Back past the middle, to the right: the previous one, with the tab this window had selected there.
        window.shift(spaceListTo: 12)
        beside = try #require(window.slide.beside)
        #expect(!beside.isNext && beside.tabs.space === home && beside.tabs.workspace.count == 1)
        #expect(beside.tabs.workspace.selectedID == home.tabs.items[0].id)
        // Let go: back to its place, nothing beside, still on Work with what was shown.
        window.shift(spaceListTo: 0)
        #expect(window.slide.beside == nil && window.space === work && window.workspace.selectedID == shown)
        // At an end there is nothing beside.
        window.show(space: play)
        window.shift(spaceListTo: -30)
        #expect(window.slide.beside == nil && window.slide.shift == -30)
    }

    @Test func `with no sidebar to slide in, a Space is gone to at once; with one, when the slide has ended`() {
        let (spaces, made) = (spaces(), MadeContents())
        let window = window(on: spaces, made: made)
        let work = spaces.add(from: spaces.spaces[0])
        window.stepSpace(by: 1)
        #expect(window.space === work && window.slide.beside == nil)
        // With a sidebar: the list is beside, the slide is under way, and the Space changes when it ends.
        window.slide.width = 240
        window.slide.animation = .default
        var ended: (() -> Void)?
        window.runSlide = { _, change, completion in
            change()
            ended = completion
        }
        window.stepSpace(by: 1)
        #expect(window.space === work && window.slide.isRunning, "still on the Space it leaves")
        #expect(window.slide.beside?.tabs.space === spaces.spaces[0] && window.slide.beside?.isNext == true)
        window.stepSpace(by: 1)
        #expect(window.slide.beside?.tabs.space === spaces.spaces[0], "one slide at a time")
        ended?()
        #expect(window.space === spaces.spaces[0] && !window.slide.isRunning && window.slide.beside == nil)
        #expect(window.slide.shift == 0)
    }
}
