package import SwiftUI

/// Where the address of a page is typed (web step b): the field, showing the host until clicked, and a thin line along its bottom edge while the page
/// loads. Used by the sidebar, the window bar and the row of a page. Return opens what was typed and gives the page the keyboard; Escape gives it back.
package struct AddressField: View {
    let content: WebContent
    /// Where its list goes.
    var place = AddressTyping.Place.top
    /// Tells whether the field is being typed in (the window bar stays out meanwhile).
    var onEditing: (Bool) -> Void = { _ in }
    @State private var focusNow = false
    @Environment(\.addressTyping) private var typing

    package init(content: WebContent, place: AddressTyping.Place = .top, onEditing: @escaping (Bool) -> Void = { _ in })
    {
        self.content = content
        self.place = place
        self.onEditing = onEditing
    }

    package var body: some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        HStack(spacing: 4) {
            if content.url != nil { SiteButton(content: content) }
            textField
            if abs(content.zoom - 1) > 0.001 {
                Button(ZoomLevels.label(content.zoom)) { content.resetZoom() }
                    .buttonStyle(.borderless)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .help("Zoom: click for 100%")
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 26)
        .background(shape.fill(Color.primary.opacity(0.08)))
        .overlay(alignment: .bottomLeading) { progressLine }
        .clipShape(shape)
        .onAppear { takeKeyboardIfAsked() }
        .onChange(of: content.wantsAddress) { _, _ in takeKeyboardIfAsked() }
    }

    private var textField: some View {
        AddressTextField(
            host: content.shownHost,
            address: content.url?.absoluteString ?? "",
            focusNow: $focusNow,
            onSubmit: { typed in
                if let typing, typing.page === content, typing.isActive {
                    typing.take()
                } else {
                    typing?.end()
                    content.open(typed: typed)
                    content.focusPage()
                }
            },
            onCancel: {
                typing?.end()
                content.focusPage()
            },
            onEditing: { editing in
                if editing { typing?.begin(content, place: place) } else if typing?.page === content { endSoon() }
                onEditing(editing)
            },
            onText: { typing?.typed($0) },
            onMove: { typing?.move($0) }
        )
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

    /// The field stopped being typed in (a click elsewhere): the list goes a moment later, so that a click on one of its rows is taken first.
    private func endSoon() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            if typing?.page === content, !(content.webView?.window?.firstResponder is NSTextView) { typing?.end() }
        }
    }

    private func takeKeyboardIfAsked() {
        guard content.wantsAddress else { return }
        content.wantsAddress = false
        focusNow = true
    }
}
