package import SunsetPane

/// One icon of the picker's grid: a symbol of the system by its name, or an emoji.
package struct IconChoice: Equatable, Identifiable, Sendable {
    /// The symbol's name, or the emoji itself.
    package let id: String
    package let isEmoji: Bool
    /// What it is called: said under the grid for the one under the pointer, and to accessibility.
    package let label: String

    package init(_ symbol: SymbolCatalog.Symbol) {
        id = symbol.name
        isEmoji = false
        label = symbol.name
    }

    package init(_ emoji: EmojiCatalog.Emoji) {
        id = emoji.text
        isEmoji = true
        label = emoji.name
    }

    /// The icon it makes; a symbol keeps the colour the icon had.
    package func icon(keeping color: IconColor?) -> PaneIcon {
        isEmoji ? .emoji(id) : .symbol(id, color: color)
    }
}
