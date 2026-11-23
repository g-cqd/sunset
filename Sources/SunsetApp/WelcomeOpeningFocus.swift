import SunsetShellModel
import SwiftUI

/// The window's content coming into focus as the opening shows the window (`WelcomeOpening.contentBlur`); sharp once it
/// has ended or been cut short.
struct WelcomeOpeningFocus<Content: View>: View {
    let clock: WelcomeOpeningClock
    @ViewBuilder let content: () -> Content

    var body: some View {
        if let start = clock.start {
            TimelineView(.animation) { context in
                let elapsed = max(0, context.date.timeIntervalSince(start))
                let now = WelcomeOpening.at(elapsed, frame: .zero)
                content().blur(radius: now.contentBlur)
            }
        } else {
            content()
        }
    }
}
