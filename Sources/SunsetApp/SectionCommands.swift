import SunsetConfig
import SunsetPane
import SunsetShell
import SwiftUI

/// View's items for the sections of the sidebars. No keys of their own yet: Cmd-Y stays the history's.
struct SectionCommands: View {
    let scopes: Scopes

    var body: some View {
        if SidebarSection.rail(for: scopes).count > 1 {
            CommandItem(.library)
        }
        if scopes.documents { Button("Documents") { AppActions.shared.toggleOpposite(.documents) } }
        if scopes.web { Button("Downloads") { AppActions.shared.toggleOpposite(.downloads) } }
    }
}
