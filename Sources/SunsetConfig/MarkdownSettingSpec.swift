import Foundation

/// Compact builder for rendered-Markdown options in `SettingsOption.documents`.
enum MarkdownSettingSpec {
    static func parse(from table: String) -> [SettingsOption] {
        table.split(separator: "\n")
            .compactMap { line in
                let p = line.split(separator: "|").map(String.init)
                guard p.count >= 4 else { return nil }
                let id = p[0].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                let key = String(id.dropFirst("documents.".count))
                if Configuration.Documents.flagKeys.contains(key) {
                    return SettingsOption.toggle(id, p[1], p[2], \.documents[flag: key]).grouped(p[3])
                }
                if Configuration.Documents.fontKeys.contains(key) {
                    let option = SettingsOption.text(id, p[1], p[2], \.documents[font: key], prompt: p[3])
                        .grouped("Markdown fonts")
                    return p.count == 5 ? option.noted(p[4]) : option
                }
                return nil
            }
    }
}
