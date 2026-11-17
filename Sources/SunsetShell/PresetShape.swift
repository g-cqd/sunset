import SunsetPane
import SwiftUI

/// A preset drawn as its shape: its panes as rounded cells, as the green light's panel draws window tiles.
struct PresetShape: View {
    let preset: SplitPreset
    @Environment(\.isEnabled) private var enabled

    var body: some View {
        Canvas { context, size in
            let panes = (0 ..< preset.paneCount).map { _ in PaneID() }
            let frames = preset.layout(of: panes).frames(in: CGRect(origin: .zero, size: size), gap: Design.Space.hair)
            for pane in panes {
                guard let frame = frames[pane] else { continue }
                let cell = Path(roundedRect: frame, cornerRadius: Design.Space.hair)
                context.fill(cell, with: .color(.accentColor.opacity(enabled ? 1 : Design.Fill.notApplicable)))
            }
        }
        .frame(width: Design.Size.presetShapeWidth, height: Design.Size.presetShapeHeight)
    }
}
