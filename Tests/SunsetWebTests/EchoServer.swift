import Foundation

/// A server on this machine that answers every request with a page whose text is the User-Agent it was sent, and
/// remembers each request's head: what a site sees of Sunset. Plain sockets on a thread of its own (no Grand Central
/// Dispatch: the repository's rule).
final class EchoServer: @unchecked Sendable {
    private let lock = NSLock()
    private var requests: [String] = []
    private let listening: Int32
    let port: UInt16

    init() throws {
        let listening = socket(AF_INET, SOCK_STREAM, 0)
        self.listening = listening
        var yes: Int32 = 1
        unsafe setsockopt(listening, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))
        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        address.sin_port = 0
        let bound = withUnsafePointer(to: &address) { pointer in
            unsafe pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                unsafe bind(listening, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard listening >= 0, bound == 0, listen(listening, 16) == 0 else { throw CocoaError(.fileNoSuchFile) }
        var actual = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        _ = withUnsafeMutablePointer(to: &actual) { pointer in
            unsafe pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                unsafe getsockname(listening, $0, &length)
            }
        }
        port = UInt16(bigEndian: actual.sin_port)
        let thread = Thread { [weak self, listening] in
            while true {
                let client = accept(listening, nil, nil)
                guard client >= 0 else { return }
                self?.serve(client)
                close(client)
            }
        }
        thread.start()
    }

    deinit { close(listening) }

    /// The requests received so far, each as its head (the request line and the headers).
    var received: [String] { lock.withLock { requests } }

    /// The value of `header` in the last request for `path`.
    func header(_ header: String, for path: String) -> String? {
        let head = received.last { $0.hasPrefix("GET \(path) ") }
        let line = head?.components(separatedBy: "\r\n").first { $0.lowercased().hasPrefix(header.lowercased() + ":") }
        return line.map { String($0.dropFirst(header.count + 1)).trimmingCharacters(in: .whitespaces) }
    }

    private func serve(_ client: Int32) {
        var buffer = [UInt8](repeating: 0, count: 65536)
        var head = ""
        // Until the blank line that ends the head.
        while !head.contains("\r\n\r\n") {
            let count = unsafe read(client, &buffer, buffer.count)
            guard count > 0 else { break }
            head += String(decoding: buffer[0 ..< count], as: UTF8.self)
        }
        lock.withLock { requests.append(head) }
        let agent =
            head.components(separatedBy: "\r\n").first { $0.lowercased().hasPrefix("user-agent:") }
            .map { String($0.dropFirst("user-agent:".count)).trimmingCharacters(in: .whitespaces) } ?? ""
        let body = "<html><head><title>echo</title></head><body><p id=\"agent\">\(agent)</p></body></html>"
        let response =
            "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(body.utf8.count)\r\n"
            + "Cache-Control: no-store\r\nConnection: close\r\n\r\n" + body
        let bytes = Array(response.utf8)
        _ = unsafe write(client, bytes, bytes.count)
    }
}
