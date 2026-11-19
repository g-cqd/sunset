/// What the icon picker picks from: the system's symbols and its emoji.
package struct IconCatalogs: Sendable {
    package let symbols: SymbolCatalog
    package let emoji: EmojiCatalog

    package init(symbols: SymbolCatalog, emoji: EmojiCatalog) {
        self.symbols = symbols
        self.emoji = emoji
    }

    /// Read from the system's files.
    package static func load() -> IconCatalogs {
        IconCatalogs(symbols: .load(), emoji: .load())
    }
}
