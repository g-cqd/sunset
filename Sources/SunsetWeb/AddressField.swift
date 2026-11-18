import SunsetShell
package import SwiftUI

/// Where the address of a page is typed (web step b): the field, showing the host until clicked, and a thin line along its bottom edge while the page
/// loads. Used by the sidebar, the window bar and the row of a page. Return opens what was typed and gives the page the keyboard; Escape gives it back.
package struct AddressField: View {
    /// The ends fade out, or are cut (`appearance.ends`, the owner's note n30).
    @Environment(\.fadesEnds) var fadesEnds
    let content: WebContent
    /// Where its list goes.
    var place = AddressTyping.Place.top
    /// Tells whether the field is being typed in (the window bar stays out meanwhile).
    var onEditing: (Bool) -> Void = { _ in }
    /// Copy and Reload (Stop while loading) at its trailing end, while the pointer is over it or the page loads, the text fading
    /// under them as a tab's title does under its buttons (roadmap 0047 F).
    var reload = false
    /// What its context menu adds after the page's own items: the tab's menu (the app's).
    var menu: AnyView?
    @State private var hovering = false
    /// Being typed in: no buttons over its end and no fade, so that the text and the caret are never hidden (note n9).
    @State private var editing = false
    @State private var focusNow = false
    @Environment(\.addressTyping) private var typing
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceStyle) private var surface
    @Environment(\.controlRadius) private var controlRadius

    package init(
        content: WebContent,
        place: AddressTyping.Place = .top,
        reload: Bool = false,
        menu: AnyView? = nil,
        onEditing: @escaping (Bool) -> Void = { _ in }
    ) {
        self.content = content
        self.place = place
        self.reload = reload
        self.menu = menu
        self.onEditing = onEditing
    }

    package var body: some View {
        HStack(spacing: Design.Optical.fieldGlyphToText) {
            if content.isPrivate { PrivateMark() }
            if content.url != nil { SiteButton(content: content) }
            textField.mask { textMask }
            if abs(content.zoom - 1) > 0.001 {
                Button(ZoomLevels.label(content.zoom)) { content.resetZoom() }
                    .buttonStyle(.borderless)
                    .font(Design.Text.detail.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .help("Zoom: click for 100%")
            }
        }
        .overlay(alignment: .trailing) {
            if showsActions {
                HStack(spacing: 0) {
                    if hovering, content.url != nil {
                        FeedbackGlyphButton(symbol: "doc.on.doc", help: "Copy Address") { content.copyAddress() }
                    }
                    reloadButton
                }
                .transition(.opacity)
            }
        }
        .contextMenu { pageMenu }
        .keptHover($hovering)
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
                self.editing = editing
                if editing { typing?.begin(content, place: place) } else if typing?.page === content { endSoon() }
                onEditing(editing)
            },
            onText: { typing?.typed($0) },
            onMove: { typing?.move($0) }
        )
    }

    private var showsActions: Bool {
        Self.showsActions(reload: reload, hovering: hovering, loading: content.isLoading, editing: editing)
    }

    /// Copy and Reload at the end: asked for, under the pointer or loading, and never while it is typed in (note n9).
    static func showsActions(reload: Bool, hovering: Bool, loading: Bool, editing: Bool) -> Bool {
        reload && !editing && (hovering || loading)
    }

    /// The text fades out under the buttons at its end while they show.
    private var textMask: some View {
        HStack(spacing: 0) {
            Color.black
            if showsActions {
                LinearGradient(
                    gradient: .end(from: .black, to: .clear, fading: fadesEnds),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: Design.Space.m)
                Color.clear.frame(width: Design.Space.l * (hovering && content.url != nil ? 2 : 1))
            }
        }
    }

    private var reloadButton: some View {
        RowGlyphButton(
            symbol: content.isLoading ? "xmark" : "arrow.clockwise",
            help: content.isLoading ? "Stop" : "Reload"
        ) {
            if content.isLoading { content.stopLoading() } else { content.reload() }
        }
        .disabled(content.url == nil)
    }

    /// Right-click: the page's own actions, then the tab's (the app's menu).
    @ViewBuilder private var pageMenu: some View {
        Button("Copy Address") { Feedback.give(content.copyAddress()) }.disabled(content.url == nil)
        Button(content.isLoading ? "Stop" : "Reload") {
            if content.isLoading { content.stopLoading() } else { content.reload() }
        }
        .disabled(content.url == nil)
        Button("Edit Address") { focusNow = true }
        Button("Site Settings\u{2026}") { content.showsSiteSettings = true }.disabled(content.url == nil)
        if abs(content.zoom - 1) > 0.001 { Button("Actual Size") { content.resetZoom() } }
        if let menu {
            Divider()
            menu
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
