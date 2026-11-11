import Darwin
import SunsetCore

/// One MiB of a stream, by name. `scroll` is what vtebench's scrolling writes once the pseudo-terminal has turned each LF into CR LF.
func stream(_ name: String) -> [UInt8]? {
    let unit: [UInt8]
    switch name {
        case "scroll": unit = [0x79, 0x0D, 0x0A]
        case "newlines": unit = [0x0D, 0x0A]
        case "returns": unit = [0x79, 0x0D]
        case "letters": unit = [0x79]
        case "cr": unit = [0x0D]
        case "bell": unit = [0x07]
        case "pairs": unit = [0x79, 0x79, 0x0D]
        case "lines": unit = Array(repeating: UInt8(0x61), count: 120) + [0x0D, 0x0A]
        case "staircase": unit = [0x79, 0x0A]
        default: return nil
    }
    var bytes: [UInt8] = []
    bytes.reserveCapacity((1 << 20) + unit.count)
    while bytes.count < 1 << 20 { bytes += unit }
    return bytes
}

let arguments = CommandLine.arguments.dropFirst()
guard let name = arguments.first, let bytes = stream(name) else {
    print("usage: instructions scroll|newlines|returns|letters|cr|bell|pairs|lines|staircase [rounds]")
    exit(2)
}
let rounds = arguments.dropFirst().first.flatMap { Int($0) } ?? 100
var terminal = Terminal(columns: 120, rows: 40)
for _ in 0 ..< rounds { bytes.withUnsafeBufferPointer { terminal.feed($0.span) } }
print(name, rounds, terminal.screen.cursorRow)
