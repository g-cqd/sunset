import Observation

/// What is shared into a call now, of every kind (a page, a terminal, a document): a count for each content, since
/// several calls may share one. While a content is shared its tab says so (`captureMark`).
@MainActor @Observable
package final class SharedPanes {
    package static let shared = SharedPanes()

    private var counts: [ObjectIdentifier: Int] = [:]

    package init() {}

    /// A share of `content` began, or ended.
    package func change(_ content: some AnyObject, sharing: Bool) {
        let key = ObjectIdentifier(content)
        let count = max(0, (counts[key] ?? 0) + (sharing ? 1 : -1))
        counts[key] = count == 0 ? nil : count
    }

    /// How many shares of `content` run.
    package func count(_ content: some AnyObject) -> Int {
        counts[ObjectIdentifier(content)] ?? 0
    }

    /// Its tab's mark: a screen shared, while any share runs.
    package func mark(_ content: some AnyObject) -> PaneCaptureMark? {
        count(content) > 0 ? .screen : nil
    }
}
