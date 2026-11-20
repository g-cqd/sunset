package import Foundation
package import SunsetConfig
package import SunsetWebModel

/// The download center's settings from the file's (roadmap 0086 D: `AppDownloads` made them in the app target).
package enum DownloadSettingsMaker {
    package static func make(_ web: Configuration.Web, folder: URL) -> DownloadSettings {
        let keep: DownloadSettings.Keep =
            switch web.keepDownloads {
                case .byHand: .byHand
                case .day: .day
                case .week: .week
                case .month: .month
                case .untilQuit: .untilQuit
                case .whenFinished: .whenFinished
            }
        return DownloadSettings(
            folder: folder,
            askWhereToSave: web.askWhereToSave,
            openSafe: web.openSafeDownloads,
            notify: web.notifyDownloads,
            approveRisky: web.approveRiskyDownloads,
            keep: keep
        )
    }
}
