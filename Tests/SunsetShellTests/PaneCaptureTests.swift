import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// n47: a tab shows the microphone and the camera a page uses, each muted from there.
@Suite("The devices a page uses") struct PaneCaptureTests {
    @Test func `each its own symbol, struck while muted, and what a click does`() {
        #expect(PaneCapture.symbol(.microphone, .live) == "mic.fill")
        #expect(PaneCapture.symbol(.microphone, .muted) == "mic.slash.fill")
        #expect(PaneCapture.symbol(.camera, .live) == "video.fill")
        #expect(PaneCapture.symbol(.camera, .muted) == "video.slash.fill")
        #expect(PaneCapture.help(.microphone, .live) == "Mute the Microphone")
        #expect(PaneCapture.help(.camera, .muted) == "Turn the Camera Back On")
    }

    @Test func `muted is still shown, so that it can be unmuted`() {
        var capture = PaneCapture(microphone: .live)
        capture[.microphone] = .muted
        #expect(!capture.isEmpty && capture.microphone == .muted && capture.camera == nil)
    }
}
