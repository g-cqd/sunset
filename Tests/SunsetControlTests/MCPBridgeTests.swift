import Foundation
import Testing

@testable import SunsetControl

/// `sunset mcp`: JSON-RPC lines in, each tool a request to the app, its reply the tool's text.
@Suite("The MCP bridge")
struct MCPBridgeTests {
    private func object(_ data: Data?) throws -> [String: Any] {
        let line = try #require(data)
        let parsed = try JSONSerialization.jsonObject(with: line)
        return try #require(parsed as? [String: Any])
    }

    @Test func `it introduces itself, lists its tools, and leaves notifications unanswered`() throws {
        let bridge = MCPBridge(version: "1") { _ in ControlReply() }
        let hello = try object(
            bridge.reply(to: Data(#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}"#.utf8))
        )
        #expect((hello["result"] as? [String: Any])?["serverInfo"] != nil)
        let tools = try object(bridge.reply(to: Data(#"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#.utf8)))
        let names = ((tools["result"] as? [String: Any])?["tools"] as? [[String: Any]])?
            .compactMap { $0["name"] as? String }
        #expect(names?.contains("read_pane") == true && names?.contains("type_into_pane") == true)
        #expect(bridge.reply(to: Data(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#.utf8)) == nil)
    }

    @Test func `a tool's call is the app's request; a refusal is the tool's error`() throws {
        var asked: [ControlRequest] = []
        let bridge = MCPBridge(version: "1") { request in
            asked.append(request)
            return request.verb == .type ? .failure("typing into terminals is off") : ControlReply(text: "$ ")
        }
        let read = try object(
            bridge.reply(
                to: Data(
                    #"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"read_pane","arguments":{"lines":5}}}"#
                        .utf8
                )
            )
        )
        let result = try #require(read["result"] as? [String: Any])
        #expect(result["isError"] as? Bool == false)
        #expect(asked.first == ControlRequest(.read, pane: "shown", lines: 5))
        let typed = try object(
            bridge.reply(
                to: Data(
                    #"{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"type_into_pane","arguments":{"text":"ls\r"}}}"#
                        .utf8
                )
            )
        )
        #expect((typed["result"] as? [String: Any])?["isError"] as? Bool == true)
    }

    @Test func `read_pane with since asks for the lines from there, and says the next`() throws {
        var asked: ControlRequest?
        let bridge = MCPBridge(version: "1") { request in
            asked = request
            var reply = ControlReply(text: "$ ls")
            reply.next = 42
            return reply
        }
        let line =
            #"{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"read_pane","arguments":{"since":40}}}"#
        let read = try object(bridge.reply(to: Data(line.utf8)))
        #expect(asked == ControlRequest(.read, pane: "shown", since: 40))
        let content = (read["result"] as? [String: Any])?["content"] as? [[String: Any]]
        #expect((content?.first?["text"] as? String)?.hasSuffix("[next: 42]") == true)
    }

    @Test func `it speaks the protocol strictly: versions negotiated, bad lines answered, blank lines ignored`() throws
    {
        let bridge = MCPBridge(version: "1") { _ in ControlReply() }
        let old = try object(
            bridge.reply(
                to: Data(
                    #"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}"#.utf8
                )
            )
        )
        #expect((old["result"] as? [String: Any])?["protocolVersion"] as? String == "2024-11-05")
        let unknown = try object(
            bridge.reply(
                to: Data(
                    #"{"jsonrpc":"2.0","id":2,"method":"initialize","params":{"protocolVersion":"1999-01-01"}}"#.utf8
                )
            )
        )
        #expect((unknown["result"] as? [String: Any])?["protocolVersion"] as? String == "2025-11-25")
        let garbage = try object(bridge.reply(to: Data("{not json".utf8)))
        #expect((garbage["error"] as? [String: Any])?["code"] as? Int == -32700)
        #expect(bridge.reply(to: Data("  ".utf8)) == nil)
        let wrongType = try object(
            bridge.reply(
                to: Data(
                    #"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"read_pane","arguments":{"lines":"five"}}}"#
                        .utf8
                )
            )
        )
        #expect((wrongType["result"] as? [String: Any])?["isError"] as? Bool == true)
    }
}
