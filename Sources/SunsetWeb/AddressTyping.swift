import Foundation
package import Observation
package import SunsetShell

/// What is being typed in an address field of a window, for the list under it (web step c): the typed row (Go to, or Search), then the engine's
/// suggestions, in the rows of the command bar (`ChoiceList`). One per window; the field that is typed in owns it while it is.
@MainActor @Observable
package final class AddressTyping {
    /// Where the list goes: under the field at the top of the content, over the bottom bar, or under a page's own row.
    package enum Place: Equatable { case top, bottom, pane }

    package private(set) weak var page: WebContent?
    package private(set) var place = Place.top
    package private(set) var text = ""
    package var selection = 0
    package let suggestions = SuggestionSource()

    package init() {}

    package var isActive: Bool { page != nil && !text.isEmpty }

    func begin(_ page: WebContent, place: Place) {
        self.page = page
        self.place = place
        text = ""
        selection = 0
    }

    func typed(_ text: String) {
        self.text = text
        selection = 0
        guard let settings = page?.settings else { return }
        let question = SuggestionSource.question(text, settings: settings)
        suggestions.update(text, engine: question?.0, words: question?.1 ?? "", enabled: settings.suggestions)
    }

    func end() {
        page = nil
        text = ""
        suggestions.clear()
    }

    /// What the rows stand for: what was typed, the history's best matches, then the engine's suggestions.
    var choices: [AddressChoice] {
        guard let settings = page?.settings, let typed = settings.input(text) else { return [] }
        let engine: SearchEngine = if case .search(let chosen, _) = typed { chosen } else { settings.engine }
        let shown = suggestions.answering == text ? suggestions.suggestions : []
        let visited = (page?.history?.suggestions(for: text) ?? []).filter { $0.url != typed.url?.absoluteString }
        return [.typed(typed)] + visited.map { .visited($0) } + shown.map { .suggested(.search(engine, words: $0)) }
    }

    package var rows: [ChoiceRow] { choices.map(\.row) }

    func move(_ steps: Int) {
        let count = choices.count
        guard count > 0 else { return }
        selection = (selection + steps + count) % count
    }

    /// The row `index` (or the selected one) is taken: the page opens it and gets the keyboard.
    package func take(_ index: Int? = nil) {
        let choices = choices
        let chosen = index ?? selection
        guard let page, choices.indices.contains(chosen), let input = choices[chosen].input else { return }
        end()
        page.open(input)
        page.focusPage()
    }
}
