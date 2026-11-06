import Testing

@testable import SunsetCore

let escapeByte: UInt8 = 0x1B

func bytes(_ string: String) -> [UInt8] { Array(string.utf8) }

func encode(_ press: KeyPress, application: Bool = false, flags: UInt8 = 0) -> [UInt8] {
    var modes = Modes()
    modes.applicationCursorKeys = application
    return KeyEncoder.encode(press, modes: modes, keyboardFlags: flags)
}

func key(_ character: Unicode.Scalar, _ modifiers: InputModifiers = [], text: String? = nil) -> KeyPress {
    KeyPress(.character(character), modifiers: modifiers, text: text)
}

@Suite("Key encoding") struct KeyEncoderTests {
    @Test func `text keys send their text`() {
        #expect(encode(key("a", text: "a")) == bytes("a"))
        #expect(encode(key("a", [.shift], text: "A")) == bytes("A"))
        #expect(encode(key("é", text: "é")) == bytes("é"))
        #expect(encode(key("1", [.shift], text: "!")) == bytes("!"))
    }

    @Test func `control letters give the control characters`() {
        #expect(encode(key("c", [.control])) == [3])
        #expect(encode(key("a", [.control])) == [1])
        #expect(encode(key("z", [.control])) == [26])
        #expect(encode(key("[", [.control])) == [27])
        #expect(encode(key(" ", [.control])) == [0])
        #expect(encode(key("?", [.control])) == [127])
        #expect(encode(key("\\", [.control])) == [28])
    }

    @Test func `alt sends escape first`() {
        #expect(encode(key("x", [.option], text: "x")) == [escapeByte, 0x78])
        #expect(encode(key("c", [.option, .control])) == [escapeByte, 3])
    }

    @Test func `enter, tab, backspace and escape`() {
        #expect(encode(KeyPress(.enter)) == [13])
        #expect(encode(KeyPress(.tab)) == [9])
        #expect(encode(KeyPress(.tab, modifiers: [.shift])) == bytes("\u{1B}[Z"))
        #expect(encode(KeyPress(.backspace)) == [127])
        #expect(encode(KeyPress(.backspace, modifiers: [.control])) == [8])
        #expect(encode(KeyPress(.escape)) == [27])
    }

    @Test func `arrows follow the cursor keys mode and carry modifiers`() {
        #expect(encode(KeyPress(.up)) == bytes("\u{1B}[A"))
        #expect(encode(KeyPress(.up), application: true) == bytes("\u{1B}OA"))
        #expect(encode(KeyPress(.left, modifiers: [.shift])) == bytes("\u{1B}[1;2D"))
        #expect(encode(KeyPress(.right, modifiers: [.control])) == bytes("\u{1B}[1;5C"))
        #expect(encode(KeyPress(.down, modifiers: [.option, .shift]), application: true) == bytes("\u{1B}[1;4B"))
        #expect(encode(KeyPress(.home)) == bytes("\u{1B}[H"))
        #expect(encode(KeyPress(.end), application: true) == bytes("\u{1B}OF"))
    }

    @Test func `paging, insert and delete`() {
        #expect(encode(KeyPress(.pageUp)) == bytes("\u{1B}[5~"))
        #expect(encode(KeyPress(.pageDown)) == bytes("\u{1B}[6~"))
        #expect(encode(KeyPress(.insert)) == bytes("\u{1B}[2~"))
        #expect(encode(KeyPress(.delete)) == bytes("\u{1B}[3~"))
        #expect(encode(KeyPress(.delete, modifiers: [.control])) == bytes("\u{1B}[3;5~"))
    }

    @Test func `function keys`() {
        #expect(encode(KeyPress(.function(1))) == bytes("\u{1B}OP"))
        #expect(encode(KeyPress(.function(4))) == bytes("\u{1B}OS"))
        #expect(encode(KeyPress(.function(1), modifiers: [.shift])) == bytes("\u{1B}[1;2P"))
        let expected = [
            5: "15", 6: "17", 7: "18", 8: "19", 9: "20", 10: "21", 11: "23", 12: "24", 13: "25", 14: "26", 15: "28",
            16: "29", 17: "31", 18: "32", 19: "33", 20: "34"
        ]
        for (number, code) in expected where number != 15 && number != 16 {
            #expect(encode(KeyPress(.function(number))) == bytes("\u{1B}[\(code)~"), "F\(number)")
        }
        #expect(encode(KeyPress(.function(12), modifiers: [.control])) == bytes("\u{1B}[24;5~"))
        #expect(encode(KeyPress(.function(30))) == [])
    }

    @Test func `with the keyboard protocol's disambiguation, escape and modified keys become CSI u`() {
        #expect(encode(KeyPress(.escape), flags: 1) == bytes("\u{1B}[27u"))
        #expect(encode(key("i", [.control]), flags: 1) == bytes("\u{1B}[105;5u"))
        #expect(encode(key("a", [.option], text: "å"), flags: 1) == bytes("\u{1B}[97;3u"))
        #expect(encode(KeyPress(.enter, modifiers: [.control]), flags: 1) == bytes("\u{1B}[13;5u"))
        #expect(encode(KeyPress(.tab, modifiers: [.control]), flags: 1) == bytes("\u{1B}[9;5u"))
        // Plain text, plain Enter and the cursor keys are unchanged.
        #expect(encode(key("a", text: "a"), flags: 1) == bytes("a"))
        #expect(encode(key("a", [.shift], text: "A"), flags: 1) == bytes("A"))
        #expect(encode(KeyPress(.enter), flags: 1) == [13])
        #expect(encode(KeyPress(.up), flags: 1) == bytes("\u{1B}[A"))
        // Flags that are not the first change nothing here.
        #expect(encode(KeyPress(.escape), flags: 2) == [27])
    }
}
