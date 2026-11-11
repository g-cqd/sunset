import SwiftUI

/// A page in a pane: a row with back, forward, reload and the address, and the page under it.
struct WebPaneView: View {
    @Bindable var content: WebContent
    let focused: Bool
    @FocusState private var typing: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                button("chevron.left", "Back", enabled: content.canGoBack) { content.back() }
                button("chevron.right", "Forward", enabled: content.canGoForward) { content.forward() }
                button(content.progress == nil ? "arrow.clockwise" : "xmark", "Reload", enabled: content.address != nil)
                {
                    content.reload()
                }
                TextField("Address or search", text: $content.typed)
                    .textFieldStyle(.roundedBorder)
                    .focused($typing)
                    .onSubmit { content.go() }
            }
            .padding(6)
            .background(.bar)
            WebRepresentable(content: content, focused: focused && !typing)
        }
        .onChange(of: typing) { _, now in if now { content.onFocusRequest() } }
        // A page with no address yet starts in its field.
        .onAppear { if content.address == nil { typing = true } }
    }

    private func button(_ symbol: String, _ help: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).frame(width: 18, height: 18) }
            .buttonStyle(.borderless)
            .disabled(!enabled)
            .help(help)
    }
}
