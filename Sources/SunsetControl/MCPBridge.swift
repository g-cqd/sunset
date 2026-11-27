public import Foundation

/// The control socket as an MCP server (`sunset mcp`): JSON-RPC lines on standard input and output, each tool one request
/// to the app. What the app refuses (control off, typing off, a pane stopped) comes back as the tool's error.
public struct MCPBridge {
    /// One request to the app and its reply.
    public typealias Send = (ControlRequest) throws -> ControlReply

    private let send: Send
    private let version: String

    public init(version: String, send: @escaping Send) {
        self.version = version
        self.send = send
    }

    /// The reply to one JSON-RPC line; nil for a notification, or a line that is not JSON-RPC.
    public func reply(to line: Data) -> Data? {
        guard let message = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
            let method = message["method"] as? String
        else { return nil }
        // A notification has no id and gets no answer.
        guard let id = message["id"] else { return nil }
        let params = message["params"] as? [String: Any] ?? [:]
        let result: [String: Any]
        switch method {
            case "initialize":
                result = [
                    "protocolVersion": params["protocolVersion"] as? String ?? "2025-06-18",
                    "capabilities": ["tools": [String: Any]()],
                    "serverInfo": ["name": "sunset", "version": version]
                ]
            case "ping": result = [:]
            case "tools/list": result = ["tools": MCPTools.all.map(\.description)]
            case "tools/call": result = call(params)
            default: return encode(["jsonrpc": "2.0", "id": id, "error": ["code": -32601, "message": "no \(method)"]])
        }
        return encode(["jsonrpc": "2.0", "id": id, "result": result])
    }

    /// A tool's result: the app's reply as text, or what went wrong.
    private func call(_ params: [String: Any]) -> [String: Any] {
        let name = params["name"] as? String ?? ""
        let arguments = params["arguments"] as? [String: Any] ?? [:]
        guard let request = MCPTools.request(name, arguments) else { return failed("no tool \(name)") }
        do {
            let reply = try send(request)
            guard reply.ok else { return failed(reply.error ?? "refused") }
            return ["content": [["type": "text", "text": Self.text(of: reply)]], "isError": false]
        } catch {
            return failed("\(error)")
        }
    }

    private func failed(_ message: String) -> [String: Any] {
        ["content": [["type": "text", "text": message]], "isError": true]
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
        return lines.isEmpty ? "done" : lines.joined(separator: "\n")
    }

    private func encode(_ object: [String: Any]) -> Data? {
        guard var data = try? JSONSerialization.data(withJSONObject: object, options: [.withoutEscapingSlashes]) else {
            return nil
        }
        data.append(0x0A)
        return data
    }
}
