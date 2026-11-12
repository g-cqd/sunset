import Foundation
package import SunsetShell

/// A row of the lists where an address is typed (web step e): what was typed (Go to, Search), a page of the history, an engine's suggestion.
package enum AddressChoice {
    case typed(WebInput)
    case visited(HistoryEntry)
    case suggested(WebInput)

    /// What opening it loads.
    package var input: WebInput? {
        switch self {
            case .typed(let input), .suggested(let input): input
            case .visited(let entry): URL(string: entry.url).map { .address($0, guessed: false) }
        }
    }

    package var row: ChoiceRow {
        switch self {
            case .typed(.address(let url, _)):
                ChoiceRow(
                    id: "typed",
                    glyph: .symbol("globe"),
                    title: "Go to \(url.absoluteString)",
                    accessory: "Address",
                    actions: []
                )
            case .typed(.search(let engine, let words)):
                ChoiceRow(
                    id: "typed",
                    glyph: .symbol("magnifyingglass"),
                    title: "Search \(engine.name) for \u{201C}\(words)\u{201D}",
                    accessory: engine.name,
                    actions: []
                )
            case .visited(let entry):
                ChoiceRow(
                    id: "visited " + entry.url,
                    glyph: .symbol("clock"),
                    title: entry.title.isEmpty ? entry.url : entry.title,
                    subtitle: Self.shortAddress(entry.url),
                    accessory: "History",
                    actions: []
                )
            case .suggested(let input):
                ChoiceRow(
                    id: "suggestion " + (input.words ?? ""),
                    glyph: .symbol("magnifyingglass"),
                    title: input.words ?? "",
                    accessory: input.engineName,
                    actions: []
                )
        }
    }

    /// The address without its scheme and "www.".
    package static func shortAddress(_ address: String) -> String {
        var text = address
        for prefix in ["https://", "http://"] where text.hasPrefix(prefix) { text.removeFirst(prefix.count) }
        if text.hasPrefix("www.") { text.removeFirst(4) }
        if text.hasSuffix("/") { text.removeLast() }
        return text
    }
}

extension WebInput {
    /// The words of a search.
    var words: String? {
        if case .search(_, let words) = self { return words }
        return nil
    }

    var engineName: String? {
        if case .search(let engine, _) = self { return engine.name }
        return nil
    }
}
