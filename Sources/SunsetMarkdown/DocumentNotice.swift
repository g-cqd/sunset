internal import SunsetShell
internal import SwiftUI

/// One line said above a document, with what can be done about it.
struct DocumentNotice<Actions: View>: View {
    let symbol: String
    let text: String
    @ViewBuilder var actions: Actions

    var body: some View {
        HStack(spacing: Design.Space.m) {
            Image(systemName: symbol).foregroundStyle(.secondary)
            Text(text).font(Design.Text.detail).lineLimit(2)
            Spacer(minLength: Design.Space.m)
            actions.controlSize(.small)
        }
        .padding(.horizontal, Design.Space.l)
        .padding(.vertical, Design.Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5))
    }
}

extension DocumentNotice where Actions == EmptyView {
    init(symbol: String, text: String) {
        self.init(symbol: symbol, text: text) { EmptyView() }
    }
}
