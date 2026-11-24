/// Comma-separated values for a file of the person's (RFC 4180): a cell is quoted when it holds a comma, a quote or a line
/// break. A cell that would start a formula in a spreadsheet (`=`, `+`, `-`, `@`, a tab, a return) gets an apostrophe first:
/// what is exported (a page's title, an address) is chosen by others, and must not run when the file is opened (CWE-1236).
public enum CSV {
    /// What is done to a cell that would start a formula: `protect` (the default: the file is for a spreadsheet) or `keep`, for a file another
    /// program reads back, where an apostrophe would change what the cell is (a password).
    public enum Formulas: Sendable {
        case protect
        case keep
    }

    public static func cell(_ text: String, formulas: Formulas = .protect) -> String {
        // By unicode scalar, not by character: "\r\n" is one character in Swift, and is neither "\r" nor "\n" to a test of characters.
        var cell = text
        if formulas == .protect, let first = cell.unicodeScalars.first, "=+-@\t\r".unicodeScalars.contains(first) {
            cell = "'" + cell
        }
        guard cell.unicodeScalars.contains(where: { ",\"\n\r".unicodeScalars.contains($0) }) else { return cell }
        return "\"" + cell.replacing("\"", with: "\"\"") + "\""
    }

    /// One line, ended as the format asks.
    public static func line(_ cells: [String], formulas: Formulas = .protect) -> String {
        cells.map { cell($0, formulas: formulas) }.joined(separator: ",") + "\r\n"
    }
}
