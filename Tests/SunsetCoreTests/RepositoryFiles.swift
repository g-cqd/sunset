import Foundation

/// The Swift files of this repository, found from this file's own path (so the tests find them whatever the working directory).
enum RepositoryFiles {
    static let root: URL = {
        var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        while directory.path != "/",
            !FileManager.default.fileExists(atPath: directory.appending(path: "Package.swift").path)
        {
            directory.deleteLastPathComponent()
        }
        return directory
    }()

    static func swiftFiles(in folders: [String]) -> [(name: String, text: String)] {
        var files: [(name: String, text: String)] = []
        var pending = folders.map { root.appending(path: $0) }
        while let directory = pending.popLast() {
            let entries =
                (try? FileManager.default.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.isDirectoryKey]
                )) ?? []
            for entry in entries {
                if (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                    pending.append(entry)
                } else if entry.pathExtension == "swift", let text = try? String(contentsOf: entry, encoding: .utf8) {
                    files.append((entry.lastPathComponent, text))
                }
            }
        }
        return files
    }
}
