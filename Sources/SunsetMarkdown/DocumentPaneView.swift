internal import MarkdownLookKit
internal import SunsetDocuments
internal import SunsetShell
internal import SwiftUI

/// What a document pane draws: what is to be said about the file, then the page or the source.
struct DocumentPaneView: View {
    let content: DocumentContent
    let context: PaneViewContext
    /// The merge whose blocks are tinted just now.
    @State private var flash: DocumentMergeNotice?

    private var document: OpenDocument { content.document }
    /// A file that was not read as text has nothing to show or to edit.
    private var hasText: Bool { document.problem != .notText && document.problem != .unreadable }

    var body: some View {
        VStack(spacing: 0) {
            DocumentNotices(content: content)
            if !hasText {
                Color.clear
            } else if content.mode == .rendered, !document.conflicts.isEmpty {
                // Each conflict on its block; the page is whole again once they are answered.
                ConflictedPageView(content: content)
                    .simultaneousGesture(TapGesture().onEnded { content.onFocusRequest() })
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
                .background(marks)
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
        .task(id: document.lastMerge?.id) { await show(document.lastMerge) }
    }

    /// The marks of a merge in this pane's source editor: read only while there is something to mark, so that typing in a
    /// document with none costs this view nothing.
    private var marks: some View {
        let conflicts = document.conflicts
        let live = !conflicts.isEmpty || flash != nil
        let revision = live ? document.source.revision : -1
        return SourceMarksFinder(
            content: content,
            conflicts: conflicts,
            revision: revision,
            merged: flash.map { $0.revision == revision ? $0.ranges : [] } ?? [],
            reveal: content.reveal,
            fontSize: content.fontSize
        )
    }

    /// A merge just put blocks in: they are tinted for a moment, and the line that says so stays a little longer.
    private func show(_ merge: DocumentMergeNotice?) async {
        guard let merge else { return }
        flash = merge
        try? await Task.sleep(for: .milliseconds(1800))
        flash = nil
        try? await Task.sleep(for: .seconds(5))
        if !Task.isCancelled, document.lastMerge?.id == merge.id { document.dismissMerge() }
    }
}
