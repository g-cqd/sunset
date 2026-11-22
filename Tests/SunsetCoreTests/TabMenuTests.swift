import Foundation
import SunsetTestSupport
import Testing

/// No menu of a tab leads to Settings: a tab has no settings of its own there.
@Suite("A tab's menu") struct TabMenuTests {
    @Test func `no entry of a tab's menu opens Settings`() {
        let menus = RepositoryFiles.swiftFiles(in: ["Sources"]).filter { $0.name.hasPrefix("TabRowMenu") }
        #expect(!menus.isEmpty)
        for file in menus { #expect(!file.text.contains(".settings(topic:"), "\(file.name)") }
    }
}
