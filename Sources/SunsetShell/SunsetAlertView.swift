import AppKit
package import SunsetShellModel
package import SwiftUI

/// An alert drawn in Sunset's look (the owner's note n73): the app's surface, title and text as its panels, the buttons in
/// the order macOS's alerts use; Return and Escape press what the alert says.
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
            HStack(spacing: Design.Space.s) {
                Spacer()
                ForEach(alert.shownOrder, id: \.self) { index in button(index) }
            }
        }
        .padding(Design.Space.xl)
        .frame(width: Design.Width.panel, alignment: .leading)
        .surface(surface.panelShape, shadow: .popover)
    }

    @ViewBuilder private func button(_ index: Int) -> some View {
        let item = alert.buttons[index]
        let role: ButtonRole? =
            switch item.role {
                case .cancel: .cancel
                case .destructive: .destructive
                case .plain: nil
            }
        let base = Button(item.title, role: role) { answer(index) }
        if index == alert.returnButton, item.role != .cancel {
            base.keyboardShortcut(.defaultAction)
        } else if index == alert.escapeButton {
            base.keyboardShortcut(.cancelAction)
        } else {
            base
        }
    }
}
