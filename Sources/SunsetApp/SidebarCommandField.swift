import SunsetConfig
import SunsetHelp
import SunsetPane
import SunsetShell
import SwiftUI

/// The sidebar's field while no page has the address there: a tab's size, it says what can be typed; a click opens the command
/// bar in its place (a search, an address, a tab, a command), where Return on an address or a search opens it in a new tab.
struct SidebarCommandField: View {
    let tabs: TabsModel

    /// What it says, and the command bar's field opened in its place: with the web off there is no address to enter, only tabs
    /// and commands.
    static var prompt: String {
        AppScopes.current.web ? "Search or Enter Address" : "Go to a Tab"
    }

    var body: some View {
        Button {
            if tabs.bar == nil { tabs.toggleBar() }
        } label: {
            HStack(spacing: Design.Optical.fieldGlyphToText) {
                Image(systemName: "magnifyingglass")
                    .frame(width: Design.Size.glyphFrame)
                Text(Self.prompt)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(.secondary)
            .fieldSurface(dark: false)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // Under the command bar while it is open here: its field takes this place.
        .opacity(tabs.bar?.inSidebar == true ? 0 : 1)
        .helpTopic(.sidebarField)
        .accessibilityLabel("Search or Enter Address")
    }
}
