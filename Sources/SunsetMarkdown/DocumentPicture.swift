internal import MarkdownLookKit
internal import SunsetDocuments
internal import SwiftUI

/// What a document's picture draws (`DocumentContent.takePicture`): rendered, the page's rows as a column with no scroll view
/// (AemiMarkdown's `NativeDocumentColumn`, made for snapshots); as source, its first lines in the editor's font. The top of the
/// document, at the size the pane had.
struct DocumentPicture: View {
    let content: DocumentContent
    let size: CGSize

    /// The most of the source's lines drawn: more than a pane shows.
    private static let sourceLines = 120

    var body: some View {
        Group {
            if content.mode == .rendered, content.hasNativePage {
                NativeDocumentColumn(document: content.document.page.shown, settings: content.document.source.settings)
            } else {
                Text(
                    content.document.source.text.split(separator: "\n", omittingEmptySubsequences: false)
                        .prefix(Self.sourceLines).joined(separator: "\n")
                )
                .font(.system(size: content.fontSize, design: .monospaced))
                .padding(content.fontSize)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipped()
    }
}
