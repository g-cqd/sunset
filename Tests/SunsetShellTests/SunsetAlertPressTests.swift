import SwiftUI
import Testing

@testable import SunsetShell

/// Seen on screen: deleting a Space with tabs asked, and neither "Close Its Tabs" nor "Move Its Tabs" deleted it, because
/// the alert went (clearing which Space was asked about) before the answer read it.
@Suite("A Sunset alert's button pressed")
@MainActor
struct SunsetAlertPressTests {
    @Test func `the answer reads the state that shows the alert, which goes after`() {
        var asking: String? = "Space 2"
        let isPresented = Binding(get: { asking != nil }, set: { if !$0 { asking = nil } })
        var answered: (index: Int, about: String?)?
        SunsetAlertPress.press(1, isPresented: isPresented) { index in answered = (index, asking) }
        #expect(answered?.index == 1)
        #expect(answered?.about == "Space 2")
        #expect(asking == nil)
    }
}
