import Foundation
import Testing

@testable import SunsetCredentials

/// Reading a comma-separated file (RFC 4180) that another program wrote (roadmap 0095 D): quoted cells with commas, doubled
/// quotes and line breaks; any line ending; a byte-order mark; the cells as they were written, never run as formulas.
@Suite("Reading CSV")
struct CSVReaderTests {
    @Test func `plain cells, quoted cells with commas, doubled quotes and line breaks`() {
        let text = "a,b,c\r\n1,\"x, y\",\"say \"\"hi\"\"\"\r\n\"two\nlines\",,end\r\n"
        #expect(
            CSVReader.rows(text) == [["a", "b", "c"], ["1", "x, y", "say \"hi\""], ["two\nlines", "", "end"]]
        )
    }

    @Test func `any line ending, a last line with none, a byte-order mark, blank lines skipped`() {
        #expect(CSVReader.rows("\u{FEFF}a,b\nc,d\r\n\r\ne,f") == [["a", "b"], ["c", "d"], ["e", "f"]])
        #expect(CSVReader.rows("a,b\rc,d\r") == [["a", "b"], ["c", "d"]])
        #expect(CSVReader.rows("").isEmpty)
    }

    @Test func `an unclosed quote takes the rest as one cell, nothing is lost`() {
        #expect(CSVReader.rows("a,\"b,c\nd") == [["a", "b,c\nd"]])
    }

    @Test func `what the writer protected is not unprotected: the apostrophe stays, it is the person's to remove`() {
        #expect(CSVReader.rows("'=SUM(A1),x\n") == [["'=SUM(A1)", "x"]])
    }
}
