import SunsetShell
import SwiftUI

/// A panel a page shows of its own (four panels drew it whole): on the popover's surface, one width, in its pane;
/// `blocking`, over a veil that keeps the page from being used until it is answered (a dialog, a sign-in, a share).
struct PagePanel<Content: View>: View {
    var blocking = true
    /// Its width: one for every panel, but a wider one where it shows pictures (the share panel).
    var width = Design.Width.panel
    @ViewBuilder let content: () -> Content
    @Environment(\.surfaceStyle) private var surface

    var body: some View {
        if blocking {
            ZStack {
                Color.black.opacity(Design.Fill.veil).contentShape(.rect).onTapGesture {}
                panel
            }
        } else {
            panel
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: Design.Space.l) {
            content()
        }
        .padding(Design.Space.xl)
        .frame(width: width, alignment: .leading)
        .surface(surface.panelShape, shadow: .popover)
        .padding(Design.Space.l)
    }
}
