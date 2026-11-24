import CSVCoder
import Foundation

/// Reads a comma-separated file (RFC 4180) that another program wrote (roadmap 0095 D): the rows of cells as written. CSVCoder's parser
/// does the reading; this takes away what a person's file carries and a row is not: the byte-order mark Excel and Notepad put first,
/// and blank lines. A cell is never run as a formula or unprotected: what the writer put in front of it (an apostrophe) stays.
public enum CSVReader {
    public static func rows(_ text: String) -> [[String]] {
        var data = Data(text.utf8)
        if data.starts(with: [0xEF, 0xBB, 0xBF]) { data.removeFirst(3) }
        var rows: [[String]] = []
        CSVParser.parse(data: data, delimiter: 0x2C) { parser in
            for row in parser {
                let cells = (0 ..< row.count).map { row.string(at: $0) ?? "" }
                if cells == [""] { continue }
                rows.append(cells)
            }
        }
        return rows
    }
}
