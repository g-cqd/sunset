internal import SunsetDocuments
internal import SunsetShell
internal import SwiftUI

/// What a document pane says above its text: that the file is gone or did not read, that it changed on disk under edits
/// made here (until step M-e merges them: reload, or keep these), that a save failed (one asked for here, or one the
/// document made by itself).
struct DocumentNotices: View {
    let content: DocumentContent

    var body: some View {
        let document = content.document
        VStack(spacing: 0) {
            if let problem = document.problem {
                DocumentNotice(symbol: "exclamationmark.triangle", text: Self.sentence(for: problem))
            }
            if document.changedOnDisk {
                DocumentNotice(
                    symbol: "arrow.triangle.2.circlepath",
                    text: "This file changed on disk after you edited it here."
                ) {
                    Button("Reload from Disk") { document.reloadFromDisk() }
                    Button("Keep Mine") { document.keepEdits() }
                }
            }
            if let failure = content.failure ?? document.saveFailure {
                DocumentNotice(symbol: "xmark.octagon", text: failure) {
                    Button("Dismiss") {
                        content.failure = nil
                        document.saveFailure = nil
                    }
                }
            }
        }
    }

    static func sentence(for problem: OpenDocumentProblem) -> String {
        switch problem {
            case .missing: "This file is not on disk. Saving writes it."
            case .unreadable: "This file could not be read."
            case .notText: "This file is not text, so it is not shown."
        }
    }
}
