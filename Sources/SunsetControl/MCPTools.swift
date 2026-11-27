/// The tools `sunset mcp` offers, each a request to the app (`ControlRequest`).
enum MCPTools {
    /// An argument of a tool: its name, its JSON type, what it is, and whether it must be given.
    struct Argument {
        let name: String
        let type: String
        let about: String
        var required = true
    }

    struct Tool {
        let name: String
        let summary: String
        let arguments: [Argument]

        var description: [String: Any] {
            var properties: [String: Any] = [:]
            for argument in arguments {
                properties[argument.name] = ["type": argument.type, "description": argument.about]
            }
            return [
                "name": name,
                "description": summary,
                "inputSchema": [
                    "type": "object",
                    "properties": properties,
                    "required": arguments.filter(\.required).map(\.name)
                ] as [String: Any]
            ]
        }
    }

    private static let pane = Argument(
        name: "pane",
        type: "string",
        about: "A pane's id from list_panes, or \"shown\" for the window in front's",
        required: false
    )

    static let all: [Tool] = [
        Tool(
            name: "list_panes",
            summary: "Lists the panes of Sunset's windows: id, kind, window, title.",
            arguments: []
        ),
        Tool(
            name: "read_pane",
            summary: "Reads a pane: a terminal's screen (and scrollback lines before it), a page's address and title.",
            arguments: [
                pane, Argument(name: "lines", type: "integer", about: "Scrollback lines before it", required: false)
            ]
        ),
        Tool(
            name: "type_into_pane",
            summary: "Types text into a terminal as keys are typed; \\r runs the line. Needs typing allowed in Sunset.",
            arguments: [pane, Argument(name: "text", type: "string", about: "What to type")]
        ),
        Tool(
            name: "wait_for_text",
            summary: "Waits until a terminal's screen shows a text, or the time is up.",
            arguments: [
                pane, Argument(name: "text", type: "string", about: "What to wait for"),
                Argument(name: "timeout", type: "number", about: "Seconds", required: false)
            ]
        ),
        Tool(
            name: "run_command",
            summary: "Runs a command of Sunset's menus in the window in front (list_commands lists them).",
            arguments: [Argument(name: "command", type: "string", about: "The command's name")]
        ),
        Tool(name: "list_commands", summary: "Lists the commands of Sunset's menus: name, title, key.", arguments: [])
    ]

    /// The request a tool's call makes; nil for a tool that is not one.
    static func request(_ name: String, _ arguments: [String: Any]) -> ControlRequest? {
        let pane = arguments["pane"] as? String ?? "shown"
        let text = arguments["text"] as? String
        switch name {
            case "list_panes": return ControlRequest(.list)
            case "list_commands": return ControlRequest(.commands)
            case "read_pane": return ControlRequest(.read, pane: pane, lines: arguments["lines"] as? Int)
            case "type_into_pane": return ControlRequest(.type, pane: pane, text: text)
            case "wait_for_text":
                return ControlRequest(.wait, pane: pane, text: text, timeout: arguments["timeout"] as? Double)
            case "run_command": return ControlRequest(.run, text: arguments["command"] as? String)
            default: return nil
        }
    }
}
