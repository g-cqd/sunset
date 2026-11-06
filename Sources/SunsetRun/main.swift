// sunset-run: runs a program in a headless Sunset terminal and prints the screen. A tool for looking at what a real program does to the emulator, and
// the way a comparison with another terminal starts (roadmap 0004, 0005).
//
//   sunset-run [--cols N] [--rows N] [--wait MS] [--keys TEXT] [--then-wait MS] [--plain] [--cells] [--env K=V] [--until-exit MS] [--resize COLSxROWS] -- command [args...]
//
// --keys is sent after --wait; \e \n \r \t \\ are escapes in it. The screen is printed after --then-wait more milliseconds (default 500).
internal import Darwin
import SunsetCore
import SunsetHost

var columns = 80
var rows = 24
var waitFirst = 800
var waitThen = 500
var keys = ""
var plain = false
var cells = false
var untilExit = 0
var resizeTo: (columns: Int, rows: Int)?
var environment: [String: String] = [:]
var command: [String] = []
var arguments = Array(CommandLine.arguments.dropFirst())
while let argument = arguments.first {
    arguments.removeFirst()
    switch argument {
        case "--cols": columns = Int(arguments.removeFirst()) ?? columns
        case "--rows": rows = Int(arguments.removeFirst()) ?? rows
        case "--wait": waitFirst = Int(arguments.removeFirst()) ?? waitFirst
        case "--then-wait": waitThen = Int(arguments.removeFirst()) ?? waitThen
        case "--keys": keys = arguments.removeFirst()
        case "--plain": plain = true
        case "--cells": cells = true
        case "--until-exit": untilExit = Int(arguments.removeFirst()) ?? 0
        case "--resize":
            let parts = arguments.removeFirst().split(separator: "x").compactMap { Int($0) }
            if parts.count == 2 { resizeTo = (parts[0], parts[1]) }
        case "--env":
            let pair = arguments.removeFirst()
            if let split = pair.firstIndex(of: "=") {
                environment[String(pair[..<split])] = String(pair[pair.index(after: split)...])
            }
        case "--":
            command = arguments
            arguments = []
        default:
            command = [argument] + arguments
            arguments = []
    }
}
guard !command.isEmpty else {
    print("usage: sunset-run [--cols N] [--rows N] [--wait MS] [--keys TEXT] [--then-wait MS] -- command [args...]")
    exit(2)
}

func unescape(_ text: String) -> String {
    var result = ""
    var iterator = text.makeIterator()
    while let character = iterator.next() {
        guard character == "\\", let next = iterator.next() else {
            result.append(character)
            continue
        }
        switch next {
            case "e": result.append("\u{1B}")
            case "n": result.append("\n")
            case "r": result.append("\r")
            case "t": result.append("\t")
            default: result.append(next)
        }
    }
    return result
}

func describe(_ color: Color) -> String {
    // Colour is printed from its public parts: default, or the packed value (palette index or RGB) in hex.
    color.isDefault ? "-" : String(color.packed, radix: 16)
}

/// The text of a run of cells with one style, then the style (colours, attributes, underline).
func describeRun(_ text: String, _ style: CellStyle) -> String {
    "\"\(text)\" fg=\(describe(style.foreground)) bg=\(describe(style.background)) attrs=\(style.attributes.rawValue) ul=\(style.underline.rawValue)"
}

/// The last column of a row that holds a character (kitty's ANSI dump drops blank cells at the end of a row, even with a background, so those cannot be
/// compared).
func lastColumn(of row: Int, in screen: Screen) -> Int {
    var last = screen.columns - 1
    while last >= 0, screen.cell(row: row, column: last).scalar == 0 { last -= 1 }
    return last
}

/// Every non-blank row as runs of cells with one style.
@MainActor func printCells(_ screen: Screen) {
    for row in 0 ..< screen.rows {
        let last = lastColumn(of: row, in: screen)
        if last < 0 { continue }
        var runs: [String] = []
        var text = ""
        var current: CellStyle?
        for column in 0 ... last {
            let cell = screen.cell(row: row, column: column)
            let style = screen.style(of: cell)
            if style != current {
                if let current, !text.isEmpty { runs.append(describeRun(text, current)) }
                text = ""
                current = style
            }
            text += screen.text(of: cell)
        }
        if let current, !text.isEmpty { runs.append(describeRun(text, current)) }
        print("\(row): " + runs.joined(separator: " | "))
    }
}

/// Only the text, as logical lines: rows that wrapped are joined (as kitty's screen dump joins them), trailing spaces and empty lines dropped.
@MainActor func printPlain(_ screen: Screen) {
    // Only the text, as logical lines: rows that wrapped are joined (as kitty's screen dump joins them), trailing spaces and empty lines dropped.
    var lines: [String] = []
    var current = ""
    for row in 0 ..< screen.rows {
        var text = ""
        for column in 0 ..< screen.columns { text += screen.text(of: screen.cell(row: row, column: column)) }
        if screen.isWrapped(row: row) {
            current += text
        } else {
            var line = current + text
            while line.last == " " { line.removeLast() }
            lines.append(line)
            current = ""
        }
    }
    while lines.last == "" { lines.removeLast() }
    for line in lines { print(line) }
}

@MainActor func run() throws {
    let session = try HeadlessSession(command, columns: columns, rows: rows, environment: environment)
    if untilExit > 0 {
        _ = session.waitForExit(timeoutMilliseconds: untilExit)
    } else {
        _ = session.wait(timeoutMilliseconds: waitFirst) { _ in false }
    }
    if let resizeTo {
        session.resize(columns: resizeTo.columns, rows: resizeTo.rows)
        _ = session.wait(timeoutMilliseconds: waitThen) { _ in false }
    }
    if !keys.isEmpty { try session.send(unescape(keys)) }
    _ = session.wait(timeoutMilliseconds: waitThen) { _ in false }
    let screen = session.terminal.screen
    if cells {
        printCells(screen)
        return
    }
    if plain {
        printPlain(screen)
        return
    }
    print(
        "title: \(screen.title)   cursor: row \(screen.cursorRow) col \(screen.cursorColumn)   alternate: \(screen.isAlternate)   history: \(screen.scrollbackCount)"
    )
    print("+" + String(repeating: "-", count: columns) + "+")
    for line in session.lines {
        print("|" + line + String(repeating: " ", count: max(0, columns - line.unicodeScalars.count)) + "|")
    }
    print("+" + String(repeating: "-", count: columns) + "+")
}

do { try run() } catch {
    print("failed: \(error)")
    exit(1)
}
