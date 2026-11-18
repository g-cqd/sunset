import Foundation
import Testing

/// The owner's note n6 (2026-11-18): switches and checkboxes used consistently. A toggle outside a menu says which it is
/// (`settingSwitch()`, `choiceBox()`), or sits in a view that does (the settings' form): none takes the style of where it
/// happens to be.
@Suite("Switches and checkboxes, each for its role") struct ToggleRolesTests {
    /// Files whose toggles are menu items (a menu draws them as checkmarks) or take their role from the settings' form.
    static let inMenusOrForm: Set<String> = [
        "KeepAwakeMenu.swift", "WebFindBar.swift", "SettingsRow.swift", "SettingsCustomRow.swift",
        // The switch style itself.
        "SpreadSwitchStyle.swift"
    ]

    @Test func `every toggle outside a menu and the settings' form says whether it is a switch or a checkbox`() {
        var unsaid: [String] = []
        for file in RepositoryFiles.swiftFiles(in: ["Sources"]) where !Self.inMenusOrForm.contains(file.name) {
            let toggles = file.text.components(separatedBy: "Toggle(").count - 1
            guard toggles > 0 else { continue }
            let said =
                file.text.components(separatedBy: ".settingSwitch()").count - 1
                + file.text.components(separatedBy: ".choiceBox()").count - 1
            if said < toggles { unsaid.append("\(file.name): \(toggles) toggles, \(said) said") }
        }
        #expect(unsaid.isEmpty, "\(unsaid)")
    }
}
