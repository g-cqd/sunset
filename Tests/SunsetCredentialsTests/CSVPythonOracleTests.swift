import AemiJSON
import AemiTestKit
import Foundation
import SunsetStorage
import Testing

@testable import SunsetCredentials

/// Python's `csv` module is the oracle for CSV (white paper: oracles run as processes, never linked): what our writer writes it reads as
/// the table, and what it writes we read as the table. Tables travel to it and back as JSON, read and written by AemiJSON. A batch of tables
/// goes through one process, so that a property of hundreds of cases is not hundreds of launches. Not run where Python is not installed.
@Suite("CSV against Python's csv module", .enabled(if: PythonCSV.path != nil))
struct CSVPythonOracleTests {
    /// Tables of two to five cells a row (a row of one quoted empty cell is a blank line to the reader, by its one rule).
    static var tables: AnyGenerator<[[[String]]]> {
        let cell = Gen.string(maxLength: 10, alphabet: CSVPropertyTests.alphabet)
        let row = AnyGenerator<[String]>(
            generate: { rng in (0 ..< 2 + rng.uniform(4)).map { _ in cell.generate(using: &rng) } },
            shrink: { _ in [] }
        )
        return Gen.array(of: Gen.array(of: row, maxCount: 5), maxCount: 40)
    }

    @Test func `what our writer writes, Python reads as the table`() throws {
        forAll(Self.tables, count: 12, seed: .named("csv.oracle.ours")) { batch in
            let texts = batch.map { table in table.map { CSV.line($0, formulas: .keep) }.joined() }
            guard let read = PythonCSV.read(texts) else { return false }
            return read == batch.map { $0.filter { $0 != [""] } }
        }
    }

    @Test func `what Python writes, our reader reads as the table`() throws {
        forAll(Self.tables, count: 12, seed: .named("csv.oracle.theirs")) { batch in
            guard let written = PythonCSV.write(batch) else { return false }
            return written.map { CSVReader.rows($0) } == batch
        }
    }

    @Test func `the oracle itself is the one we think: a known table, both ways`() throws {
        let table = [["a", "b,c", "d\"e"], ["line\nbreak", "", "é😀"]]
        let text = try #require(PythonCSV.write([table])?.first)
        #expect(text == "a,\"b,c\",\"d\"\"e\"\r\n\"line\nbreak\",,é😀\r\n")
        #expect(PythonCSV.read([text]) == [table])
    }
}
