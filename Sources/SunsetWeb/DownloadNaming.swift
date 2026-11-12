import Foundation

/// The names and kinds of downloaded files (web step f): a name that is free in the folder ("-2", "-3" before the extension), the partial file's name,
/// the kinds that need an approval (apps, installers, scripts; not disk images, the owner's answer) and those that may open after download.
package enum DownloadNaming {
    /// The kinds that run code when opened.
    static let suspicious: Set<String> = [
        "app", "pkg", "mpkg", "command", "tool", "sh", "bash", "zsh", "terminal", "workflow", "scpt", "applescript",
        "jar",
        "dylib", "bundle", "plugin", "action", "prefpane", "kext", "osax", "py", "pl", "rb"
    ]
    /// The kinds Safari calls safe: pictures, PDF, plain text, sound and film.
    static let safe: Set<String> = [
        "png", "jpg", "jpeg", "gif", "heic", "webp", "tiff", "bmp", "pdf", "txt", "mp3", "m4a", "wav", "mp4", "mov",
        "m4v"
    ]

    package static func isSuspicious(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ext.isEmpty ? false : suspicious.contains(ext)
    }

    package static func isSafe(_ name: String) -> Bool { safe.contains((name as NSString).pathExtension.lowercased()) }

    /// A file name with nothing that could leave the folder or hide (no slash, no leading dot), "download" when nothing is left.
    package static func cleaned(_ suggested: String) -> String {
        var name = suggested.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        name = name.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        return name.isEmpty ? "download" : name
    }

    /// The first of `name`, `name-2`, `name-3`… for which `taken` is false (the partial file's name counts as taken too).
    /// `ownPartial`: the partial file of `name` itself is this download's, not another's (when it finishes).
    package static func free(_ name: String, ownPartial: Bool = false, taken: (String) -> Bool) -> String {
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var candidate = name
        var number = 2
        func busy(_ candidate: String) -> Bool {
            if taken(candidate) { return true }
            return !(ownPartial && candidate == name) && taken(partial(candidate))
        }
        while busy(candidate) {
            candidate = ext.isEmpty ? "\(base)-\(number)" : "\(base)-\(number).\(ext)"
            number += 1
        }
        return candidate
    }

    /// The name of the file while it is being written.
    package static func partial(_ name: String) -> String { name + ".download" }
}
