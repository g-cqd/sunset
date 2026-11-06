import TerminalKitText
import Testing

@testable import SunsetCore

@Suite("Scalar width") struct ScalarWidthTests {
    @Test func `the table agrees with the library for every scalar`() {
        var wrong: [UInt32] = []
        for value in UInt32(0) ... 0x10FFFF {
            guard let scalar = Unicode.Scalar(value) else { continue }
            if ScalarWidth.of(scalar) != UnicodeWidth.displayWidth(of: Character(scalar)) { wrong.append(value) }
            if wrong.count > 5 { break }
        }
        #expect(wrong.isEmpty, "first scalars that differ: \(wrong.map { String($0, radix: 16) })")
    }

    @Test func `known widths: narrow, wide, zero`() {
        #expect(ScalarWidth.of("a") == 1)
        #expect(ScalarWidth.of("日") == 2)
        #expect(ScalarWidth.of("\u{0301}") == 0)
        #expect(ScalarWidth.of("😀") == 2)
        #expect(ScalarWidth.of("\u{0}") == 0)
    }
}
