package import Foundation
package import Observation
package import WebKit

/// The app's downloads (web step f): the list, kept in a file beside the session; each download's name and place decided (approval for risky kinds,
/// a free name, the partial file), its progress followed, the file renamed, marked as downloaded (quarantine) and announced when it finishes.
@MainActor @Observable
package final class DownloadCenter: NSObject {
    package static let shared = DownloadCenter()

    /// Latest first.
    package internal(set) var items: [DownloadItem] = []
    @ObservationIgnored package var settings = DownloadSettings()
    /// Where the list is kept; nil: not kept (tests).
    @ObservationIgnored package var path: String? {
        didSet { load() }
    }
    /// Asked before a risky kind is saved: its name and the page it comes from.
    @ObservationIgnored package var approve: (String, URL?) async -> Bool = { _, _ in true }
    /// Asked for the place of a file when the settings say to ask; nil: the download is given up.
    @ObservationIgnored package var choose: (String) async -> URL? = { _ in nil }
    @ObservationIgnored package var onFinished: (DownloadItem) -> Void = { _ in }
    /// A page that is never shown, for resuming (WebKit resumes through a web view).
    @ObservationIgnored private lazy var resumer = WKWebView(frame: .zero)

    package var running: [DownloadItem] { items.filter { $0.state == .running } }
    package var latest: DownloadItem? { items.first }

    /// The whole progress of what runs, from 0 to 1 (nil when nothing runs or no size is known).
    package var progress: Double? {
        let known = running.compactMap { item in item.expected.map { (item.received, $0) } }
        let total = known.reduce(Int64(0)) { $0 + $1.1 }
        guard total > 0 else { return running.isEmpty ? nil : 0 }
        return Double(known.reduce(Int64(0)) { $0 + $1.0 }) / Double(total)
    }

    // MARK: Starting

    /// A navigation became a download: it is followed from here.
    package func adopt(_ download: WKDownload, origin: URL?) {
        let item = DownloadItem(source: download.originalRequest?.url, origin: origin, name: "download")
        item.download = download
        items.insert(item, at: 0)
        download.delegate = self
        follow(item, download)
        save()
    }

    private func follow(_ item: DownloadItem, _ download: WKDownload) {
        item.observation = download.progress.observe(\.completedUnitCount, options: [.new]) { [weak item] progress, _ in
            let done = progress.completedUnitCount
            let total = progress.totalUnitCount
            Task { @MainActor in
                item?.received = done
                item?.expected = total > 0 ? total : nil
            }
        }
    }

    func item(for download: WKDownload) -> DownloadItem? { items.first { $0.download === download } }

    // MARK: Acting

    /// Stop: the download is cut, with what resumes it.
    package func stop(_ item: DownloadItem) {
        guard item.state == .running, let download = item.download else { return }
        download.cancel { [weak self] data in
            Task { @MainActor in
                item.resumeData = data
                item.state = data == nil ? .failed : .paused
                // The server cannot resume: the partial file is of no use.
                if data == nil, let partial = item.partial { try? FileManager.default.removeItem(at: partial) }
                if data == nil { item.failure = "Stopped; this server cannot resume it" }
                self?.save()
            }
        }
    }

    package func resume(_ item: DownloadItem) {
        guard let data = item.resumeData else { return }
        resumer.resumeDownload(fromResumeData: data) { [weak self] download in
            MainActor.assumeIsolated {
                guard let self else { return }
                item.resumeData = nil
                item.state = .running
                item.failure = nil
                item.download = download
                download.delegate = self
                self.follow(item, download)
                self.save()
            }
        }
    }

    /// Out of the list; a file not finished goes with it.
    package func remove(_ item: DownloadItem) {
        if item.state != .finished, let partial = item.partial { try? FileManager.default.removeItem(at: partial) }
        item.download?.cancel()
        items.removeAll { $0 === item }
        save()
    }

    /// Clear: the finished, failed and paused ones go from the list (their files stay; a partial file goes).
    package func clear() {
        for item in items where item.state != .running { remove(item) }
    }

    /// The app is quitting: what runs is cut with what resumes it (waiting up to two seconds for WebKit), the list is kept as the settings say.
    package func finish() {
        let cutting = running
        var left = cutting.count
        for item in cutting {
            item.download?
                .cancel { data in
                    MainActor.assumeIsolated {
                        item.resumeData = data
                        item.state = data == nil ? .failed : .paused
                        left -= 1
                    }
                }
        }
        let limit = Date().addingTimeInterval(2)
        while left > 0, Date() < limit { RunLoop.main.run(until: Date().addingTimeInterval(0.05)) }
        if settings.keep == .untilQuit { items.removeAll { $0.state == .finished } }
        save()
    }

    // MARK: Keeping

    func save() {
        guard let path else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let data = try? encoder.encode(items.map(\.record)) else { return }
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: path).deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
    }

    private func load() {
        items = []
        guard let path, let data = FileManager.default.contents(atPath: path) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let records = (try? decoder.decode([DownloadItem.Record].self, from: data)) ?? []
        let now = Date()
        items = records.map(DownloadItem.init)
            .filter { item in
                guard item.state == .finished, let finished = item.finished else { return true }
                return settings.keeps(finishedAt: finished, now: now)
            }
    }

    /// Lists a download as given (tests, and what is read back).
    func insert(_ item: DownloadItem) {
        items.insert(item, at: 0)
        save()
    }
}
