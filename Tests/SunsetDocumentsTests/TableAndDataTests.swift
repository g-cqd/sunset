import Testing

@testable import SunsetDocuments

/// A CSV or TSV opens as a table, a JSON file as a tree: their text read as such, leniently, and as they are typed.
@Suite("Tables and data")
struct TableAndDataTests {
    @Test func `CSV, TSV and JSON are their own kinds; Sunset opens them`() {
        #expect(DocumentKind(path: "a.csv") == .table && DocumentKind(path: "b.TSV") == .table)
        #expect(DocumentKind(path: "c.json") == .data && DocumentKind(path: "d.geojson") == .data)
        #expect(DocumentKind.opens(path: "/x/a.csv") && DocumentKind.opens(path: "/x/c.json"))
    }

    @Test func `quoted cells hold separators, line breaks and quotes; blank lines and a missing last break are fine`() {
        let table = TableText("name,note\r\n\"Smith, J\",\"said \"\"hi\"\"\nthen left\"\n\nlast,row")
        #expect(table.rows == [["name", "note"], ["Smith, J", "said \"hi\"\nthen left"], ["last", "row"]])
        #expect(table.total == 3)
        #expect(
            TableText("a\tb\n1\t2", separator: TableText.separator(path: "/x/t.tsv")).rows == [["a", "b"], ["1", "2"]]
        )
        #expect(TableText("a,b\n1,2", separator: TableText.separator(path: nil)).rows.count == 2)
    }

    @Test func `a stray quote is text, a short row stays short; past the limit, rows are counted, not kept`() {
        #expect(TableText("x\"y,z\n1").rows == [["x\"y", "z"], ["1"]])
        let many = TableText((0 ..< 50).map(String.init).joined(separator: "\n"), limit: 10)
        #expect(many.rows.count == 10 && many.total == 50)
    }

    @Test func `JSON is a tree in the file's order, each node its path; JSON5 is read; anything else is nil`() throws {
        let tree = try #require(DataTree(#"{ "b": [1, 2.5, "x"], "a": { "ok": true, "none": null }, }"#))
        #expect(tree.value == .object(count: 2))
        #expect(tree.children?.map(\.key) == ["b", "a"])
        let items = try #require(tree.children?.first?.children)
        #expect(items.map(\.value) == [.number("1"), .number("2.5"), .string("x")])
        #expect(items.map(\.id) == ["$.b[0]", "$.b[1]", "$.b[2]"])
        #expect(tree.children?.last?.children?.map(\.value) == [.bool(true), .null])
        #expect(items.first?.children == nil, "a scalar has nothing to fold")
        #expect(DataTree("{ not json") == nil && DataTree("") == nil)
    }
}
