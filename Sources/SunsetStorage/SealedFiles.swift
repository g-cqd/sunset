package import Foundation

/// Files sealed beside themselves (`name.sealed`, 0600) and opened back: what the cookie jars and the sites' storage share
/// (t114, t137).
package enum SealedFiles {
    package static let sealedExtension = "sealed"

    /// What opening did: files put back, seals dropped for a newer file in the clear, seals kept that do not open.
    package struct Opened: Equatable, Sendable {
        package var opened = 0
        package var newer = 0
        package var unreadable = 0

        package init(opened: Int = 0, newer: Int = 0, unreadable: Int = 0) {
            self.opened = opened
            self.newer = newer
            self.unreadable = unreadable
        }
    }

    package static func sealedPlace(_ file: URL) -> URL {
        file.appendingPathExtension(sealedExtension)
    }

    /// Seals `file` beside it, checks the seal opens to the same bytes, then removes the file. False: it stays in the clear.
    package static func seal(_ file: URL, identity: String, with seal: Seal) -> Bool {
        guard let plain = try? Data(contentsOf: file), let sealedData = try? seal.seal(plain, identity: identity) else {
            return false
        }
        let place = sealedPlace(file)
        guard (try? sealedData.write(to: place, options: [.atomic])) != nil,
            (try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: place.path)) != nil,
            let back = try? Data(contentsOf: place), (try? seal.open(back, identity: identity)) == plain,
            (try? FileManager.default.removeItem(at: file)) != nil
        else { return false }
        return true
    }

    /// Puts the file sealed at `place` back where it was (0600), and removes the seal. A file there already is newer
    /// (written after the seal): it stays and the seal goes. A seal that does not open (another key) is kept, never deleted.
    package static func open(_ place: URL, identity: (URL) -> String, with seal: Seal, into outcome: inout Opened) {
        let file = place.deletingPathExtension()
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: place)
            outcome.newer += 1
            return
        }
        guard let sealedData = try? Data(contentsOf: place),
            let plain = try? seal.open(sealedData, identity: identity(file)),
            (try? plain.write(to: file, options: [.atomic])) != nil
        else {
            outcome.unreadable += 1
            return
        }
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        try? FileManager.default.removeItem(at: place)
        outcome.opened += 1
    }
}
