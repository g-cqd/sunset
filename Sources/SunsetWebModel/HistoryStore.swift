package import Foundation
package import SunsetRuntime
package import SunsetStorage

/// The history of pages visited: an address, its title, its visit count and its last visit. Kept as sealed records of
/// the state database: nothing of it is in the file in the clear, so it is held whole in memory, latest first, and
/// searched there. Without a table it is in memory only (a private window, tests).
@MainActor
package final class HistoryStore {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
    package var runtime = Runtime.live

    package var byAddress: [String: Page] = [:]
    /// By last visit, the oldest first: a visit now is added at the end, and the lists read from the end. A page visited again
    /// leaves its old place marked `gone` (finding it would mean walking the list); the marks are swept when there are many.
    package var ordered: [Page] = []
    package var goneCount = 0
    package let table: SealedTable?
    /// The kept history is all in memory. False for a moment after a large history is opened: its records are opened off the
    /// main actor, and what is visited or removed meanwhile is joined to them when they arrive.
    package private(set) var isLoaded = true
    private var loading: Task<Void, Never>?
    package var removed = Removed()
    /// Records that did not open when the history was read (altered or damaged): they are not shown.
    package private(set) var unreadable = 0
    /// Something was written (a visit, a title, a deletion): lists that show the history read it again.
    package var onChange: () -> Void = {}

    /// Opens the history kept in `table`. Fewer records than `atOnceBelow` are opened here and now; more are opened off the
    /// main actor (`ready()` waits for them), so that a long history does not hold up the launch.
    /// - Complexity: O(the history's bytes): every record is opened once.
    package init(table: SealedTable? = nil, atOnceBelow: Int = 2048) {
        self.table = table
        guard let table else { return }
        let sealed = table.sealed()
        if sealed.count < atOnceBelow {
            install(sealed.open { Kept($0) })
        } else {
            isLoaded = false
            loading = runtime.task { [weak self] in
                let read = await sealed.openConcurrently { Kept($0) }
                self?.install(read)
            }
        }
    }

    /// Returns once the kept history is all in memory.
    package func ready() async {
        await loading?.value
    }

    /// Takes in the kept pages (the latest first), joined to what happened since the reading began.
    private func install(_ read: (values: [Kept], unreadable: Int)) {
        unreadable = read.unreadable
        let untouched = ordered.isEmpty
        ordered.reserveCapacity(ordered.count + read.values.count)
        byAddress.reserveCapacity(read.values.count)
        // What was removed while the history was being read goes from the table by name now.
        removeKept(read.values.filter { removed.covers($0.entry) }.map(\.entry.url))
        for kept in read.values.reversed() where !removed.covers(kept.entry) {
            if let page = byAddress[kept.entry.url] {
                // Visited while the history was being read: that visit is added to the kept ones.
                page.entry.visits += kept.entry.visits
                if page.entry.title.isEmpty {
                    page.entry.title = kept.entry.title
                    page.hay = kept.hay
                }
                keep(page)
            } else {
                let page = Page(kept)
                byAddress[kept.entry.url] = page
                ordered.append(page)
            }
        }
        if !untouched { ordered.sort { $0.entry.lastVisit < $1.entry.lastVisit } }
        removed = Removed()
        loading = nil
        if !isLoaded {
            isLoaded = true
            onChange()
        }
    }

    package var count: Int {
        byAddress.count
    }

    /// A visit to `url` at `time`: counted, its title kept when it has one.
    package func visit(_ url: String, title: String, at time: Date = Runtime.live.now()) {
        var entry = HistoryEntry(url: url, title: title, visits: 1, lastVisit: time)
        if let page = byAddress[url] {
            entry.visits = page.entry.visits + 1
            if title.isEmpty { entry.title = page.entry.title }
            drop(page)
        }
        place(Page(entry))
        onChange()
    }

    /// Pages kept elsewhere (Sunset WebKit's history of before), added: a page in both keeps the visits of both, its
    /// later visit and that visit's title.
    package func merge(_ entries: [HistoryEntry]) {
        for entry in entries {
            var merged = entry
            if let page = byAddress[entry.url] {
                merged.visits += page.entry.visits
                let ours = page.entry.lastVisit > entry.lastVisit
                merged.lastVisit = max(page.entry.lastVisit, entry.lastVisit)
                if ours && !page.entry.title.isEmpty || merged.title.isEmpty { merged.title = page.entry.title }
                drop(page)
            }
            place(Page(merged))
        }
        onChange()
    }

    /// The page's title arrived after its visit was counted.
    package func retitle(_ url: String, title: String) {
        guard !title.isEmpty, let page = byAddress[url] else { return }
        page.entry.title = title
        page.hay = Self.folded(Array((url + "\n" + title).utf8))
        keep(page)
        onChange()
    }

    package func delete(_ url: String) {
        if !isLoaded { removed.addresses.insert(url) }
        if let page = byAddress.removeValue(forKey: url) { drop(page) }
        table?.remove(url)
        onChange()
    }

    /// Forgets the pages last visited since `date` (all for `.distantPast`).
    package func clear(since date: Date) {
        if !isLoaded { removed.since = min(removed.since ?? date, date) }
        forget { $0.entry.lastVisit >= date }
        onChange()
    }

    /// Forgets the pages last visited before `date` (what `web.history.keep` no longer keeps).
    package func expire(before date: Date) {
        if !isLoaded { removed.before = max(removed.before ?? date, date) }
        forget { $0.entry.lastVisit < date }
    }

    // MARK: In memory

    /// Forgets the pages `forgotten` names, in memory and in the table by name (format 2 seals the times).
    private func forget(_ forgotten: (Page) -> Bool) {
        var gone: [String] = []
        ordered.removeAll { page in
            if page.gone { return true }
            guard forgotten(page) else { return false }
            byAddress[page.entry.url] = nil
            gone.append(page.entry.url)
            return true
        }
        goneCount = 0
        removeKept(gone)
    }

    /// Takes these pages out of the table, as one transaction.
    private func removeKept(_ urls: [String]) {
        guard let table, !urls.isEmpty else { return }
        table.transaction {
            for url in urls { table.remove(url) }
        }
    }

    /// Marks a page's place in the list as empty; sweeps the marks when a quarter of the list is marked.
    private func drop(_ page: Page) {
        page.gone = true
        goneCount += 1
        if goneCount > 1024, goneCount > ordered.count / 4 {
            ordered.removeAll(where: \.gone)
            goneCount = 0
        }
    }

    /// Puts a page where its last visit belongs (the end, for a visit now), and keeps it.
    private func place(_ page: Page) {
        byAddress[page.entry.url] = page
        if let last = ordered.last, last.entry.lastVisit > page.entry.lastVisit {
            // An earlier time than the latest (a visit given its time): before the first page visited later.
            var low = 0
            var high = ordered.count
            while low < high {
                let middle = (low + high) / 2
                if ordered[middle].entry.lastVisit <= page.entry.lastVisit { low = middle + 1 } else { high = middle }
            }
            ordered.insert(page, at: low)
        } else {
            ordered.append(page)
        }
        keep(page)
    }

    private func keep(_ page: Page) {
        table?
            .put(
                page.entry.url,
                payload: Data((page.entry.url + "\n" + page.entry.title).utf8),
                sort: page.entry.lastVisit.timeIntervalSince1970,
                count: page.entry.visits
            )
    }

    /// Adds pages read from elsewhere (the history of before the database), as one transaction; a page already known is left.
    package func adopt(_ entries: [HistoryEntry]) {
        let add = {
            for entry in entries where self.byAddress[entry.url] == nil {
                let page = Page(entry)
                self.byAddress[entry.url] = page
                self.ordered.append(page)
                self.keep(page)
            }
        }
        if let table { table.transaction(add) } else { add() }
        ordered.sort { $0.entry.lastVisit < $1.entry.lastVisit }
        onChange()
    }
}
