import Observation
import SunsetPane
import SwiftUI

/// A plain text note in a pane: the second kind of content, with nothing of a terminal in it. Its text is saved with the session.
@MainActor @Observable
final class NoteContent: PaneContent {
    static let kind = "note"

    var text: String {
        didSet { if text != oldValue { onEdit() } }
    }
    /// The pane has the keyboard and is on screen (what `setState` said last).
    private(set) var isFocused = false
    @ObservationIgnored var onExit: () -> Void = {}
    @ObservationIgnored var onFocusRequest: () -> Void = {}
    /// The text changed: the session is to be saved.
    @ObservationIgnored var onEdit: () -> Void = {}

    init(text: String = "") {
        self.text = text
    }

    /// The first line that has something on it.
    var title: String {
        let line = text.split(whereSeparator: \.isNewline).first { !$0.allSatisfy(\.isWhitespace) }
        return line.map { String($0.prefix(60)).trimmingCharacters(in: .whitespaces) } ?? "Note"
    }
    var detail: String? { nil }
    var glyph: PaneGlyph { .symbol("note.text") }
    var progress: Double? { nil }
    /// Nothing is lost by closing it that the person did not ask to lose: there is no file behind it.
    var closeWarning: String? { nil }
    var descriptor: PaneDescriptor { PaneDescriptor(kind: Self.kind, state: ["text": text]) }

    func setState(focused: Bool, visible: Bool) { isFocused = focused && visible }
    func stop() {}
    func makeView(_ context: PaneViewContext) -> AnyView { AnyView(NoteView(note: self, focused: context.focused)) }
}
