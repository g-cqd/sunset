import SunsetShell
import SwiftUI

/// The window's title is the shown pane's. Given to the window directly, by a view of its own that alone follows the title:
/// through `navigationTitle`, SwiftUI showed the hidden title bar again at each change and the chrome put it back (the
/// traffic lights moved again each time), and the whole scene was read again; a program that renames its tab often cost a
/// tenth of the main thread's work in the chrome alone (measured, `Scripts/retitle-probe`; review of 2026-11-15, t265).
struct WindowTitle: View {
    let tabs: TabsModel

    var body: some View { WindowTitleKeeper(title: tabs.selectedContent?.title ?? "Sunset") }
}
