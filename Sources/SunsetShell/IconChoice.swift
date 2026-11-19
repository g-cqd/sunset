import SunsetPane

/// One icon of the picker's grid: a symbol of the system by its name, or an emoji.
struct IconChoice: Equatable, Identifiable, Sendable {
    /// The symbol's name, or the emoji itself.
    let id: String
    let isEmoji: Bool
    /// What it is called: said under the grid for the one under the pointer, and to accessibility.
    let label: String

    init(_ symbol: SymbolCatalog.Symbol) {
        id = symbol.name
        isEmoji = false
        label = symbol.name
    }

    init(_ emoji: EmojiCatalog.Emoji) {
        id = emoji.text
        isEmoji = true
        label = emoji.name
    }

    /// The icon it makes; a symbol keeps the colour the icon had.
    func icon(keeping color: IconColor?) -> PaneIcon {
        isEmoji ? .emoji(id) : .symbol(id, color: color)
    }
}
