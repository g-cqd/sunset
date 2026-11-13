package import SunsetPane
package import SwiftUI

/// A tab's picture alone: the icon a person gave it, its content's glyph, or, not running, what it would start from (in outline).
package struct TabIcon: View {
    let model: (any PaneContent)?
    var icon: PaneIcon?
    var saved: PaneDescriptor?
    var savedCommand: String?
    /// The loading ring shows while the content loads (`tabs.bar.showProgress` and the sidebar's).
    var showsProgress = true
    @Environment(\.accent) private var accent

    package init(
        model: (any PaneContent)?,
        icon: PaneIcon? = nil,
        saved: PaneDescriptor? = nil,
        savedCommand: String? = nil,
        showsProgress: Bool = true
    ) {
        self.model = model
        self.icon = icon
        self.saved = saved
        self.savedCommand = savedCommand
        self.showsProgress = showsProgress
    }

    package var body: some View {
        let progress = showsProgress ? model?.progress : nil
        let loading = progress != nil
        ZStack {
            picture
                .scaleEffect(loading ? Design.Ring.iconScale : 1)
                .clipShape(Circle().scale(loading ? Design.Ring.clipLoading : Design.Ring.clipAtRest))
            // Completes when the page has loaded (no progress left), then fades as the icon grows back.
            Circle()
                .inset(by: Design.Ring.lineWidth / 2)
                .trim(from: 0, to: progress ?? 1)
                .stroke(accent.color, style: StrokeStyle(lineWidth: Design.Ring.lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(loading ? 1 : 0)
        }
        .frame(width: Design.Size.glyphFrame, height: Design.Size.glyphFrame)
        .animation(.easeOut(duration: Design.Ring.follow), value: progress)
        .animation(.easeOut(duration: Design.Ring.settle), value: loading)
    }

    @ViewBuilder private var picture: some View {
        if let icon {
            PaneIconView(icon: icon)
        } else if let model {
            PaneGlyphView(glyph: model.glyph)
        } else {
            PaneGlyphView(
                glyph: TabLabel.glyph(
                    of: saved ?? PaneDescriptor(kind: PaneDescriptor.terminalKind),
                    command: savedCommand
                ),
                outlined: true
            )
        }
    }
}
