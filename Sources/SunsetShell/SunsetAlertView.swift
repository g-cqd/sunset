import AppKit
package import SunsetShellModel
package import SwiftUI

/// An alert drawn in Sunset's look: the app's surface, title and text as its panels, the buttons in the order macOS's
/// alerts use; Return and Escape press what the alert says.
package struct SunsetAlertView: View {
    let alert: SunsetAlert
    let answer: (Int) -> Void
    @Environment(\.surfaceStyle) private var surface

    package init(alert: SunsetAlert, answer: @escaping (Int) -> Void) {
        self.alert = alert
        self.answer = answer
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.l) {
            HStack(alignment: .top, spacing: Design.Space.l) {
                if let data = alert.icon, let image = NSImage(data: Data(data)) {
                    Image(nsImage: image).resizable().frame(width: Design.Size.alertIcon, height: Design.Size.alertIcon)
                }
                VStack(alignment: .leading, spacing: Design.Space.s) {
                    Text(alert.title).font(Design.Text.body.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    if !alert.message.isEmpty {
                        Text(alert.message).font(Design.Text.body).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            if let preview = alert.preview {
                ScrollView {
                    Text(preview).font(.system(.callout, design: .monospaced)).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .bouncesOnlyWhenScrolling()
                .frame(maxHeight: Design.Size.dialogMessage)
                .padding(Design.Space.s)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: Design.Radius.small(surface.layout)))
            }
            // In a row when they fit, else one under another, the default at the bottom: never a label cut short.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Design.Space.s) {
                    Spacer()
                    ForEach(alert.shownOrder, id: \.self) { index in button(index).fixedSize() }
                }
                VStack(spacing: Design.Space.s) {
                    ForEach(alert.shownOrder, id: \.self) { index in button(index, wide: true) }
                }
            }
        }
        .background { escapeKey }
        .padding(Design.Space.xl)
        .frame(width: Design.Width.panel, alignment: .leading)
        // No panel of its own: it is always in a sheet, which macOS draws (seen: Sunset's panel, its stroke and shadow,
        // inside the sheet's: two frames one in the other).
    }

    /// Escape, when the button it presses already answers Return.
    @ViewBuilder private var escapeKey: some View {
        if let escape = alert.escapeButton, escape == alert.returnButton {
            Button("") { answer(escape) }.keyboardShortcut(.cancelAction).opacity(0).accessibilityHidden(true)
        }
    }

    @ViewBuilder private func button(_ index: Int, wide: Bool = false) -> some View {
        let item = alert.buttons[index]
        let role: ButtonRole? =
            switch item.role {
                case .cancel: .cancel
                case .destructive: .destructive
                case .plain: nil
            }
        let base = Button(role: role) {
            answer(index)
        } label: {
            Text(item.title).foregroundStyle(item.role == .destructive ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
                .frame(maxWidth: wide ? .infinity : nil)
        }
        // The default button is drawn as one (Return); a Cancel that is also the default answers Escape through
        // `escapeKey` (a button takes one shortcut).
        if index == alert.returnButton {
            base.keyboardShortcut(.defaultAction)
        } else if index == alert.escapeButton {
            base.keyboardShortcut(.cancelAction)
        } else {
            base
        }
    }
}
