package import SwiftUI

/// Where the address of a page is typed (web step b): the field, showing the host until clicked, and a thin line along its bottom edge while the page
/// loads. Used by the sidebar, the window bar and the row of a page. Return opens what was typed and gives the page the keyboard; Escape gives it back.
package struct AddressField: View {
    let content: WebContent
    /// Tells whether the field is being typed in (the window bar stays out meanwhile).
    var onEditing: (Bool) -> Void = { _ in }
    @State private var focusNow = false

    package init(content: WebContent, onEditing: @escaping (Bool) -> Void = { _ in }) {
        self.content = content
        self.onEditing = onEditing
    }

    package var body: some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        AddressTextField(
            host: content.shownHost,
            address: content.url?.absoluteString ?? "",
            focusNow: $focusNow,
            onSubmit: { typed in
                content.open(typed: typed)
                content.focusPage()
            },
            onCancel: { content.focusPage() },
            onEditing: onEditing
        )
        .padding(.horizontal, 8)
        .frame(height: 26)
        .background(shape.fill(Color.primary.opacity(0.08)))
        .overlay(alignment: .bottomLeading) { progressLine }
        .clipShape(shape)
        .onAppear { takeKeyboardIfAsked() }
        .onChange(of: content.wantsAddress) { _, _ in takeKeyboardIfAsked() }
    }

    private var progressLine: some View {
        GeometryReader { proxy in
            if let progress = content.progress {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: proxy.size.width * max(progress, 0.05), height: 2)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .animation(.easeOut(duration: 0.2), value: progress)
            }
        }
    }

    private func takeKeyboardIfAsked() {
        guard content.wantsAddress else { return }
        content.wantsAddress = false
        focusNow = true
    }
}
