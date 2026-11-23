import SunsetShell
import SunsetWebModel
package import SwiftUI

/// The Now Playing stack at the foot of the sidebar (roadmap 0114): the front card, and above it the tops of at most two
/// more, each a little smaller and dimmer, as in perspective; a card behind shows its surface only, never what it holds,
/// so that the front one reads. A scroll up or down over it brings the next card to the front, going round them all.
/// Cards come, go and change places animated.
package struct NowPlayingStack: View {
    let center: NowPlaying
    let pictureInPicture: Bool
    /// What every card is drawn on: the window's own material, from the app.
    let surface: AnyView
    @Environment(\.surfaceStyle) private var style

    package init(center: NowPlaying = .shared, pictureInPicture: Bool, surface: AnyView) {
        self.center = center
        self.pictureInPicture = pictureInPicture
        self.surface = surface
    }

    package var body: some View {
        let shown = center.stack.shown
        ZStack(alignment: .bottom) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { depth, page in
                card(page, depth: depth)
                    .zIndex(-Double(depth))
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .scale(scale: 1 - Design.NowPlaying.shrink).combined(with: .opacity)
                        )
                    )
            }
        }
        .padding(.top, Design.NowPlaying.peek * Double(shown.dropFirst().count))
        .background(NowPlayingScrollCatcher { cards in withAnimation(.snappy) { center.scroll(cards) } })
        .animation(.smooth, value: shown.map(\.id))
        .animation(.smooth, value: shown.first)
    }

    private func card(_ page: MediaPage, depth: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: Design.NowPlaying.radius, style: .continuous)
        return NowPlayingCard(page: page, center: center, pictureInPicture: pictureInPicture)
            // Behind the front card: its surface only.
            .opacity(depth == 0 ? 1 : 0)
            .background { surface.clipShape(shape) }
            .overlay { shape.fill(.black.opacity(depth == 0 ? 0 : 1 - Design.NowPlaying.behind)) }
            .clipShape(shape)
            // Its edge, as the window's other surfaces have (n125): a card without one blurred into the sidebar.
            .overlay { shape.hairline(style.layout) }
            // A slight shadow under the front card (n133); the cards behind it are under it already.
            .shadow(
                color: .black.opacity(depth == 0 ? Design.Shadow.card.opacity : 0),
                radius: Design.Shadow.card.radius,
                y: Design.Shadow.card.y
            )
            .allowsHitTesting(depth == 0)
            // Nor to accessibility: a card behind has nothing to press (seen 2026-11-22: its hidden buttons were pressed).
            .accessibilityHidden(depth != 0)
            .scaleEffect(1 - Design.NowPlaying.shrink * Double(depth), anchor: .top)
            .offset(y: -Design.NowPlaying.peek * Double(depth))
    }
}
