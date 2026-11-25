import SunsetShell
import SunsetTerminalModel
package import SwiftUI

/// A terminal pane: the AppKit terminal surface with a floating top-trailing `FindBarView` when Cmd-F is active
/// (T-3 / roadmap 0026).
package struct TerminalPaneView: View {
    package let model: TerminalModel
    package var optionAsMeta: Bool
    package var translucent = false
    package var focused = true
    package var topInset = 0.0

    package var body: some View {
        ZStack {
            TerminalRepresentable(
                model: model,
                optionAsMeta: optionAsMeta,
                translucent: translucent,
                focused: focused
            )
            GlassEffectContainer(spacing: Design.Space.m) {
                if model.find.isOpen {
                    FindBarView(model: model.find, atTop: true)
                        .transition(BarGroupSlide.transition(atTop: true, inset: Design.Space.m))
                }
            }
            .barGroupBlurs()
            .padding(Design.Space.m)
            .padding(.top, topInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .allowsHitTesting(model.find.isOpen)
        }
    }
}
