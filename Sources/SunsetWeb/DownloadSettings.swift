package import Foundation

/// What downloads are made with, from `web.*` (web step f).
package struct DownloadSettings: Sendable, Equatable {
    package enum Keep: Sendable, Equatable { case byHand, day, week, month, untilQuit, whenFinished }

    package var folder: URL
    package var askWhereToSave = false
    package var openSafe = false
    package var notify = true
    package var approveRisky = true
    package var keep = Keep.byHand

    package init(
        folder: URL = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Downloads"),
        askWhereToSave: Bool = false,
        openSafe: Bool = false,
        notify: Bool = true,
        approveRisky: Bool = true,
        keep: Keep = .byHand
    ) {
        self.folder = folder
        self.askWhereToSave = askWhereToSave
        self.openSafe = openSafe
        self.notify = notify
        self.approveRisky = approveRisky
        self.keep = keep
    }

    /// Whether a finished download that ended at `finished` is still listed at `now`.
    package func keeps(finishedAt finished: Date, now: Date) -> Bool {
        let age = now.timeIntervalSince(finished)
        switch keep {
            case .byHand: return true
            case .day: return age < 86_400
            case .week: return age < 7 * 86_400
            case .month: return age < 31 * 86_400
            case .untilQuit, .whenFinished: return false
        }
    }
}
