internal import AemiJSONCore
internal import AemiMCP

/// The tools `sunset mcp` offers, each a request to the app (`ControlRequest`).
enum MCPTools {
    private static let pane = MCPSchema.string("A pane's id from list_panes, or \"shown\" for the window in front's")
    private static let text = MCPSchema.string("What to type")

    static let all: [MCPTool] = [
        MCPTool(
            name: "list_panes",
            description: "Lists the panes of Sunset's windows: id, kind, window, title.",
            schema: MCPSchema.object()
        ),
        MCPTool(
            name: "read_pane",
            description:
                "Reads a pane: a terminal's screen (and scrollback lines before it), a page's address and title.",
            schema: MCPSchema.object(
                properties: [
                    "pane": pane, "lines": MCPSchema.integer("Scrollback lines before it"),
                    "since": MCPSchema.integer("Only lines from this one on (a reply's next)")
                ]
            )
        ),
        MCPTool(
            name: "type_into_pane",
            description:
                "Types text into a terminal as keys are typed; \\r runs the line. Needs typing allowed in Sunset.",
            schema: MCPSchema.object(properties: ["pane": pane, "text": text], required: ["text"])
        ),
        MCPTool(
            name: "wait_for_text",
            description: "Waits until a terminal's screen shows a text, or the time is up.",
            schema: MCPSchema.object(
                properties: [
                    "pane": pane, "text": MCPSchema.string("What to wait for"), "timeout": MCPSchema.number("Seconds")
                ],
                required: ["text"]
            )
        ),
        MCPTool(
            name: "run_command",
            description: "Runs a command of Sunset's menus in the window in front (list_commands lists them).",
            schema: MCPSchema.object(
                properties: ["command": MCPSchema.string("The command's name")],
                required: ["command"]
            )
        ),
        MCPTool(
            name: "list_commands",
            description: "Lists the commands of Sunset's menus: name, title, key.",
            schema: MCPSchema.object()
        )
    ]

    /// The request a tool's call makes; nil for a tool that is not one.
    /// - Throws: `MCPToolArguments.ValidationError` for an argument of the wrong type, which is the tool's error.
    static func request(_ name: String, _ arguments: MCPToolArguments) throws -> ControlRequest? {
        let pane = try arguments.string("pane") ?? "shown"
        let text = try arguments.string("text")
        switch name {
            case "list_panes": return ControlRequest(.list)
            case "list_commands": return ControlRequest(.commands)
            case "read_pane":
                return ControlRequest(
                    .read,
                    pane: pane,
                    lines: try arguments.integer("lines"),
                    since: try arguments.integer("since")
                )
            case "type_into_pane": return ControlRequest(.type, pane: pane, text: text)
            case "wait_for_text":
                return ControlRequest(.wait, pane: pane, text: text, timeout: try arguments.double("timeout"))
            case "run_command": return ControlRequest(.run, text: try arguments.string("command"))
            default: return nil
        }
    }
}
