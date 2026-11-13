import SunsetShell
package import SwiftUI

/// Where the address of a page is typed (web step b): the field, showing the host until clicked, and a thin line along its bottom edge while the page
/// loads. Used by the sidebar, the window bar and the row of a page. Return opens what was typed and gives the page the keyboard; Escape gives it back.
package struct AddressField: View {
    let content: WebContent
    /// Where its list goes.
    var place = AddressTyping.Place.top
    /// Tells whether the field is being typed in (the window bar stays out meanwhile).
    var onEditing: (Bool) -> Void = { _ in }
    /// Reload (Stop while loading) at its trailing end, while the pointer is over it or the page loads.
    var reload = false
    @State private var hovering = false
    @State private var focusNow = false
    @Environment(\.addressTyping) private var typing
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceStyle) private var surface
    @Environment(\.controlRadius) private var controlRadius

    package init(
        content: WebContent,
        place: AddressTyping.Place = .top,
        reload: Bool = false,
        onEditing: @escaping (Bool) -> Void = { _ in }
    ) {
        self.content = content
        self.place = place
        self.reload = reload
        self.onEditing = onEditing
    }

    package var body: some View {
        HStack(spacing: Design.Optical.fieldGlyphToText) {
            if content.isPrivate { PrivateMark() }
            if content.url != nil { SiteButton(content: content) }
            textField
            if abs(content.zoom - 1) > 0.001 {
                Button(ZoomLevels.label(content.zoom)) { content.resetZoom() }
                    .buttonStyle(.borderless)
                    .font(Design.Text.detail.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .help("Zoom: click for 100%")
            }
            if reload, hovering || content.isLoading { reloadButton.transition(.opacity) }
        }
        .onHover { inside in hovering = inside }
        .animation(.easeOut(duration: 0.15), value: hovering)
        // A private page's field is dark, its text light (web step h).
        .fieldSurface(dark: content.isPrivate)
        .clipShape(RoundedRectangle(cornerRadius: controlRadius ?? surface.leafRadius, style: .continuous))
        .environment(\.colorScheme, content.isPrivate ? .dark : colorScheme)
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

    private var reloadButton: some View {
        Button {
            if content.isLoading { content.stopLoading() } else { content.reload() }
        } label: {
            Image(systemName: content.isLoading ? "xmark" : "arrow.clockwise")
                .font(Design.Text.detail.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help(content.isLoading ? "Stop" : "Reload")
        .disabled(content.url == nil)
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
