// Run: swiftc -O -o /tmp/edns Scripts/probes/network-encrypted-dns.swift && /tmp/edns (roadmap 0046 A, 2026-11-18).
// Can a connection Sunset makes resolve its host only over DNS over HTTPS or TLS (Network.framework's privacy context), as
// a proxy inside Sunset that the pages go through would? With a resolver that works, the host is reached; with one that
// cannot be reached, it must not be (else the system's resolver answered in its place). Names never asked before.
import Foundation
import Network

func attempt(_ name: String, host: String, resolver: NWParameters.PrivacyContext.ResolverConfiguration) async -> String
{
    let context = NWParameters.PrivacyContext(description: name)
    context.requireEncryptedNameResolution(true, fallbackResolver: resolver)
    context.flushCache()
    let parameters = NWParameters.tls
    parameters.setPrivacyContext(context)
    let connection = NWConnection(host: NWEndpoint.Host(host), port: 443, using: parameters)
    return await withCheckedContinuation { done in
        let once = Once(done)
        connection.stateUpdateHandler = { state in
            switch state {
                case .ready:
                    once.finish("ready, to \(connection.currentPath?.remoteEndpoint.map { "\($0)" } ?? "?")")
                    connection.cancel()
                case .failed(let error): once.finish("failed: \(error)")
                case .waiting(let error):
                    once.finish("waiting: \(error)")
                    connection.cancel()
                default: break
            }
        }
        connection.start(queue: .main)
        Task {
            try? await Task.sleep(for: .seconds(8))
            once.finish("no answer in 8 s")
            connection.cancel()
        }
    }
}

final class Once: @unchecked Sendable {
    // Touched on the main queue only.
    private var done: CheckedContinuation<String, Never>?
    init(_ done: CheckedContinuation<String, Never>) { self.done = done }
    func finish(_ text: String) {
        done?.resume(returning: text)
        done = nil
    }
}

let doh = NWParameters.PrivacyContext.ResolverConfiguration.https(
    URL(string: "https://cloudflare-dns.com/dns-query") ?? URL(fileURLWithPath: "/"),
    serverAddresses: [.hostPort(host: "1.1.1.1", port: 443)]
)
let dot = NWParameters.PrivacyContext.ResolverConfiguration.tls(
    .hostPort(host: "one.one.one.one", port: 853),
    serverAddresses: [.hostPort(host: "1.1.1.1", port: 853)]
)
let dead = NWParameters.PrivacyContext.ResolverConfiguration.https(
    URL(string: "https://dead.invalid/dns-query") ?? URL(fileURLWithPath: "/"),
    serverAddresses: [.hostPort(host: "127.0.0.1", port: 9)]
)
Task {
    // Each its own host, never looked up on this Mac before in this run; the unreachable resolver first.
    // A name never asked before: a fresh label under a domain that answers every one (GitHub Pages).
    func fresh() -> String { "p\(UInt32.random(in: 0 ... .max)).github.io" }
    print("DoH that cannot be reached:", await attempt("dead", host: fresh(), resolver: dead))
    print("DoH (Cloudflare):", await attempt("doh", host: fresh(), resolver: doh))
    print("DoT (Cloudflare):", await attempt("dot", host: fresh(), resolver: dot))
    exit(0)
}
RunLoop.main.run()
