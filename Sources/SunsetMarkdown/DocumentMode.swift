/// How a pane shows its document: drawn as a page, or as its source in an editor.
package enum DocumentMode: String, Sendable {
    case rendered, source

    package var other: DocumentMode {
        self == .rendered ? .source : .rendered
    }
}
