import Foundation
import SunsetUpdate
import Testing

/// A package made between two bundles rebuilds the new one from the old, exactly (roadmap 0122 C, D).
struct UpdatePackageTests {
    /// A folder under the temporary directory, removed after `body`.
    static func inFolder(_ body: (URL) throws -> Void) throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "update-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try body(folder)
    }

    /// A small bundle: an executable, resources, a framework with its `Versions/Current` link.
    static func bundle(at url: URL, executable: [UInt8], resource: String, extra: Bool) throws {
        let files = FileManager.default
        for folder in ["Contents/MacOS", "Contents/Resources", "Contents/Frameworks/K.framework/Versions/A"] {
            try files.createDirectory(at: url.appending(path: folder), withIntermediateDirectories: true)
        }
        try Data(executable).write(to: url.appending(path: "Contents/MacOS/App"))
        try files.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: url.appending(path: "Contents/MacOS/App").path
        )
        try Data(resource.utf8).write(to: url.appending(path: "Contents/Resources/text.txt"))
        try Data("same".utf8).write(to: url.appending(path: "Contents/Resources/same.txt"))
        try Data("k".utf8).write(to: url.appending(path: "Contents/Frameworks/K.framework/Versions/A/K"))
        try files.createSymbolicLink(
            atPath: url.appending(path: "Contents/Frameworks/K.framework/Versions/Current").path,
            withDestinationPath: "A"
        )
        if extra { try Data("new".utf8).write(to: url.appending(path: "Contents/Resources/added.txt")) }
    }

    static func pair(in folder: URL) throws -> (old: URL, new: URL) {
        let old = folder.appending(path: "old.app")
        let new = folder.appending(path: "new.app")
        let code = BinaryDeltaTests.bytes(40_000, seed: 11)
        try bundle(at: old, executable: code, resource: "before", extra: false)
        try bundle(at: new, executable: BinaryDeltaTests.edited(code), resource: "after", extra: true)
        return (old, new)
    }

    @Test func rebuildsTheNewBundleFromTheOldExactly() throws {
        try Self.inFolder { folder in
            let (old, new) = try Self.pair(in: folder)
            let data = try UpdatePackage.make(old: old, new: new, from: 1, to: 2)
            let package = try UpdatePackage(decoding: data)
            #expect(package.from == 1 && package.to == 2)
            #expect(data.count < 40_000 / 4)
            let staging = folder.appending(path: "staging.app")
            try UpdateStaging.build(package, running: old, staging: staging)
            #expect(try BundleManifest.read(bundle: staging) == BundleManifest.read(bundle: new))
            #expect(try BundleManifest.read(bundle: staging) == package.manifest)
        }
    }

    @Test func refusesToStageOnABundleItWasNotMadeFor() throws {
        try Self.inFolder { folder in
            let (old, new) = try Self.pair(in: folder)
            let package = try UpdatePackage(decoding: UpdatePackage.make(old: old, new: new, from: 1, to: 2))
            try Data("changed".utf8).write(to: old.appending(path: "Contents/MacOS/App"))
            #expect(throws: BinaryDelta.Failure.otherOldFile) {
                try UpdateStaging.build(package, running: old, staging: folder.appending(path: "staging.app"))
            }
        }
    }

    @Test func refusesPathsOutsideTheBundle() throws {
        let header = """
            {"from": 1, "to": 2, "items": [{"entry": {"path": "../../evil", "kind": "directory"}}]}
            """
        var data = Data("SSUPDAT1".utf8)
        data.append(littleEndian: header.utf8.count)
        data.append(Data(header.utf8))
        #expect(throws: UpdatePackage.Failure.outside("../../evil")) { try UpdatePackage(decoding: data) }
    }

    @Test func refusesToWriteUnderALinkItMakes() throws {
        let header = """
            {"from": 1, "to": 2, "items": [{"entry": {"path": "Contents/out", "kind": "link", "target": "/tmp"}},
             {"entry": {"path": "Contents/out/evil", "kind": "directory"}}]}
            """
        var data = Data("SSUPDAT1".utf8)
        data.append(littleEndian: header.utf8.count)
        data.append(Data(header.utf8))
        #expect(throws: UpdatePackage.Failure.outside("Contents/out/evil")) { try UpdatePackage(decoding: data) }
    }

    @Test func refusesEveryTruncation() throws {
        try Self.inFolder { folder in
            let (old, new) = try Self.pair(in: folder)
            let data = try UpdatePackage.make(old: old, new: new, from: 1, to: 2)
            for length in stride(from: 0, to: 300, by: 5) {
                #expect(throws: UpdatePackage.Failure.self) { try UpdatePackage(decoding: data.prefix(length)) }
            }
        }
    }
}

extension Data {
    mutating func append(littleEndian value: Int) {
        Swift.withUnsafeBytes(of: Int64(value).littleEndian) { append(contentsOf: unsafe $0) }
    }
}
