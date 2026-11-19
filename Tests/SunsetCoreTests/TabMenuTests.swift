import Foundation
import SunsetTestSupport
import Testing

/// The owner's note n47 (2026-11-18): "the tab settings context menu entry on a tab, the one that leads to the tab settings in
/// the settings is useless". No menu of a tab leads to Settings.
@Suite("A tab's menu") struct TabMenuTests {
    @Test func `no entry of a tab's menu opens Settings`() {
        let menus = RepositoryFiles.swiftFiles(in: ["Sources"]).filter { $0.name.hasPrefix("TabRowMenu") }
        #expect(!menus.isEmpty)
        for file in menus { #expect(!file.text.contains(".settings(topic:"), "\(file.name)") }
    }
}
