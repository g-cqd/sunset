import SunsetConfig
import SwiftUI

/// One small tab inside a split tab's container: its title, a slight highlight under the pointer, and, when it is the focused pane of the selected tab, a
/// stronger one with the same hairline the selected tab row has.
struct SidebarGroupPart: View {
    let model: TerminalModel?
    let lit: Bool
    let layout: Configuration.Layout
    let select: () -> Void
    @State private var hovering = false
    @Environment(\.controlActiveState) private var activeState

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: max(layout.tabRadius - 2, 2), style: .continuous)
        TabLabel(model: model, showTitle: true, showDirectory: false, showProgress: false)
            .frame(maxWidth: .infinity, minHeight: layout.closeButtonSize, alignment: .leading)
            .padding(.horizontal, 4)
            .background(shape.fill(highlight))
            .overlay { shape.hairline(layout).opacity(lit ? 1 : 0) }
            .contentShape(shape)
            .onHover { hovering = $0 }
            .animation(layout.smooth, value: hovering)
            .animation(layout.smooth, value: lit)
            .animation(layout.smooth, value: activeState)
            .onTapGesture(perform: select)
    }

    private var highlight: Color {
        switch (lit, hovering) {
            case (true, true): .primary.opacity(activeState == .inactive ? 0.12 : 0.2)
            case (true, false): .primary.opacity(activeState == .inactive ? 0.1 : 0.16)
            case (false, true): .primary.opacity(0.08)
            case (false, false): .clear
        }
    }
}
