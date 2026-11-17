internal import MarkdownLookKit
internal import SunsetDocuments
internal import SunsetShell
internal import SwiftUI

/// The page while conflicts wait (roadmap 0023 step M-e): the document in parts, each conflict on its block, with what is
/// here and what the disk says one above the other and the answers under them. Once all are answered the page is drawn whole
/// again, by the kit's own view (which this is not: no selection across parts, and links within the page do not jump).
struct ConflictedPageView: View {
    let content: DocumentContent

    var body: some View {
        let document = content.document
        // Read so that the parts are made again when the text changes.
        let _ = document.source.revision
        let parts = PageParts.of(document.source.text, conflicts: document.conflicts)
        let settings = document.source.settings
        let size = CGFloat(settings.textSize)
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: size) {
                    ForEach(parts) { part in
                        if let conflict = part.conflict {
                            ConflictCard(content: content, conflict: conflict, mine: part.text)
                                .clipShape(RoundedRectangle(cornerRadius: Design.Space.m))
                                .padding(.horizontal, size)
                                .id(part.id)
                        } else {
                            PagePartView(text: part.text, kind: document.kind, settings: settings).equatable()
                        }
                    }
                }
                .padding(.top, size * 3.5)
                .padding(.bottom, size * 5)
            }
            .bouncesOnlyWhenScrolling()
            .onChange(of: content.reveal) {
                withAnimation { proxy.scrollTo(content.shownConflict, anchor: .center) }
            }
            .onAppear { proxy.scrollTo(content.shownConflict ?? document.conflicts.first?.id, anchor: .center) }
        }
    }
}
