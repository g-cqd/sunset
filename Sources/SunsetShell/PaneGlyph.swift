package import SunsetPane

/// The picture a tab has by itself: a terminal's (its folder with a letter, or the mark of a running command), a symbol by name, or a letter in a rounded
/// square (a page: the first letter of its title, R1).
package enum PaneGlyph: Equatable {
    case tab(TabGlyph)
    case symbol(String)
    case initial(String)
}
