import AppKit
import SwiftUI
import WebKit

/// What a page's pane shows: the page; over it, for an empty page, a field for an address (until the address bar of web step b), and for a page that
/// failed, what failed with Try Again (and Visit Anyway, after a warning, for a certificate).
struct WebPaneView: View {
    let content: WebContent
    let focused: Bool
    let topInset: Double
    @State private var typed = ""
    @State private var warning = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ZStack {
            if let webView = content.webView {
                WebViewHost(webView: webView, focused: focused && content.url != nil && content.failure == nil)
            }
            if content.url == nil, content.webView?.url == nil { empty }
            if let failure = content.failure { failed(failure) }
        }
        .padding(.top, topInset)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var empty: some View {
        VStack(spacing: 10) {
            Image(systemName: "globe").font(.system(size: 28)).foregroundStyle(.tertiary)
            TextField("Address", text: $typed)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 420)
                .focused($fieldFocused)
                .onSubmit { content.open(typed: typed) }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { fieldFocused = focused }
        .onChange(of: focused) { _, now in if now { fieldFocused = true } }
    }

    private func failed(_ failure: WebFailure) -> some View {
        VStack(spacing: 10) {
            Image(systemName: failure.isCertificate ? "lock.trianglebadge.exclamationmark" : "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Sunset could not open this page").font(.title3)
            Text(failure.reason).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let url = failure.url {
                Text(url.absoluteString).font(.callout.monospaced()).foregroundStyle(.tertiary).textSelection(.enabled)
            }
            HStack {
                Button("Try Again") { content.reload() }.keyboardShortcut(.defaultAction)
                if failure.isCertificate { Button("Visit Anyway\u{2026}") { warning = true } }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Visit this page anyway?", isPresented: $warning) {
            Button("Cancel", role: .cancel) {}
            Button("Visit Anyway", role: .destructive) { content.acceptCertificate() }
        } message: {
            Text(
                "The system does not trust this site's certificate: someone may be pretending to be it. Continue only if you know the site (your own server, for instance). Sunset accepts it for this page until it closes."
            )
        }
    }
}
