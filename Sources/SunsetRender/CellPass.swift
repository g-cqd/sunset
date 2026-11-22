/// What a pass over a row's cells draws: everything (the usual single pass), or, when an image goes between them (kitty's
/// negative `z`), the backgrounds first and then the marks (glyphs, decorations, a thin cursor).
enum CellPass {
    case all, backgrounds, marks

    var drawsBackgrounds: Bool {
        self != .marks
    }

    var drawsMarks: Bool {
        self != .backgrounds
    }
}
