public import Foundation
public import SunsetRuntime

/// Where Export All writes (R12 step ST-6): a dated folder of its own in the folder the person chose, so that an export never
/// mixes with what is there, and file names that never write over one another.
public enum ExportFolder {
    /// Makes "Sunset Export 2026-11-15" in `parent` (with a number when there is one already), and says where it is.
    public static func make(in parent: URL, now: Date = Runtime.live.now(), calendar: Calendar = .current) throws -> URL
    {
        let day = calendar.dateComponents([.year, .month, .day], from: now)
        let name = String(format: "Sunset Export %04d-%02d-%02d", day.year ?? 0, day.month ?? 0, day.day ?? 0)
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        for attempt in 1 ... 1000 {
            let folder = parent.appending(path: attempt == 1 ? name : "\(name) \(attempt)", directoryHint: .isDirectory)
            guard !FileManager.default.fileExists(atPath: folder.path) else { continue }
            // The person's only: what is in it is plain text.
            try FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700]
            )
            return folder
        }
        throw CocoaError(.fileWriteFileExists)
    }

    /// File names given out for one folder: a name already given gets a number before its extension. Names that differ only
    /// by case count as one, as on the Mac's disks.
    public struct Names {
        private var taken: [String: Int] = [:]

        public init() {}

        public mutating func next(_ name: String) -> String {
            let key = name.lowercased()
            let count = (taken[key] ?? 0) + 1
            taken[key] = count
            guard count > 1 else { return name }
            // The extension starts at the last dot that is not the name's first character.
            guard let dot = name.lastIndex(of: "."), dot != name.startIndex else { return "\(name) \(count)" }
            let numbered = "\(name[..<dot]) \(count)\(name[dot...])"
            // The numbered name may itself have been given ("Notes 2.md" as a title): it is taken from now on.
            taken[numbered.lowercased(), default: 0] += 1
            return numbered
        }
    }
}
