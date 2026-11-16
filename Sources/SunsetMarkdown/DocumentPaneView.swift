internal import MarkdownLookKit
internal import SunsetDocuments
internal import SunsetShell
internal import SwiftUI

/// What a document pane draws: what is to be said about the file, then the page or the source.
struct DocumentPaneView: View {
    let content: DocumentContent
    let context: PaneViewContext

    private var document: OpenDocument { content.document }
    /// A file that was not read as text has nothing to show or to edit.
    private var hasText: Bool { document.problem != .notText && document.problem != .unreadable }

    var body: some View {
        VStack(spacing: 0) {
            DocumentNotices(content: content)
            if !hasText {
                Color.clear
            } else if content.mode == .rendered {
                NativeDocumentView(
                    document: document.page.shown,
                    settings: document.source.settings,
                    base: content.base,
                    onLink: { content.open(link: $0) }
                )
                .simultaneousGesture(TapGesture().onEnded { content.onFocusRequest() })
            } else {
                MarkdownSourceEditor(
                    source: document.source,
                    configuration: MarkdownEditorConfiguration(fontSize: content.fontSize),
                    proxy: content.proxy
                )
                .onChange(of: content.proxy.isFocused) { _, focused in
                    if focused { content.onFocusRequest() }
                }
                .task { if context.focused { content.proxy.focus() } }
            }
        }
        .padding(.top, context.topInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // On the terminal's background, as every pane (the owner, 2026-11-15).
        .paneBackdrop(context.backdrop)
    }
}
