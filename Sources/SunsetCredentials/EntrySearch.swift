import Foundation

/// The Passwords section's search (roadmap 0092 E): every word typed is somewhere in an entry (its title, its fields'
/// values, its tags, its folder, its note), case and accents aside. A secret's value is never searched: a password typed
/// in the search field finds nothing.
public enum EntrySearch {
    public static func matching(_ query: String, in entries: [VaultEntry]) -> [VaultEntry] {
        let words = query.split(whereSeparator: \.isWhitespace).map { fold(String($0)) }
        guard !words.isEmpty else { return entries }
        return entries.filter { entry in
            let text = fold(searchable(entry))
            return words.allSatisfy(text.contains)
        }
    }

    /// What of an entry is searched.
    private static func searchable(_ entry: VaultEntry) -> String {
        let values = entry.sections.flatMap(\.fields).filter { !$0.kind.isConcealed }.map(\.value)
        return ([entry.title, entry.note, entry.folder ?? ""] + entry.tags + values).joined(separator: "\n")
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
