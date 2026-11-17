import SunsetHelp
import SunsetPane
import SwiftUI

/// The fourth light (n78, t287): after the zoom button, in the system's accent (`PresetLightColor`); a click or the pointer
/// resting on it shows the presets that lay the selected tab out (`PresetPanel`), as the green light's panel
/// lays out windows.
struct PresetLight: View {
    let tabs: TabsModel
    @State private var shown = false
    @State private var hovered = false
    @State private var resting: Task<Void, Never>?

    var body: some View {
        Button {
            shown.toggle()
        } label: {
            Circle()
                .fill(Color(nsColor: PresetLightColor.color))
                .overlay {
                    if hovered {
                        Image(systemName: "rectangle.split.2x2")
                            .font(.system(size: Design.Size.presetLightGlyph, weight: .bold))
                            .foregroundStyle(.black.opacity(Design.Fill.lightGlyph))
                    }
                }
                .frame(width: SidebarHeader.lightsSize, height: SidebarHeader.lightsSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { inside in
            hovered = inside
            resting?.cancel()
            guard inside else { return }
            // As the green light's panel: shown once the pointer rests on it.
            resting = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                if !Task.isCancelled, hovered { shown = true }
            }
        }
        .helpTopic(.layoutLight)
        .accessibilityLabel("Lay Out the Tab")
        .popover(isPresented: $shown, arrowEdge: .bottom) {
            PresetPanel(tabs: tabs) { shown = false }
        }
    }
}
