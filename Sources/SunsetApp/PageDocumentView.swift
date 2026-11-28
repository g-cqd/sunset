import MarkdownLookKit
import SunsetConfig
import SunsetDocuments
import SunsetMarkdown
import SunsetRuntime
import SunsetShell
import SunsetWeb
import SwiftUI

/// A page document (HTML, XHTML, SVG) drawn by WebKit (`DocumentContent.pageView`): its text drawn again a moment after
/// the last keystroke, its links opened as a document's are.
struct PageDocumentView: View {
    @Environment(\.runtime) private var runtime
    let content: DocumentContent
    /// The text drawn: the editor's, a moment after it last changed.
    @State private var drawn: String?

    /// How long the text rests before it is drawn again.
    private static let rest = Duration.milliseconds(250)

    var body: some View {
        let source = content.document.source
        LocalPageView(
            text: drawn ?? source.text,
            file: content.file,
            allowsNetwork: AppConfiguration.shared.configuration.documents.pagesReachNetwork,
            onLink: { content.open(link: $0) }
        )
        .task(id: source.revision) {
            guard drawn != nil else {
                drawn = source.text
                return
            }
            guard await runtime.sleep(for: Self.rest) else { return }
            drawn = source.text
        }
        .simultaneousGesture(TapGesture().onEnded { content.onFocusRequest() })
    }
}
