import Foundation
import Testing

@testable import SunsetControl

/// The control socket answers its user's requests line for line, and refuses what is not one.
@Suite("The control socket")
struct ControlSocketTests {
    private func path() -> String {
        // Short: a socket's path has at most 103 bytes.
        "/tmp/sunset-control-\(UUID().uuidString.prefix(8))/control.sock"
    }

    @Test func `a request is answered by the handler; the socket's folder and file are the user's only`() throws {
        let path = path()
        let server = ControlServer(path: path)
        try server.start { request in
            request.verb == .read ? ControlReply(text: "screen of \(request.pane ?? "?")") : .failure("no")
        }
        defer { server.stop() }
        let reply = try ControlClient.send(ControlRequest(.read, pane: "shown"), path: path)
        #expect(reply == ControlReply(text: "screen of shown"))
        #expect(try ControlClient.send(ControlRequest(.list), path: path).error == "no")
        let folder = (path as NSString).deletingLastPathComponent
        let mode = try FileManager.default.attributesOfItem(atPath: folder)[.posixPermissions] as? Int
        #expect(mode == 0o700)
    }

    @Test func `nothing listening is said plainly`() {
        #expect(throws: ControlClient.Failure.self) {
            try ControlClient.send(ControlRequest(.list), path: "/tmp/sunset-none-\(UUID().uuidString.prefix(8)).sock")
        }
    }

    @Test func `a request and a reply are one line of JSON each`() throws {
        let line = try ControlLine.encode(ControlRequest(.type, pane: "shown", text: "ls\r"))
        #expect(line.last == 0x0A && !line.dropLast().contains(0x0A))
        let back = try ControlLine.decode(ControlRequest.self, from: line.dropLast())
        #expect(back == ControlRequest(.type, pane: "shown", text: "ls\r"))
    }
}
