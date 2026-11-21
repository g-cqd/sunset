import AppKit
import SunsetShell
import SunsetShellModel
import SwiftUI
import WebKit

/// What a page's pane shows: the page, under its address row when the address is typed in each page (`webAddressRow`); over it, for an empty page,
/// a globe, and for a page that failed, what failed with Try Again (and Visit Anyway, after a warning, for a certificate).
struct WebPaneView: View {
    let content: WebContent
    let focused: Bool
    @Environment(\.windowBarHostsFind) private var findInWindowBar
    let topInset: Double
    /// The terminal's background: behind what is not a page (the empty pane, a page that failed).
    let backdrop: PaneBackdrop
    @State private var warning = false
    /// Its floating address row is typed in: it stays out.
    @State private var rowTyping = false
    @Environment(\.webAddressRow) private var addressRow
    @Environment(\.permissionsInSidebar) private var permissionsInSidebar
    @Environment(\.addressTyping) private var typing

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                if let webView = content.webView {
                    WebViewHost(webView: webView, focused: focused && content.url != nil && content.failure == nil)
                        // A view made again (Reload As) is a new host.
                        .id(ObjectIdentifier(webView))
                        // No page to show: its blank does not show through a background that is not opaque.
                        .opacity(isEmpty || content.failure != nil ? 0 : 1)
                }
                if isEmpty { empty }
                if let failure = content.failure { failed(failure) }
                if let request = content.permissionRequest, !permissionsInSidebar {
                    PermissionPanel(request: request, store: content.permissions)
                        .frame(maxWidth: .infinity, alignment: .leading).id(request.id)
                }
                if let link = content.hoveredLink {
                    LinkStatusLabel(text: link)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .transition(.opacity)
                }
                if let request = content.credentialRequest {
                    CredentialPanel(request: request)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .id(request.id)
                        .transition(.opacity)
                }
                if let request = content.shareRequest {
                    SharePanel(request: request, host: content.url?.host() ?? "This page")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .id(request.id)
                        .transition(.opacity)
                }
                if let dialog = content.dialog {
                    PageDialogPanel(dialog: dialog) { content.silenceDialogs() }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .id(dialog.id)
                        .transition(.opacity)
                }
                // The container stays and the bar comes and goes inside it: a glass container that leaves takes its glass
                // with it at once, and the bar did not slide away (the owner's note n43).
                GlassEffectContainer(spacing: Design.Space.m) {
                    if content.find.isOpen, !(focused && findInWindowBar) {
                        WebFindBar(content: content)
                            .transition(BarGroupSlide.transition(atTop: true, inset: Design.Space.m))
                    }
                }
                .barGroupBlurs()
                .padding(Design.Space.m)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .allowsHitTesting(content.find.isOpen)
                // The page's own address row floats over its top, revealed there (roadmap 0055 D); the page keeps its top.
                if addressRow {
                    FloatingEdgeBar(atTop: true, hides: true, typing: rowTyping || content.wantsAddress) {
                        AddressField(content: content, place: .pane) { rowTyping = $0 }
                            .padding(.horizontal, Design.Space.m)
                            .padding(.vertical, Design.Space.s)
                    }
                    .padding(.top, Self.addressRowTop(topInset: topInset))
                }
                if addressRow, let typing { AddressSuggestionList(typing: typing, places: [.pane], page: content) }
            }
        }
        .padding(.top, Self.contentTop(topInset: topInset, addressRow: addressRow))
        // The page's own colour, above it too (the strip that drags the window; note n71).
        .background(pageColor)
        .animation(BarGroupSlide.animation, value: content.find.isOpen)
    }

    /// How far below the pane's top the page starts. The strip that drags a window with no title bar (the floating sidebar's)
    /// lies over the page, which reaches the top as a docked card does: pushed below it, the page left a band of its colour
    /// (the owner, 2026-11-18: "an odd blank space at the top", roadmap 0045 D). A row of the page's own address is kept
    /// below it, out of the strip.
    static func contentTop(topInset: Double, addressRow: Bool) -> Double {
        0
    }

    /// Where the page's floating address row is: below the strip.
    static func addressRowTop(topInset: Double) -> Double {
        topInset
    }

    private var isEmpty: Bool {
        content.url == nil && content.webView?.url == nil
    }

    /// Behind a page, its own colour; behind no page or one that failed, the terminal's background, as every pane (the owner,
    /// 2026-11-15).
    private var pageColor: Color {
        if isEmpty || content.failure != nil { return backdrop.color }
        return content.pageBackground.map { Color(nsColor: $0) } ?? backdrop.color
    }

    private var empty: some View {
        Image(systemName: "globe")
            .font(.system(size: Design.Symbol.hero))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .paneBackdrop(backdrop)
    }

    private func failed(_ failure: WebFailure) -> some View {
        VStack(spacing: Design.Space.l) {
            Image(systemName: failure.isCertificate ? "lock.trianglebadge.exclamationmark" : "exclamationmark.triangle")
                .font(.system(size: Design.Symbol.hero))
                .foregroundStyle(.secondary)
            Text(failure.heading).font(Design.Text.heading)
            Text(failure.reason).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let url = failure.url {
                Text(url.absoluteString).font(Design.Text.secondary).code().foregroundStyle(.tertiary)
                    .textSelection(.enabled)
            }
            HStack {
                Button("Try Again") { content.reload() }.keyboardShortcut(.defaultAction)
                if failure.isCertificate { Button("Visit Anyway\u{2026}") { warning = true } }
                // HTTPS failed and the settings ask (`web.httpsUpgrade` "ask"): the same address over http, for this page.
                if content.offersHTTP(after: failure) {
                    Button("Load over HTTP") { content.loadOverHTTP() }
                        .help(
                            "This site did not answer over HTTPS. Over HTTP what you send and see can be read on the way."
                        )
                }
            }
        }
        .padding(Design.Space.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paneBackdrop(backdrop)
        .sunsetAlert(
            isPresented: $warning,
            SunsetAlert(
                title: "Visit this page anyway?",
                message: "The system does not trust this site's certificate: someone may be pretending to be it. "
                    + "Continue only if you know the site (your own server, for instance). Sunset accepts it for this "
                    + "page until it closes.",
                buttons: [.cancel("Cancel"), .destructive("Visit Anyway")],
                defaultButton: 0
            )
        ) { pressed in
            if pressed == 1 { content.acceptCertificate() }
        }
    }
}
