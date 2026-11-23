import Foundation
import SunsetUpdate

/// The network and disk side of an update (roadmap 0122 D): GitHub's list, the package or the zip, the staging copy and
/// its checks. Nothing of the person is sent (an ephemeral session, no cookie).
enum UpdateTransfer {
    struct Failed: LocalizedError {
        let errorDescription: String?
    }

    static func releases() async throws -> [PublishedRelease] {
        guard let address = ReleaseFeed.address else { return [] }
        var request = URLRequest(url: address)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw Failed(errorDescription: "GitHub answered \((response as? HTTPURLResponse)?.statusCode ?? 0).")
        }
        return try ReleaseFeed.decode(data)
    }

    /// The update staged beside the app and checked (signature, team, notarization, a later build): the package from
    /// the running build when the release has one and it applies, else the full archive.
    static func stage(_ offer: UpdateOffer, running: RunningApp) async throws -> URL {
        let staging = running.staging
        try? FileManager.default.removeItem(at: staging)
        let package = offer.release.package(
            for: running.flavour,
            from: running.build,
            architecture: RunningApp.architecture
        )
        if let package, (try? await stagePackage(package, running: running, staging: staging)) != nil {
            try check(staging, running: running)
            return staging
        }
        try? FileManager.default.removeItem(at: staging)
        try await stageArchive(offer.archive, staging: staging)
        try check(staging, running: running)
        return staging
    }

    /// Whether `staging` may replace the running app; removes it when not.
    static func check(_ staging: URL, running: RunningApp) throws {
        do {
            guard let team = SignatureCheck.runningTeam() else { throw SignatureCheck.Failure.unreadable(0) }
            try SignatureCheck.check(
                bundle: staging,
                requirement: SignatureCheck.requirement(team: team, identifier: running.identifier)
            )
            try SignatureCheck.checkLater(bundle: staging, than: running.build)
        } catch {
            try? FileManager.default.removeItem(at: staging)
            throw Failed(errorDescription: "the downloaded app is not one Sunset can trust (\(error)).")
        }
    }

    private static func stagePackage(_ asset: ReleaseAsset, running: RunningApp, staging: URL) async throws {
        let file = try await download(asset)
        defer { try? FileManager.default.removeItem(at: file) }
        let package = try UpdatePackage(decoding: Data(contentsOf: file, options: .mappedIfSafe))
        try UpdateStaging.build(package, running: running.bundle, staging: staging)
    }

    /// The archive unzipped (`ditto`, as it was zipped) beside the app, its app moved to `staging`.
    private static func stageArchive(_ asset: ReleaseAsset, staging: URL) async throws {
        let file = try await download(asset)
        defer { try? FileManager.default.removeItem(at: file) }
        let folder = staging.deletingLastPathComponent().appending(path: ".sunset-update-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let ditto = Process()
        ditto.executableURL = URL(filePath: "/usr/bin/ditto")
        ditto.arguments = ["-x", "-k", file.path, folder.path]
        try ditto.run()
        ditto.waitUntilExit()
        let apps = try FileManager.default.contentsOfDirectory(atPath: folder.path).filter { $0.hasSuffix(".app") }
        guard ditto.terminationStatus == 0, apps.count == 1 else {
            throw Failed(errorDescription: "the archive did not hold one app.")
        }
        try FileManager.default.moveItem(at: folder.appending(path: apps[0]), to: staging)
    }

    /// An asset into the temporary folder.
    private static func download(_ asset: ReleaseAsset) async throws -> URL {
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (temporary, response) = try await session.download(from: asset.url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw Failed(errorDescription: "GitHub had no \(asset.name).")
        }
        let file = URL(filePath: NSTemporaryDirectory()).appending(path: "sunset-update-\(UUID().uuidString)")
        try FileManager.default.moveItem(at: temporary, to: file)
        return file
    }
}
