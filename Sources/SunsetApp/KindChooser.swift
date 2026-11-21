import SunsetPane
import SunsetShell
import SunsetWeb
import SwiftUI

/// Which kind of tab to make (Shift-Cmd-T; the owner's note n69): a terminal, a web page or a document, each of those on.
/// T, W and D pick; Escape closes.
struct KindChooser: View {
    let tabs: TabsModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.l) {
            Text("New Tab").font(Design.Text.title)
            HStack(spacing: Design.Space.l) {
                if tabs.scopes.terminal {
                    choice("Terminal", symbol: "terminal", key: "t") {
                        AppActions.shared.newTab(kind: PaneDescriptor.terminal(directory: nil))
                    }
                }
                if tabs.scopes.web {
                    choice("Web Page", symbol: "globe", key: "w") {
                        AppActions.shared.newTab(kind: PaneContentKinds.newPage)
                    }
                }
                if tabs.scopes.documents {
                    choice("Document", symbol: "doc.text", key: "d") {
                        AppActions.shared.newDocument()
                    }
                }
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(Design.Space.xxl)
    }

    private func choice(
        _ title: String,
        symbol: String,
        key: KeyEquivalent,
        make: @escaping () -> Void
    ) -> some View {
        Button {
            dismiss()
            make()
        } label: {
            VStack(spacing: Design.Space.s) {
                Image(systemName: symbol).font(.system(size: Design.Symbol.large))
                Text(title)
                Text(String(key.character).uppercased()).font(Design.Text.detail).foregroundStyle(.secondary)
            }
            .frame(width: 110, height: 84)
        }
        .keyboardShortcut(key, modifiers: [])
    }
}
