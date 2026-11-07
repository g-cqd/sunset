import AppKit
import SunsetConfig
import SwiftUI

/// Gives the window the look the configuration asks for: with `decorations: none` the content fills the window under a transparent title bar with no title, and
/// the traffic lights stay, moved to where `trafficLights` says (within the title bar's own area: the system lays them out in it); with `native` the system's
/// title bar. It sits behind the terminal as a view of its own size and acts on the window it is in.
struct WindowChrome: NSViewRepresentable {
    var settings: Configuration.Window

    func makeNSView(context: Context) -> ChromeView { ChromeView() }

    func updateNSView(_ view: ChromeView, context: Context) { view.settings = settings }
}
