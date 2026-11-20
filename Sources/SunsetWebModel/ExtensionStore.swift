package import Foundation
import SunsetPane

/// The extensions installed in one profile (roadmap 0109 A, ADR-0109): each a copy in the profile's folder (a zip WebKit loads,
/// or an unpacked folder copied as it is), listed in that folder's `index.json`: its name, on or off, in private windows or not
/// (off by default), what the person granted at install.
package struct ExtensionStore {
    package struct Installed: Codable, Equatable, Sendable, Identifiable {
        package let id: UUID
        package var name: String
        package var enabled: Bool
        package var inPrivate: Bool
        /// What was granted at install: API permissions and site patterns, as the manifest names them.
        package var granted: [String]
        /// The copy's name in the folder: `<id>.zip`, or `<id>` for an unpacked folder.
        package let file: String
    }

    /// The profile's folder.
    package let folder: URL
    package private(set) var installed: [Installed]

    /// `root` holds a folder per profile; nil is the default profile's.
    package init(root: URL, profile: UUID?) {
        folder = root.appending(path: profile?.uuidString ?? "default")
        let index = folder.appending(path: "index.json")
        installed = (try? JSONDecoder().decode([Installed].self, from: Data(contentsOf: index))) ?? []
    }

    /// Where WebKit loads it from.
    package func file(of extension: Installed) -> URL {
        folder.appending(path: `extension`.file)
    }

    /// Copies what the person picked: a folder as it is; a `.zip`, `.xpi` or `.crx` as the zip WebKit loads. On, not in
    /// private windows.
    @discardableResult
    package mutating func install(from source: URL, name: String, granted: [String]) throws -> Installed {
        let id = UUID()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var isFolder: ObjCBool = false
        let file: String
        if FileManager.default.fileExists(atPath: source.path, isDirectory: &isFolder), isFolder.boolValue {
            file = id.uuidString
            try FileManager.default.copyItem(at: source, to: folder.appending(path: file))
        } else {
            let zip = try ExtensionPackage.zip(from: Data(contentsOf: source))
            file = id.uuidString + ".zip"
            try zip.write(to: folder.appending(path: file), options: .atomic)
        }
        let entry = Installed(id: id, name: name, enabled: true, inPrivate: false, granted: granted, file: file)
        installed.append(entry)
        save()
        return entry
    }

    package mutating func set(_ id: UUID, enabled: Bool) {
        update(id) { $0.enabled = enabled }
    }

    package mutating func set(_ id: UUID, inPrivate: Bool) {
        update(id) { $0.inPrivate = inPrivate }
    }

    /// To `index` in the order (the order of their buttons).
    package mutating func move(_ id: UUID, to index: Int) {
        guard installed.move(id: id, to: index) else { return }
        save()
    }

    /// `offset` places later (earlier when negative); past either end, it stays.
    package mutating func move(_ id: UUID, by offset: Int) {
        guard let from = installed.firstIndex(where: { $0.id == id }) else { return }
        let to = from + offset
        guard installed.indices.contains(to) else { return }
        move(id, to: to)
    }

    /// Its copy and its entry gone.
    package mutating func remove(_ id: UUID) {
        guard let entry = installed.first(where: { $0.id == id }) else { return }
        try? FileManager.default.removeItem(at: file(of: entry))
        installed.removeAll { $0.id == id }
        save()
    }

    private mutating func update(_ id: UUID, _ change: (inout Installed) -> Void) {
        guard let index = installed.firstIndex(where: { $0.id == id }) else { return }
        change(&installed[index])
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(installed) else { return }
        try? data.write(to: folder.appending(path: "index.json"), options: .atomic)
    }
}
