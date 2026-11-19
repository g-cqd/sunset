/// Keys written as text on a command line (`--keys`), for the tools that drive a terminal (sunset-run, sunset-render):
/// `\e` escape, `\n` newline, `\r` return, `\t` tab; a backslash before anything else is that thing.
public enum KeyText {
    public static func unescape(_ text: String) -> String {
        var result = ""
        var iterator = text.makeIterator()
        while let character = iterator.next() {
            guard character == "\\", let next = iterator.next() else {
                result.append(character)
                continue
            }
            switch next {
                case "e": result.append("\u{1B}")
                case "n": result.append("\n")
                case "r": result.append("\r")
                case "t": result.append("\t")
                default: result.append(next)
            }
        }
        return result
    }
}
