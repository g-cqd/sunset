package import Foundation

/// The sheet's question: the tabs offered, and the answer to give once.
package struct ShareRequest: Identifiable {
    package let id = UUID()
    package let sources: [ShareSource]
    private let reply: (ShareChoice) -> Void

    init(sources: [ShareSource], reply: @escaping (ShareChoice) -> Void) {
        self.sources = sources
        self.reply = reply
    }

    package func answer(_ choice: ShareChoice) { reply(choice) }
}
