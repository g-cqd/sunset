import SunsetConfig
import SwiftUI

/// The built-in bar on a toolbar of its own: the system's bar material, a hairline on the page's side.
extension TerminalScene {
    var toolbarBar: some View {
        let atTop = configuration.tabs.bar.position == .top
        return VStack(spacing: 0) {
            if !atTop { Divider() }
            tabBar
            if atTop { Divider() }
        }
        .background(.bar)
    }
}
