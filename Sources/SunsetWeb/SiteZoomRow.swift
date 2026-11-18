import SunsetShell
import SwiftUI

/// The page's zoom in its site's panel (W-d): smaller, the level, larger, back to 100 %; kept for the site when zoom is by
/// site (`web.zoomScope`).
struct SiteZoomRow: View {
    let content: WebContent

    var body: some View {
        HStack {
            Label("Zoom", systemImage: "plus.magnifyingglass")
            Spacer()
            Button {
                content.zoom(by: -1)
            } label: {
                Image(systemName: "minus")
            }
            .accessibilityLabel("Zoom Out")
            Button("\(Int((content.zoom * 100).rounded())) %") { content.resetZoom() }
                .accessibilityLabel("Actual Size")
            Button {
                content.zoom(by: 1)
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Zoom In")
        }
        .buttonStyle(.borderless)
    }
}
