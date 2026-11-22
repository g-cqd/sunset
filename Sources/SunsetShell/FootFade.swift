package import SwiftUI

/// The bottom of a sidebar list's mask above the buttons at its foot: the rows faded out by the buttons' top, nothing
/// drawn under them (seen 2026-11-17 and 2026-11-22: rows showed through the buttons).
package struct FootFade: View {
    /// The room the buttons take.
    let room: Double
    @Environment(\.fadesEnds) private var fadesEnds

    package init(room: Double) {
        self.room = room
    }

    package var body: some View {
        LinearGradient(gradient: .end(from: .black, to: .clear, fading: fadesEnds), startPoint: .top, endPoint: .bottom)
            .frame(height: Design.Space.xl)
        Color.clear.frame(height: room)
    }
}
