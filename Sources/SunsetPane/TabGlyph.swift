/// The small picture that tells what a tab is about when there is no room for its path or command: a folder with the first letter of the folder's name in it,
/// or, while a program other than the shell runs in the foreground, a mark for a command.
public struct TabGlyph: Sendable, Equatable {
    public enum Kind: Sendable, Equatable { case folder, command }

    public let kind: Kind
    /// The letter inside a folder (capital); nil for no directory yet, and for a command.
    public let letter: Character?

    public init(kind: Kind, letter: Character?) {
        self.kind = kind
        self.letter = letter
    }

    /// What `directory` (the program's working directory) and `command` (the foreground program's name, nil when the shell is in front) say. `home` is the
    /// user's home folder, marked `~`.
    public static func make(directory: String?, command: String?, home: String) -> TabGlyph {
        if let command, !command.isEmpty, !shells.contains(command.trimmingPrefix("-")) {
            return TabGlyph(kind: .command, letter: nil)
        }
        guard let directory, !directory.isEmpty else { return TabGlyph(kind: .folder, letter: nil) }
        var path = Substring(directory)
        while path.count > 1, path.hasSuffix("/") { path = path.dropLast() }
        if path == "/" { return TabGlyph(kind: .folder, letter: "/") }
        if path == Substring(home) { return TabGlyph(kind: .folder, letter: "~") }
        let name = path.split(separator: "/").last ?? path
        let first =
            name.first { $0.isLetter || $0.isNumber || $0.unicodeScalars.first?.properties.isEmojiPresentation == true }
            ?? name.first
        return TabGlyph(kind: .folder, letter: first.map { Character($0.uppercased()) })
    }

    /// Programs that are the shell itself (a login shell's name starts with `-`).
    private static let shells: Set<Substring> = [
        "sh", "bash", "zsh", "fish", "dash", "ksh", "tcsh", "csh", "nu", "elvish", "xonsh"
    ]
}
