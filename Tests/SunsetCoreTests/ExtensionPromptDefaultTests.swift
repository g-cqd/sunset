import Foundation
import SunsetTestSupport
import Testing

/// The install prompt's yes is never its first button: Return does not install, a click on "Add Extension" does (ADR-0109).
@Suite("The install prompt's default")
struct ExtensionPromptDefaultTests {
    @Test func `Cancel first, Add Extension second, and only the second installs`() throws {
        let text = try #require(
            RepositoryFiles.swiftFiles(in: ["Sources"]).first { $0.name.hasSuffix("ExtensionPrompt.swift") }?.text
        )
        let cancel = try #require(text.range(of: #"addButton(withTitle: "Cancel")"#))
        let add = try #require(text.range(of: #"addButton(withTitle: "Add Extension")"#))
        #expect(cancel.lowerBound < add.lowerBound)
        #expect(text.contains("== .alertSecondButtonReturn") && !text.contains("alertFirstButtonReturn"))
    }
}
