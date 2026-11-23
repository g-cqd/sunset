public import Foundation

/// An offer staged beside the running app and checked (roadmap 0122 D, ADR-0122): the package from the running build
/// when the release has one and it applies, else the full archive; then `trust` (the signature check, in the app) on the
/// staged copy, which is removed when refused. `fetch` downloads an asset to a file of its own (the app's: an ephemeral
/// session), which the installer removes after.
public struct UpdateInstaller: Sendable {
    public let fetch: @Sendable (URL) async throws -> URL
    public let trust: @Sendable (URL) throws -> Void

    public init(fetch: @escaping @Sendable (URL) async throws -> URL, trust: @escaping @Sendable (URL) throws -> Void) {
        self.fetch = fetch
        self.trust = trust
    }

    /// Stages `offer` at `staging` (removed first when there).
    public func stage(_ offer: UpdateOffer, running: RunningBundle, staging: URL) async throws {
        try? FileManager.default.removeItem(at: staging)
        let package = offer.release.package(
            for: running.flavour,
            from: running.build,
            architecture: running.architecture
        )
        var staged = false
        if let package {
            staged = (try? await stagePackage(package, running: running.bundle, staging: staging)) != nil
        }
        if !staged {
            try? FileManager.default.removeItem(at: staging)
            try await stageArchive(offer.archive, staging: staging)
        }
        do {
            try trust(staging)
        } catch {
            try? FileManager.default.removeItem(at: staging)
            throw error
        }
    }

    private func stagePackage(_ asset: ReleaseAsset, running: URL, staging: URL) async throws {
        let file = try await fetch(asset.url)
        defer { try? FileManager.default.removeItem(at: file) }
        let package = try UpdatePackage(decoding: Data(contentsOf: file, options: .mappedIfSafe))
        try UpdateStaging.build(package, running: running, staging: staging)
    }

    /// The archive unzipped (`ditto`, as it was zipped) beside the app, its one app moved to `staging`.
    private func stageArchive(_ asset: ReleaseAsset, staging: URL) async throws {
        let file = try await fetch(asset.url)
        defer { try? FileManager.default.removeItem(at: file) }
        let folder = staging.deletingLastPathComponent().appending(path: ".sunset-update-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let ditto = Process()
        ditto.executableURL = URL(filePath: "/usr/bin/ditto")
        ditto.arguments = ["-x", "-k", file.path, folder.path]
        try ditto.run()
        ditto.waitUntilExit()
        let apps = (try? FileManager.default.contentsOfDirectory(atPath: folder.path))?.filter { $0.hasSuffix(".app") }
        guard ditto.terminationStatus == 0, let apps, apps.count == 1 else { throw Failure.noApp }
        try FileManager.default.moveItem(at: folder.appending(path: apps[0]), to: staging)
    }

    public enum Failure: Error, Equatable {
        /// The archive did not hold one app.
        case noApp
    }
}
