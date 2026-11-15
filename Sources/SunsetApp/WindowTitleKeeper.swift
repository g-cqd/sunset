import SwiftUI

/// Puts `title` on the window it is in (`WindowTitleView`).
struct WindowTitleKeeper: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> WindowTitleView { WindowTitleView() }

    func updateNSView(_ view: WindowTitleView, context: Context) { view.title = title }
}
