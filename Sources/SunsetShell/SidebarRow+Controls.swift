import SunsetHelp
import SunsetMetrics
import SwiftUI

/// The controls at a row's end besides its close button: the cup of a row kept awake, the clear button of a row renamed.
extension SidebarRow {
    /// Empties the name being typed; left empty, the row takes back its own title.
    var clearButton: some View {
        ClearNameButton(layout: layout) {
            typed = ""
        }
    }

    /// Kept awake: the close button's size, its symbol's size and weight, in its place while it is hidden. While the
    /// row is pointed at it is a button beside the close button, slashed under the pointer: a click lets the Mac sleep
    /// again.
    @ViewBuilder var awakeMark: some View {
        if showsClose, let stopAwake {
            SwiftUI.Button(action: stopAwake) { cup(slashed: overAwake) }
                .buttonStyle(.plain)
                .keptHover($overAwake)
                .help("Stop Keeping the Mac Awake")
                .accessibilityLabel("Stop Keeping the Mac Awake")
        } else {
            cup(slashed: false)
                .helpTopic(.keepAwake)
                .accessibilityElement()
                .accessibilityLabel("Keeps the Mac awake")
        }
    }

    private func cup(slashed: Bool) -> some View {
        // No slashed cup among the symbols: one cut and slashed as theirs are.
        SlashedSymbol(
            name: "cup.and.saucer.fill",
            size: Design.Symbol.badge,
            weight: Design.Symbol.weight,
            slashed: slashed
        )
        .foregroundStyle(slashed ? Color.primary : Color.secondary)
        .rowEndFace(layout, lit: slashed)
    }

    /// The controls at the row's end after the close button, in their order: the cup, the sound, the microphone, the
    /// camera.
    var endControls: [RowEndControl] {
        var controls: [RowEndControl] = []
        if awake { controls.append(.awake) }
        if let sound = model?.sound { controls.append(.sound(sound)) }
        if let model {
            for device in PaneCapture.Device.allCases {
                if let state = model.devices[device] { controls.append(.device(device, state)) }
            }
        }
        return controls
    }

    @ViewBuilder func endControl(_ control: RowEndControl) -> some View {
        switch control {
            case .awake: awakeMark
            case .sound(let sound):
                RowEndButton(symbol: sound.symbol, help: sound.help, layout: layout) { model?.toggleMuted() }
            case .device(let device, let state):
                RowEndButton(
                    symbol: PaneCapture.symbol(device, state),
                    help: PaneCapture.help(device, state),
                    live: state == .live,
                    layout: layout
                ) { model?.toggle(device) }
        }
    }
}
