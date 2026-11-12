import Foundation
package import Observation

/// The engine's suggestions for what is being typed (web step c): asked after a short pause, the earlier question dropped when more is typed; never
/// for an address typed with its scheme or one of this machine or the local network; nothing when the setting is off or the engine has no suggestion
/// address. Asked without cookies or a cache (an ephemeral session), so the engine cannot tie them to the pages' store.
@MainActor @Observable
package final class SuggestionSource {
    /// The suggestions, and what was typed they answer.
    package private(set) var suggestions: [String] = []
    package private(set) var answering = ""
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var asked = ""

    nonisolated static let session = URLSession(configuration: .ephemeral)

    package init() {}

    /// What is typed now, with the engine it would be searched with (nil: nothing is asked).
    package func update(_ typed: String, engine: SearchEngine?, words: String, enabled: Bool) {
        let key = (engine?.name ?? "") + "\u{0}" + words
        guard key != asked else { return }
        asked = key
        task?.cancel()
        guard enabled, let engine, !words.isEmpty, let url = engine.suggestURL(words) else {
            suggestions = []
            answering = typed
            return
        }
        task = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled, let (data, _) = try? await Self.session.data(from: url), !Task.isCancelled else {
                return
            }
            let found = OpenSearchSuggestions.parse(data).filter { $0.lowercased() != words.lowercased() }
            self?.suggestions = found
            self?.answering = typed
        }
    }

    /// What to ask about `typed`, with `settings`: the engine and the words when it would be searched or is a host being typed (not one with a
    /// scheme, not a local one).
    package static func question(_ typed: String, settings: WebSettings, chip: SearchEngine? = nil) -> (
        SearchEngine, String
    )? {
        let text = typed.trimmingCharacters(in: .whitespaces)
        if let chip { return text.isEmpty ? nil : (chip, text) }
        switch settings.input(text) {
            case .search(let engine, let words)?: return (engine, words)
            case .address(_, let guessed)?: return guessed ? (settings.engine, text) : nil
            case nil: return nil
        }
    }

    package func clear() {
        task?.cancel()
        asked = ""
        suggestions = []
    }
}
