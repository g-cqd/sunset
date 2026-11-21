package import SwiftUI

extension Design {
    /// The welcome (roadmap 0111 H; docs/research/welcome-design.md): the sky the whole window, the text in the darker
    /// upper sky over a dimming layer, left-aligned in the system's text styles.
    package enum Welcome {
        /// How far above the screen's middle the window sits, as a share of the screen's height.
        package static let opticalLift = 0.07
        /// The window's size.
        package static let size = CGSize(width: 720, height: 470)
        /// Around the content and the buttons.
        package static let margin = 44.0
        /// Between the title block and the controls, and between controls: the spacing scale's.
        package static let section = Space.xxl
        package static let row = Space.l
        /// The controls' column: narrow enough to read, the sky beside it.
        package static let column = 440.0
        /// The dimming behind the text (the HIG's 35% for bright content), fading out by `dimmingReach` of the height.
        package static let dimming = 0.35
        package static let dimmingReach = 0.55
        /// Where the dimming under the buttons starts, as a share of the height.
        package static let buttonsDimmingStart = 0.8
        /// The page change: a cross-fade.
        package static let change = Animation.smooth(duration: 0.3)
    }
}
