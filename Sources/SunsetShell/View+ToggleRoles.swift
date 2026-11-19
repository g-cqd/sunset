package import SwiftUI

/// The two kinds of switch Sunset draws, the same everywhere (the owner's note n6, 2026-11-18: "use more consistently
/// toggles and checkboxes"): what turns something on or off — a setting, a site's blocking — is a switch; what picks the
/// things an action applies to — what Clear History clears, a sheet's "Don't ask again" — is a checkbox. In a menu, a
/// toggle is the menu's checkmark.
extension View {
    /// On or off: a switch, small, its label on the leading edge and the switch on the trailing one (note n45).
    package func settingSwitch() -> some View {
        toggleStyle(SpreadSwitchStyle()).controlSize(.small)
    }

    /// One of the things an action applies to: a checkbox.
    package func choiceBox() -> some View {
        toggleStyle(.checkbox)
    }
}
