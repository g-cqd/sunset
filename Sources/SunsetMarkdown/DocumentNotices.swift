internal import MarkdownLookKit
internal import SunsetDocuments
internal import SunsetShell
internal import SwiftUI

/// What a document pane says above its text: that the file is gone or did not read, that it stopped being text on disk
/// under edits made here (reload, or keep these), that a change on disk was merged (what was put in, which can be
/// undone, and the blocks that wait for an answer), that a save failed (one asked for here, or one the document made by
/// itself).
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
                    text: "This file changed on disk after you edited it here, and is no longer text."
                ) {
                    Button("Reload from Disk") { document.reloadFromDisk() }
                    Button("Keep Mine") { document.keepEdits() }
                }
            }
            if let merge = document.lastMerge {
                DocumentNotice(symbol: "arrow.triangle.merge", text: Self.sentence(merged: merge.ranges.count)) {
                    if merge.revision == document.source.revision { Button("Undo") { document.undoMerge() } }
                }
            }
            if let place = content.conflictPlace {
                DocumentNotice(
                    symbol: "exclamationmark.arrow.triangle.2.circlepath",
                    text: Self.sentence(conflicts: document.conflicts.count)
                ) {
                    Text("\(place + 1) of \(document.conflicts.count)").font(Design.Text.detail).monospacedDigit()
                    Button {
                        content.showConflict(step: -1)
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                    .help("Previous conflict")
                    Button {
                        content.showConflict(step: 1)
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .help("Next conflict")
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

    static func sentence(merged count: Int) -> String {
        count == 1 ? "Merged 1 change from the file on disk." : "Merged \(count) changes from the file on disk."
    }

    static func sentence(conflicts count: Int) -> String {
        count == 1
            ? "1 block changed both here and on disk. It is saved once you have chosen."
            : "\(count) blocks changed both here and on disk. It is saved once you have chosen for each."
    }

    static func sentence(for problem: OpenDocumentProblem) -> String {
        switch problem {
            case .missing: "This file is not on disk. Saving writes it."
            case .unreadable: "This file could not be read."
            case .notText: "This file is not text, so it is not shown."
        }
    }
}
