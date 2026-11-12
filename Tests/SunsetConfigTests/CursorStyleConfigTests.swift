import Testing

@testable import SunsetConfig

@Suite("Cursor style") struct CursorStyleConfigTests {
    @Test func `the default is a blinking bar`() {
        let configuration = Configuration()
        #expect(configuration.cursorShape == .bar && configuration.cursorBlinks)
    }

    @Test(arguments: ["block", "underline", "bar"])
    func `cursor.shape reads each shape`(name: String) throws {
        let result = try ConfigurationParser.parse(#"{ "cursor": { "shape": "\#(name)" } }"#)
        #expect(result.issues.isEmpty && result.configuration.cursorShape.rawValue == name)
    }

    @Test func `cursor.shape and cursor.blink report what is wrong and keep the default`() throws {
        let shape = try ConfigurationParser.parse(#"{ "cursor": { "shape": "beam" } }"#)
        #expect(shape.configuration.cursorShape == .bar && shape.issues.map(\.path) == ["cursor.shape"])
        #expect(shape.issues.first?.message.contains("bar") == true)
        let blink = try ConfigurationParser.parse(#"{ "cursor": { "blink": "yes" } }"#)
        #expect(blink.configuration.cursorBlinks && blink.issues.map(\.path) == ["cursor.blink"])
        let off = try ConfigurationParser.parse(#"{ "cursor": { "blink": false } }"#)
        #expect(!off.configuration.cursorBlinks && off.issues.isEmpty)
    }

    @Test func `a change of the style is a change of the cursor`() {
        var changed = Configuration()
        changed.cursorShape = .underline
        #expect(changed.changes(from: Configuration()) == [.cursorStyle])
    }
}
