// sunset: asks the running Sunset over its control socket (Settings › General › Control from outside).
//
//   sunset list                         the panes of every window: id, kind, title
//   sunset read [PANE] [--lines N]      a terminal's screen (N lines of scrollback before it), a page's address
//   sunset read [PANE] --since N        a terminal's lines from N on; the next N is printed to standard error
//   sunset type PANE TEXT               types TEXT into a terminal; \r runs the line, \t \e \n \\ are escapes
//   sunset wait PANE TEXT [--timeout S] until the terminal shows TEXT (30 s unless given)
//   sunset run COMMAND                  runs a command of the menus (sunset commands lists them)
//   sunset commands
//
//   sunset mcp                          an MCP server on standard input and output, its tools these requests
//
// PANE is an id from `list`, or "shown" (the default): the pane shown in the window in front. --json prints the reply.
import Foundation
import SunsetControl

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("sunset: \(message)\n".utf8))
    exit(1)
}

/// `text` with \r \n \t \e \\ turned into what they name.
func unescaped(_ text: String) -> String {
    var result = ""
    var escaping = false
    for character in text {
        if escaping {
            switch character {
                case "r": result += "\r"
                case "n": result += "\n"
                case "t": result += "\t"
                case "e": result += "\u{1B}"
                default: result.append(character)
            }
            escaping = false
        } else if character == "\\" {
            escaping = true
        } else {
            result.append(character)
        }
    }
    return result
}

var arguments = Array(CommandLine.arguments.dropFirst())
if arguments == ["mcp"] {
    let bridge = MCPBridge(version: "1") { request in try ControlClient.send(request) }
    while let line = readLine(strippingNewline: true) {
        guard let reply = bridge.reply(to: Data(line.utf8)) else { continue }
        FileHandle.standardOutput.write(reply)
    }
    exit(0)
}
var json = false
var lines: Int?
var timeout: Double?
var since: Int?
var words: [String] = []
while !arguments.isEmpty {
    let argument = arguments.removeFirst()
    switch argument {
        case "--json": json = true
        case "--lines": lines = arguments.isEmpty ? nil : Int(arguments.removeFirst())
        case "--timeout": timeout = arguments.isEmpty ? nil : Double(arguments.removeFirst())
        case "--since": since = arguments.isEmpty ? nil : Int(arguments.removeFirst())
        case "-h", "--help":
            print(
                "usage: sunset list | read [PANE] [--lines N | --since N] | type PANE TEXT | wait PANE TEXT [--timeout S]"
            )
            print("       sunset run COMMAND | commands   (--json prints the reply)")
            exit(0)
        default: words.append(argument)
    }
}
guard let verbName = words.first, let verb = ControlRequest.Verb(rawValue: verbName) else {
    fail("expected one of: \(ControlRequest.Verb.allCases.map(\.rawValue).joined(separator: ", ")) (--help)")
}
let rest = Array(words.dropFirst())
var request = ControlRequest(verb, lines: lines, timeout: timeout, since: since)
switch verb {
    case .list, .commands: break
    case .read: request.pane = rest.first ?? "shown"
    case .type, .wait:
        guard rest.count == 2 else { fail("\(verbName) takes a pane and a text") }
        request.pane = rest[0]
        request.text = verb == .type ? unescaped(rest[1]) : rest[1]
    case .run:
        guard rest.count == 1 else { fail("run takes a command (sunset commands lists them)") }
        request.text = rest[0]
}

let reply: ControlReply
do {
    reply = try ControlClient.send(request)
} catch {
    fail("\(error)")
}
if json {
    let data = (try? ControlLine.encode(reply)) ?? Data()
    FileHandle.standardOutput.write(data)
    exit(reply.ok ? 0 : 1)
}
guard reply.ok else { fail(reply.error ?? "failed") }
if let panes = reply.panes {
    for pane in panes {
        let shown = pane.shown ? "*" : " "
        let detail = pane.detail.map { "  \($0)" } ?? ""
        print("\(shown) \(pane.id)  \(pane.kind)  w\(pane.window)  \(pane.title)\(detail)")
    }
}
if let commands = reply.commands { commands.forEach { print($0) } }
if let text = reply.text { print(text) }
if let next = reply.next, since != nil { FileHandle.standardError.write(Data("next: \(next)\n".utf8)) }
