internal import MarkdownLookKit
internal import SunsetDocuments
internal import SwiftUI

/// Some blocks of a document drawn as the page draws them, with no page around them: a part of the page between two
/// conflicts, or one side of a conflict. Parsed by themselves, so a link to a reference defined in another part does not
/// resolve here; the page is whole again once the conflicts are answered.
struct PagePartView: View, Equatable {
    let text: String
    let kind: DocumentKind
    let settings: ViewerSettings

    var body: some View {
        let size = CGFloat(settings.textSize)
        if kind == .markdown {
            NativeDocumentColumn(
                document: LabSession(text: text).nativeDocument(settings: settings),
                settings: settings
            )
            // The column has a page's margins above and below: taken back, a part is not a page.
            .padding(.top, -size * 3.5)
            .padding(.bottom, -size * 5)
        } else {
            Text(text)
                .font(.system(size: size, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, size * 2.5)
        }
    }
}
