public import Foundation
internal import SunsetWebModel
internal import UniformTypeIdentifiers

/// Whether a file a terminal links to is a program: what the system runs, starts or installs when it is opened (ADR-0118).
/// Links are followed first, symbolic links and Finder aliases alike (Launch Services opens what an alias names): a link
/// named `notes.txt` to an app is an app, and one whose target cannot be found is treated as one.
public enum FileLinkTarget {
    /// What `url` names once symbolic links and Finder aliases are followed (at most 16 of them), without mounting a
    /// volume or asking anything of the user; nil when it names nothing that can be found.
    public static func target(of url: URL) -> URL? {
        var current = url.resolvingSymlinksInPath()
        for _ in 0 ..< 16 {
            guard (try? current.resourceValues(forKeys: [.isAliasFileKey]))?.isAliasFile == true else {
                return FileManager.default.fileExists(atPath: current.path) ? current : nil
            }
            guard let next = try? URL(resolvingAliasFileAt: current, options: [.withoutUI, .withoutMounting]) else {
                return nil
            }
            current = next.resolvingSymlinksInPath()
        }
        return nil
    }

    public static func isProgram(_ url: URL) -> Bool {
        guard let target = target(of: url) else { return true }
        let name = target.lastPathComponent
        // The kinds that run code when opened, as downloads go by (`DownloadNaming.suspicious`), and as macOS goes by.
        if DownloadNaming.isSuspicious(name) || RiskyKinds.extensions.contains(target.pathExtension.lowercased()) {
            return true
        }
        let values = try? target.resourceValues(forKeys: [
            .isDirectoryKey, .isApplicationKey, .isExecutableKey, .contentTypeKey
        ])
        if values?.isApplication == true { return true }
        let kinds = [values?.contentType, UTType(filenameExtension: target.pathExtension)].compactMap(\.self)
        if kinds.contains(where: RiskyKinds.conforms) { return true }
        // An executable file (a script with its bit, a binary); a folder's execute bit only lets it be entered.
        return values?.isDirectory == false && values?.isExecutable == true
    }
}
