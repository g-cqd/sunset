internal import AppKit
internal import MarkdownLookKit
internal import SunsetDocuments
import SunsetRuntime
internal import SunsetShell
import SwiftUI

/// Finds the text view of the source editor it is put behind, and keeps its marks (`SourceMarks`) as the document's
/// conflicts are. The editor is the kit's and gives no handle on its text view; the one searched for is the nearest text view
/// on this document's text, which is this pane's (another pane on the same document has its own).
struct SourceMarksFinder: NSViewRepresentable {
    @Environment(\.runtime) var runtime

    let content: DocumentContent
    /// What the marks depend on: when one changes, they are placed again.
    let conflicts: [DocumentConflict]
    let revision: Int
    let merged: [Range<Int>]
    let reveal: Int
    let fontSize: Double

    final class Coordinator {
        var marks: SourceMarks
        var revealed: Int
        init(marks: SourceMarks, revealed: Int) {
            self.marks = marks
            self.revealed = revealed
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(marks: SourceMarks(content: content), revealed: reveal)
    }

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ view: NSView, context: Context) {
        let coordinator = context.coordinator
        let marks = coordinator.marks
        marks.merged = merged
        // Nothing to mark and nothing marked: the editor is not even looked for.
        guard !conflicts.isEmpty || !merged.isEmpty || marks.isAttached else { return }
        let storage = content.document.source.storage
        let wanted = reveal
        // After this pass: the editor beside this view may not be in the window yet.
        runtime.task { @MainActor [weak view] in
            guard let view else { return }
            marks.attach(to: Self.editor(near: view, on: storage))
            marks.update()
            if coordinator.revealed != wanted {
                coordinator.revealed = wanted
                marks.reveal()
            }
        }
    }

    static func dismantleNSView(_ view: NSView, coordinator: Coordinator) {
        coordinator.marks.attach(to: nil)
    }

    /// The text view on `storage` in the nearest view above `view` that holds one.
    private static func editor(near view: NSView, on storage: NSTextStorage) -> NSTextView? {
        var above = view.superview
        while let holder = above {
            if let found = textView(in: holder, on: storage) { return found }
            above = holder.superview
        }
        return nil
    }

    private static func textView(in view: NSView, on storage: NSTextStorage) -> NSTextView? {
        if let text = view as? NSTextView, text.textStorage === storage { return text }
        for child in view.subviews {
            if let found = textView(in: child, on: storage) { return found }
        }
        return nil
    }
}
