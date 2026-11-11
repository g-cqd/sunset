import AppKit
import SwiftUI

/// Escape clears the rows selected together (R3 step d) without being taken from the terminal: the key still goes where it was going (a program in the
/// terminal reads Escape constantly). Watched while the sidebar is shown.
struct EscapeClearsMarks: ViewModifier {
    let tabs: TabsModel
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear {
                weak let tabs = tabs
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.keyCode == 53, let tabs, !tabs.marked.isEmpty { tabs.clearMarks() }
                    return event
                }
            }
            .onDisappear {
                if let monitor { NSEvent.removeMonitor(monitor) }
                monitor = nil
            }
    }
}
