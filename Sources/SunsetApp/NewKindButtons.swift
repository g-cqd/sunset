import SunsetPane
import SunsetShell
import SwiftUI

/// A new terminal tab and a new page, each where its scope is on (the Panes menu and the sidebar's add menu each listed
/// them).
struct NewKindButtons: View {
    let scopes: Scopes

    var body: some View {
        if scopes.terminal {
            Button("New Terminal Tab") { AppActions.shared.newTab(kind: PaneDescriptor.terminal(directory: nil)) }
        }
        if scopes.web {
            Button("New Web Page") { AppActions.shared.newTab(kind: PaneContentKinds.newPage) }
        }
    }
}
