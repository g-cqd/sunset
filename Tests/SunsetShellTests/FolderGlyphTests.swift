import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// "Previews don't show the custom icon for folders". The folder's row and its card under the pointer show the same
/// glyph: the folder's own icon when it has one the system can draw, else a folder, filled while open.
@MainActor @Suite("A folder's glyph, in its row and its card")
struct FolderGlyphTests {
    private func folder(icon: PaneIcon?) throws -> Favorites.Folder {
        var favorites = Favorites()
        let id = try #require(favorites.addFolder(named: "Work") as Favorites.NodeID?)
        favorites.setIcon(icon, for: id)
        guard case .folder(let folder)? = favorites.node(id) else {
            throw FolderMissing()
        }
        return folder
    }

    private struct FolderMissing: Error {}

    @Test func `its own icon when it has one, a folder otherwise`() throws {
        let own = try folder(icon: .symbol("briefcase"))
        #expect(FolderGlyph(folder: own, open: true).custom == .symbol("briefcase"))
        #expect(FolderGlyph(folder: try folder(icon: .emoji("🌅")), open: true).custom == .emoji("🌅"))
        let plain = try folder(icon: nil)
        #expect(FolderGlyph(folder: plain, open: true).custom == nil)
        #expect(FolderGlyph(folder: plain, open: true).symbol == "folder.fill")
        #expect(FolderGlyph(folder: plain, open: false).symbol == "folder")
        #expect(FolderGlyph(folder: try folder(icon: .symbol("no.such.symbol.anywhere")), open: true).custom == nil)
    }
}
