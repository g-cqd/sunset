import SunsetPane

/// The picture a tab has by itself: a terminal's (its folder with a letter, or the mark of a running command), or a symbol by name.
enum PaneGlyph: Equatable {
    case tab(TabGlyph)
    case symbol(String)
}
