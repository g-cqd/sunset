import Foundation
import SunsetTestSupport
import Testing

/// n140 and n147: the symbols of a context menu were blue (the accent is the tint of everything below a window's root, and a menu takes
/// it), for a tab's menu, then for a pinned tab's and a favorite's, and the same went for the folders', the built-in bar's and others. A
/// menu's own ink is `.tint(.primary)`; setting it view by view left the next menu to repeat the bug. Every context menu goes through
/// `inkedContextMenu`, which sets it. A source test, because a tint is not something a unit test can see.
@Suite("Context menus keep the menu's own ink")
struct MenuInkTests {
    @Test func `no context menu is opened but through inkedContextMenu`() {
        let files = RepositoryFiles.swiftFiles(in: ["Sources"])
        let bare = files.flatMap { file in
            file.text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()
                .compactMap { number, line in
                    Self.opensContextMenu(String(line)) && file.name != "View+InkedContextMenu.swift"
                        ? "\(file.name):\(number + 1)" : nil
                }
        }
        #expect(bare.isEmpty, "use .inkedContextMenu { }: \(bare)")
    }

    @Test func `the helper itself sets the ink on what it opens`() throws {
        let helper = try #require(
            RepositoryFiles.swiftFiles(in: ["Sources/SunsetShell"]).first { $0.name == "View+InkedContextMenu.swift" }
        )
        #expect(helper.text.contains(".tint(.primary)"))
    }

    /// A `.contextMenu {` or `.contextMenu(…)` that is a call, not a word in a comment, a string or an enum case.
    static func opensContextMenu(_ line: String) -> Bool {
        let code = line.trimmingCharacters(in: .whitespaces)
        guard !code.hasPrefix("//"), !code.hasPrefix("///"), !code.hasPrefix("case ") else { return false }
        return code.contains(".contextMenu {") || code.contains(".contextMenu(")
    }
}
