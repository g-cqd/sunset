import SunsetShell
import SwiftUI

/// The site panel's first group (the owner, 2026-11-19): what this tab's page uses now, each stopped or muted from here, as
/// from the tab's own buttons; apart from the settings of the site, which stay for its next pages.
struct SitePageNow: View {
    let content: WebContent

    /// Whether the page uses anything now: sound, the microphone, the camera, the screen, or it is shared into a call.
    static func shows(_ content: WebContent) -> Bool {
        content.sound != nil || !content.devices.isEmpty || content.capture != nil || content.sharedInto > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            Text("This tab now").font(Design.Text.detail).foregroundStyle(.secondary)
            if let sound = content.sound {
                Toggle(isOn: Binding(get: { sound != .muted }, set: { _ in content.toggleMuted() })) {
                    Label("Sound", systemImage: sound.symbol)
                }
                .settingSwitch()
            }
            ForEach(PaneCapture.Device.allCases, id: \.self) { device in
                if let state = content.devices[device] {
                    Toggle(isOn: Binding(get: { state == .live }, set: { _ in content.toggle(device) })) {
                        Label(
                            device == .microphone ? "Microphone" : "Camera",
                            systemImage: PaneCapture.symbol(device, state)
                        )
                    }
                    .settingSwitch()
                }
            }
            if content.capture != nil {
                Button("Stop Camera, Microphone and Screen") { content.stopCapture() }
            }
            // This page is shared into a call (ADR-0082): stopped from here too.
            if content.sharedInto > 0 {
                Button("Stop Sharing This Tab") { content.stopBeingShared() }
            }
        }
    }
}
