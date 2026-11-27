import Foundation

/// Whether the running app's files were replaced on disk since it started (an update installed beside it, a build copied
/// over it): its helper processes then start from the new files and fail, and pages end one after the other until Sunset
/// opens again (the owner's note n151).
package enum BundleOnDisk {
    /// The executable's identity as Sunset started: its file number and when it was last written.
    private static let atLaunch = identity()

    /// Read once at launch: before anything could replace the files.
    package static func remember() {
        _ = atLaunch
    }

    /// Whether the executable on disk is no longer the one that started.
    package static var changed: Bool {
        guard let atLaunch else { return false }
        return identity() != atLaunch
    }

    private static func identity() -> [String]? {
        guard let path = Bundle.main.executablePath,
            let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        else { return nil }
        let number = (attributes[.systemFileNumber] as? NSNumber)?.stringValue ?? ""
        let written = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
        return [number, String(written)]
    }
}
