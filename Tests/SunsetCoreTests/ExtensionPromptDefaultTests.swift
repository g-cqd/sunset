import Foundation
import SunsetTestSupport
import Testing

/// The install prompt's yes is never its default: Return does not install, a click on "Add Extension" does; in Sunset's
/// alert, Cancel is button 0 and the default, and only button 1 installs.
@Suite("The install prompt's default")
struct ExtensionPromptDefaultTests {
    @Test func `Cancel first and the default, Add Extension second, and only the second installs`() throws {
        let text = try #require(
            RepositoryFiles.swiftFiles(in: ["Sources"]).first { $0.name.hasSuffix("ExtensionPrompt.swift") }?.text
        )
        #expect(text.contains(#"buttons: [.cancel("Cancel"), .plain("Add Extension")]"#))
        #expect(text.contains("defaultButton: 0"))
        #expect(text.contains("await SunsetAlerts.ask(alert) == 1"))
    }
}
