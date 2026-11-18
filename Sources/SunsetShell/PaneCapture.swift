/// A device a page uses (the owner's note n47): the microphone or the camera, live or muted by the person. A tab shows each
/// and mutes or unmutes it from there; the site's panel too.
package struct PaneCapture: Equatable, Sendable {
    package enum Device: Sendable, CaseIterable { case microphone, camera }
    package enum State: Sendable { case live, muted }

    package var microphone: State?
    package var camera: State?

    package init(microphone: State? = nil, camera: State? = nil) {
        self.microphone = microphone
        self.camera = camera
    }

    package subscript(_ device: Device) -> State? {
        get { device == .microphone ? microphone : camera }
        set { if device == .microphone { microphone = newValue } else { camera = newValue } }
    }

    package var isEmpty: Bool { microphone == nil && camera == nil }

    /// Its symbol in a tab: struck through while muted.
    package static func symbol(_ device: Device, _ state: State) -> String {
        let base = device == .microphone ? "mic" : "video"
        return state == .muted ? base + ".slash.fill" : base + ".fill"
    }

    /// What clicking it does.
    package static func help(_ device: Device, _ state: State) -> String {
        switch (device, state) {
            case (.microphone, .live): "Mute the Microphone"
            case (.microphone, .muted): "Unmute the Microphone"
            case (.camera, .live): "Turn the Camera Off"
            case (.camera, .muted): "Turn the Camera Back On"
        }
    }
}
