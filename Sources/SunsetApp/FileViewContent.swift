import Observation
import SunsetPane
import SunsetShell
import SwiftUI

/// A file only looked at (a PDF, a picture, a sound or a film) as the content of a pane: drawn by the system's own viewer
/// for it (`FileViewer`). It has no text to edit; the file stays where it is.
@MainActor @Observable
final class FileViewContent: PaneContent, PaneViewMaking {
    static let kind = PaneDescriptor.fileViewKind

    let path: String
    let viewed: FileViewed
    @ObservationIgnored var onExit: () -> Void = {}
    @ObservationIgnored var onFocusRequest: () -> Void = {}

    /// The viewer a saved descriptor names; nil when it names no file only looked at.
    init?(_ descriptor: PaneDescriptor) {
        guard let path = descriptor.state["file"],
            let viewed = FileViewed(extension: (path as NSString).pathExtension)
        else { return nil }
        self.path = path
        self.viewed = viewed
    }

    var url: URL {
        URL(fileURLWithPath: path)
    }

    // MARK: PaneContent

    var title: String {
        (path as NSString).lastPathComponent
    }
    var detail: String? {
        (path as NSString).deletingLastPathComponent
    }
    var glyph: PaneGlyph {
        switch viewed {
            case .pdf: .symbol("doc.richtext")
            case .picture: .symbol("photo")
            case .media: .symbol("play.rectangle")
        }
    }
    var progress: Double? {
        nil
    }
    var closeWarning: String? {
        nil
    }
    var searchTerms: [String] {
        [title, path]
    }
    var descriptor: PaneDescriptor {
        PaneDescriptor(kind: Self.kind, state: ["file": path, "title": title])
    }

    func setState(focused: Bool, visible: Bool) {}
    func stop() {}
    func makeView(_ context: PaneViewContext) -> AnyView {
        AnyView(
            FileViewer(url: url, viewed: viewed)
                .padding(.top, context.topInset)
                .paneBackdrop(context.backdrop)
                .simultaneousGesture(TapGesture().onEnded { [weak self] in self?.onFocusRequest() })
        )
    }
}
