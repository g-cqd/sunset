import SunsetPane
import SunsetShell
import SunsetWeb
import SwiftUI

/// Which kind of tab to make (Shift-Cmd-T, the owner's answer in web step a): a terminal or a web page. T and W pick, Escape closes.
struct KindChooser: View {
    let tabs: TabsModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.l) {
            Text("New Tab").font(Design.Text.title)
            HStack(spacing: Design.Space.l) {
                choice("Terminal", symbol: "terminal", key: "t", kind: PaneDescriptor.terminal(directory: nil))
                choice("Web Page", symbol: "globe", key: "w", kind: PaneContentKinds.newPage)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
            }
        }
        .padding(Design.Space.xxl)
    }

    private func choice(_ title: String, symbol: String, key: KeyEquivalent, kind: PaneDescriptor) -> some View {
        Button {
            dismiss()
            AppActions.shared.newTab(kind: kind)
        } label: {
            VStack(spacing: Design.Space.s) {
                Image(systemName: symbol).font(.system(size: Design.Symbol.large))
                Text(title)
            }
            .frame(width: 110, height: 70)
        }
        .keyboardShortcut(key, modifiers: [])
    }
}
