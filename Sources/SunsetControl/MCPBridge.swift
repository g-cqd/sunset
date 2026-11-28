internal import AemiMCP
public import Foundation

/// The control socket as an MCP server (`sunset mcp`): JSON-RPC lines on standard input and output, each tool one request
/// to the app. What the app refuses (control off, typing off, a pane stopped) comes back as the tool's error. The protocol
/// itself (version negotiation, strict JSON-RPC, errors) is AemiMCP's.
public struct MCPBridge {
    /// One request to the app and its reply.
    public typealias Send = (ControlRequest) throws -> ControlReply

    private let send: Send
    private let server: MCPSyncServer

    public init(version: String, send: @escaping Send) {
        self.send = send
        server = MCPSyncServer(
            configuration: MCPServerConfiguration(name: "sunset", version: version),
            tools: MCPTools.all
        )
    }

    /// The reply to one JSON-RPC line, with its newline; nil for a notification or a blank line.
    public func reply(to line: Data) -> Data? {
        let bytes = Array(line)
        guard bytes.contains(where: { $0 != 0x20 && $0 != 0x09 && $0 != 0x0D }),
            var reply = server.handle(bytes, callTool: call)
        else { return nil }
        reply.append(0x0A)
        return Data(reply)
    }

    /// A tool's result: the app's reply as text, or what went wrong.
    private func call(_ name: String, _ arguments: MCPToolArguments) throws -> MCPToolResult {
        guard let request = try MCPTools.request(name, arguments) else { return .error("no tool \(name)") }
        let reply = try send(request)
        guard reply.ok else { return .error(reply.error ?? "refused") }
        return .text(Self.text(of: reply))
    }

    /// A reply as the text a model reads: the panes a line each, the commands, the screen.
    static func text(of reply: ControlReply) -> String {
        var lines: [String] = []
        for pane in reply.panes ?? [] {
            let detail = pane.detail.map { " — \($0)" } ?? ""
            lines.append(
                "\(pane.id) \(pane.kind) window \(pane.window)\(pane.shown ? " shown" : ""): \(pane.title)\(detail)"
            )
        }
        lines += reply.commands ?? []
        if let text = reply.text { lines.append(text) }
        // A model follows a terminal by reading again from it.
        if let next = reply.next { lines.append("[next: \(next)]") }
        return lines.isEmpty ? "done" : lines.joined(separator: "\n")
    }
}
