import Foundation
import Network

/// An HTTP proxy on this Mac that answers every request with one page, and keeps the first line of each.
@MainActor
final class AnsweringProxy {
    private let listener: NWListener
    private(set) var requests: [String] = []
    var port: Int {
        Int(listener.port?.rawValue ?? 0)
    }

    private init(listener: NWListener) {
        self.listener = listener
    }

    static func start() async throws -> AnsweringProxy {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: .any)
        let proxy = AnsweringProxy(listener: try NWListener(using: parameters))
        proxy.listener.newConnectionHandler = { connection in
            Task { @MainActor in proxy.serve(connection) }
        }
        proxy.listener.start(queue: .main)
        while proxy.listener.port == nil || proxy.listener.port?.rawValue == 0 {
            try await Task.sleep(for: .milliseconds(10))
        }
        return proxy
    }

    func stop() {
        listener.cancel()
    }

    private func serve(_ connection: NWConnection) {
        connection.start(queue: .main)
        answer(connection)
    }

    /// Reads one request: a CONNECT opens the tunnel, and the request in it is read next; any other is answered with the page.
    private func answer(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, _, _ in
            let text = String(decoding: data ?? Data(), as: UTF8.self)
            Task { @MainActor in
                guard !text.isEmpty else { return connection.cancel() }
                self.requests.append(String(text.prefix { $0 != "\r" }))
                if text.hasPrefix("CONNECT ") {
                    let open = Data("HTTP/1.1 200 Connection established\r\n\r\n".utf8)
                    connection.send(content: open, completion: .contentProcessed { _ in })
                    self.answer(connection)
                    return
                }
                let body = "<title>proxied</title>through the proxy"
                let reply =
                    "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: \(body.utf8.count)\r\n"
                    + "Connection: close\r\n\r\n" + body
                connection.send(content: Data(reply.utf8), completion: .contentProcessed { _ in connection.cancel() })
            }
        }
    }
}
