public import Foundation
internal import SunsetWebModel

/// Whether a file a terminal links to is a program: what the system runs, starts or installs when it is opened (ADR-0118).
/// Links are followed first: a link named `notes.txt` to an app is an app.
public enum FileLinkTarget {
    public static func isProgram(_ url: URL) -> Bool {
        let target = url.resolvingSymlinksInPath()
        // The kinds that run code when opened, as downloads go by (`DownloadNaming.suspicious`).
        if DownloadNaming.isSuspicious(target.lastPathComponent) { return true }
        let values = try? target.resourceValues(forKeys: [.isDirectoryKey, .isApplicationKey, .isExecutableKey])
        if values?.isApplication == true { return true }
        // An executable file (a script with its bit, a binary); a folder's execute bit only lets it be entered.
        return values?.isDirectory == false && values?.isExecutable == true
    }
}
