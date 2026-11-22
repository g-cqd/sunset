import Foundation
import SunsetTestSupport
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The catalogs of the icon picker, kept while a picker may want them (the picker "is not really performant right now
/// at loading all symbols"). They were read again at each opening, with a spinner meanwhile.
@MainActor
@Suite("The icon picker's catalogs")
struct IconLibraryTests {
    /// How many times the files were read.
    final class Reads: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0
        func count() {
            lock.withLock { value += 1 }
        }
        var total: Int {
            lock.withLock { value }
        }
    }

    private func library(_ reads: Reads, idle: Duration = .seconds(60)) -> IconLibrary {
        IconLibrary(idle: idle) {
            reads.count()
            let symbol = SymbolCatalog.Symbol(name: "folder", keywords: [], categories: [])
            return IconCatalogs(symbols: SymbolCatalog(symbols: [symbol]), emoji: EmojiCatalog(emoji: []))
        }
    }

    @Test func `read once: asked again, and by two at once, the files are not read again`() async {
        let reads = Reads()
        let library = library(reads)
        #expect(library.ready == nil)
        async let first = library.catalogs()
        async let second = library.catalogs()
        let both = await (first, second)
        #expect(both.0.symbols.symbols.count == 1 && both.1.symbols.symbols.count == 1 && reads.total == 1)
        _ = await library.catalogs()
        #expect(reads.total == 1 && library.ready != nil)
    }

    @Test func `dropped a while after the last picker closed; kept when one opens again in time`() async throws {
        let reads = Reads()
        let time = TestTime()
        let library = library(reads, idle: .milliseconds(40))
        library.runtime = time.runtime
        library.opened()
        _ = await library.catalogs()
        library.opened()
        library.closed()
        try await time.pass(.seconds(60))
        #expect(library.ready != nil, "a picker is still open")
        let cancelled = time.mark()
        library.closed()
        try await time.waited(since: cancelled)
        library.opened()
        try await time.pass(.seconds(60))
        #expect(library.ready != nil, "opened again in time")
        let dropping = time.mark()
        library.closed()
        try await time.release(after: .milliseconds(40), since: dropping)
        #expect(library.ready == nil)
        _ = await library.catalogs()
        #expect(reads.total == 2)
    }
}
