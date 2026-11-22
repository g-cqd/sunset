import SunsetShell
import SunsetWebModel
package import SwiftUI

/// The Now Playing stack at the foot of the sidebar (roadmap 0114): the front card, and above it the tops of at most two
/// more, each smaller and fainter, as in perspective. A scroll up or down over it brings the next card to the front.
package struct NowPlayingStack: View {
    let center: NowPlaying
    let pictureInPicture: Bool
    let goThere: (WebContent) -> Void

    package init(center: NowPlaying = .shared, pictureInPicture: Bool, goThere: @escaping (WebContent) -> Void) {
        self.center = center
        self.pictureInPicture = pictureInPicture
        self.goThere = goThere
    }

    package var body: some View {
        let shown = center.stack.shown
        if !shown.isEmpty {
            ZStack(alignment: .bottom) {
                ForEach(Array(shown.enumerated()).reversed(), id: \.element.id) { depth, page in
                    NowPlayingCard(page: page, center: center, pictureInPicture: pictureInPicture, goThere: goThere)
                        .allowsHitTesting(depth == 0)
                        .scaleEffect(1 - Design.NowPlaying.shrink * Double(depth), anchor: .top)
                        .offset(y: -Design.NowPlaying.peek * Double(depth))
                        .opacity(depth == 0 ? 1 : Design.NowPlaying.behind)
                        .zIndex(-Double(depth))
                }
            }
            .padding(.top, Design.NowPlaying.peek * Double(shown.dropFirst().count))
            .background(NowPlayingScrollCatcher { cards in center.scroll(cards) })
            .animation(.smooth, value: shown.map(\.id))
        }
    }
}
