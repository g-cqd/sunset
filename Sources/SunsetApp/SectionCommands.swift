import SunsetConfig
import SunsetShell
import SwiftUI

/// View's items for the sections of the sidebars (roadmap 0031). No keys of their own yet: Cmd-Y stays the history's.
struct SectionCommands: View {
    var body: some View {
        Button("Library") { AppActions.shared.toggleLibrary() }
            .disabled(!AppConfiguration.shared.configuration.sidebar.library)
        Button("Documents") { AppActions.shared.toggleOpposite(.documents) }
        Button("Downloads") { AppActions.shared.toggleOpposite(.downloads) }
    }
}
