import SunsetShell
import SwiftUI

/// A page of the app's own (Settings, Help) in its pane: `laidOut(narrow:)` given whether the pane is too narrow for the
/// list beside the page (measured on the pane, not the page, which can be wider), the pane's top inset, and the backdrop of
/// Sunset's scheme (the owner, 2026-11-27: these pages stayed dark in light, and did not fit a narrow pane).
struct ListBesidePage<Content: View>: View {
    let context: PaneViewContext
    @ViewBuilder let laidOut: (_ narrow: Bool) -> Content

    var body: some View {
        GeometryReader { pane in
            laidOut(pane.size.width < Design.Size.settingsList + Design.Size.settingsPageMinimum)
                .frame(width: pane.size.width, height: pane.size.height)
        }
        .padding(.top, context.topInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paneBackdrop(context.backdrop.forApp(light: AppConfiguration.shared.isLight))
    }
}
