import SunsetMetrics
import SwiftUI

/// The button that empties a name being typed in place (a tab's, an entry's, a folder's).
struct ClearNameButton: View {
    let layout: ShellSettings.Layout
    let clear: () -> Void

    var body: some View {
        Button(action: clear) {
            RowButtonFace(
                symbol: "delete.left",
                side: layout.closeButtonSize,
                radius: layout.closeButtonRadius,
                quiet: true
            )
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help("Clear the Name")
        .accessibilityLabel("Clear the Name")
    }
}
