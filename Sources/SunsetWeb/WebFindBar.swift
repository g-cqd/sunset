import AemiSDR
import SunsetShell
import SwiftUI

/// The find bar of a page, delegating its capsule glass chrome to `FindBarView`.
struct WebFindBar: View {
    let content: WebContent
    /// Its blur falls down from the top edge (in the window bar at the bottom: up).
    var atTop = true

    var body: some View {
        FindBarView(model: content.find, atTop: atTop)
            .onChange(of: content.find.isOpen) { _, open in
                if !open { content.focusPage() }
            }
    }
}
