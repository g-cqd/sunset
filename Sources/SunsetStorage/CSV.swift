/// Comma-separated values for a file of the person's (RFC 4180): a cell is quoted when it holds a comma, a quote or a line
/// break. A cell that would start a formula in a spreadsheet (`=`, `+`, `-`, `@`, a tab, a return) gets an apostrophe first:
/// what is exported (a page's title, an address) is chosen by others, and must not run when the file is opened (CWE-1236).
public enum CSV {
    public static func cell(_ text: String) -> String {
        var cell = text
        if let first = cell.first, "=+-@\t\r".contains(first) { cell = "'" + cell }
        guard cell.contains(where: { ",\"\n\r".contains($0) }) else { return cell }
        return "\"" + cell.replacing("\"", with: "\"\"") + "\""
    }

    /// One line, ended as the format asks.
    public static func line(_ cells: [String]) -> String {
        cells.map(cell).joined(separator: ",") + "\r\n"
    }
}
