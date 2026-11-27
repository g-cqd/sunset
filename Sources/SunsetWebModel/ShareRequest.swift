package import Foundation

/// The sheet's question: the tabs offered, and the answer to give once.
package struct ShareRequest: Identifiable {
    package let id = UUID()
    package let sources: [ShareSource]
    /// Who asks, as WebKit says it (the asking frame's host), when it is not the page's own site: a frame in it.
    package let frameHost: String?
    private let reply: (ShareChoice) -> Void

    package init(sources: [ShareSource], frameHost: String? = nil, reply: @escaping (ShareChoice) -> Void) {
        self.sources = sources
        self.frameHost = frameHost
        self.reply = reply
    }

    package func answer(_ choice: ShareChoice) {
        reply(choice)
    }
}
