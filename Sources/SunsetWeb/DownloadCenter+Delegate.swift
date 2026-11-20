package import Foundation
import SunsetRuntime
package import WebKit

/// WebKit's questions about a download: where it goes (approval, the folder or a place asked for, a free name, written as .download first), and
/// how it ended.
extension DownloadCenter: WKDownloadDelegate {
    package func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String
    ) async -> URL? {
        guard let item = item(for: download) else { return nil }
        let name = DownloadNaming.cleaned(suggestedFilename)
        item.name = name
        item.expected = response.expectedContentLength > 0 ? response.expectedContentLength : nil
        if settings.approveRisky, DownloadNaming.isSuspicious(name), await !approve(name, item.origin) {
            remove(item)
            return nil
        }
        let folder: URL
        if item.asks ?? settings.askWhereToSave {
            guard let chosen = await choose(name) else {
                remove(item)
                return nil
            }
            folder = chosen.deletingLastPathComponent()
            item.name = chosen.lastPathComponent
        } else {
            folder = item.folder ?? settings.folder
        }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let free = DownloadNaming.free(item.name) {
            FileManager.default.fileExists(atPath: folder.appending(path: $0).path)
        }
        item.name = free
        item.destination = folder.appending(path: free)
        save()
        return item.partial
    }

    package func downloadDidFinish(_ download: WKDownload) {
        guard let item = item(for: download), let partial = item.partial, let destination = item.destination else {
            return
        }
        let folder = destination.deletingLastPathComponent()
        // A file of that name may have appeared meanwhile (its own partial file does not count).
        let free = DownloadNaming.free(item.name, ownPartial: true) {
            FileManager.default.fileExists(atPath: folder.appending(path: $0).path)
        }
        let final = folder.appending(path: free)
        try? FileManager.default.moveItem(at: partial, to: final)
        Quarantine.mark(final, source: item.source, origin: item.origin)
        item.name = free
        item.destination = final
        item.state = .finished
        item.finished = runtime.now()
        if let expected = item.expected { item.received = expected }
        item.observation = nil
        onFinished(item)
        if settings.keep == .whenFinished { items.removeAll { $0 === item } }
        save()
    }

    package func download(_ download: WKDownload, didFailWithError error: any Error, resumeData: Data?) {
        guard let item = item(for: download) else { return }
        item.resumeData = resumeData
        item.state = resumeData == nil ? .failed : .paused
        item.failure = (error as NSError).code == NSURLErrorCancelled ? nil : error.localizedDescription
        if resumeData == nil, let partial = item.partial { try? FileManager.default.removeItem(at: partial) }
        item.observation = nil
        save()
    }
}

extension DownloadCenter {
    /// Bytes WebKit already has, and where they come from.
    package struct Saved: Sendable {
        package let data: Data
        package let name: String
        package let source: URL?
        package let origin: URL?
        package let isPrivate: Bool

        package init(data: Data, name: String, source: URL?, origin: URL?, isPrivate: Bool) {
            self.data = data
            self.name = name
            self.source = source
            self.origin = origin
            self.isPrivate = isPrivate
        }
    }

    /// Bytes WebKit already has, to be saved as a download is (a film's Download Video: WebKit hands them over instead of
    /// making a download; the owner's note n64): approved if risky, the place asked for or the folder, a free name,
    /// quarantined, listed as finished. Nil when it is given up.
    package func save(_ saved: Saved, folder: URL?, asks: Bool?) async -> DownloadItem? {
        let name = DownloadNaming.cleaned(saved.name)
        if settings.approveRisky, DownloadNaming.isSuspicious(name), await !approve(name, saved.origin) { return nil }
        let place: URL
        var wanted = name
        if asks ?? settings.askWhereToSave {
            guard let chosen = await choose(name) else { return nil }
            place = chosen.deletingLastPathComponent()
            wanted = chosen.lastPathComponent
        } else {
            place = folder ?? settings.folder
        }
        try? FileManager.default.createDirectory(at: place, withIntermediateDirectories: true)
        let free = DownloadNaming.free(wanted) {
            FileManager.default.fileExists(atPath: place.appending(path: $0).path)
        }
        let final = place.appending(path: free)
        guard (try? saved.data.write(to: final, options: .withoutOverwriting)) != nil else { return nil }
        Quarantine.mark(final, source: saved.source, origin: saved.origin)
        let item = DownloadItem(source: saved.source, origin: saved.origin, name: free)
        item.isPrivate = saved.isPrivate
        item.destination = final
        item.expected = Int64(saved.data.count)
        item.received = Int64(saved.data.count)
        item.state = .finished
        item.finished = runtime.now()
        insert(item)
        onFinished(item)
        if settings.keep == .whenFinished { items.removeAll { $0 === item } }
        save()
        return item
    }
}
