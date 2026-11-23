import Foundation
import SunsetUpdate

/// The network and disk side of an update (roadmap 0122 D): GitHub's list, the package or the zip, the staging copy and
/// its checks. Nothing of the person is sent (an ephemeral session, no cookie).
enum UpdateTransfer {
    struct Failed: LocalizedError {
        let errorDescription: String?
    }

    /// GitHub's list of Sunset's releases; `$SUNSET_UPDATES_FEED` names another list (a test's, on files: the assets it
    /// names are trusted no more than GitHub's, ADR-0122).
    static func releases() async throws -> [PublishedRelease] {
        let named = ProcessInfo.processInfo.environment["SUNSET_UPDATES_FEED"].flatMap { URL(string: $0) }
        guard let address = named ?? ReleaseFeed.address else { return [] }
        let file = try await download(address)
        defer { try? FileManager.default.removeItem(at: file) }
        return try ReleaseFeed.decode(Data(contentsOf: file))
    }

    /// The update staged beside the app and checked (signature, team, notarization, a later build): the package from
    /// the running build when the release has one and it applies, else the full archive (`UpdateInstaller`).
    static func stage(_ offer: UpdateOffer, running: RunningApp) async throws -> URL {
        let bundle = RunningBundle(
            bundle: running.bundle,
            build: running.build,
            flavour: running.flavour,
            architecture: RunningApp.architecture
        )
        let installer = UpdateInstaller(fetch: download) { staging in try check(staging, running: running) }
        try await installer.stage(offer, running: bundle, staging: running.staging)
        return running.staging
    }

    /// Whether `staging` may replace the running app.
    static func check(_ staging: URL, running: RunningApp) throws {
        do {
            guard let team = SignatureCheck.runningTeam() else { throw SignatureCheck.Failure.unreadable(0) }
            try SignatureCheck.check(
                bundle: staging,
                requirement: SignatureCheck.requirement(team: team, identifier: running.identifier)
            )
            try SignatureCheck.checkLater(bundle: staging, than: running.build)
        } catch {
            throw Failed(errorDescription: "the downloaded app is not one Sunset can trust (\(error)).")
        }
    }

    /// An asset into the temporary folder.
    @Sendable
    private static func download(_ address: URL) async throws -> URL {
        let file = URL(filePath: NSTemporaryDirectory()).appending(path: "sunset-update-\(UUID().uuidString)")
        if address.isFileURL {
            try FileManager.default.copyItem(at: address, to: file)
            return file
        }
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (temporary, response) = try await session.download(from: address)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw Failed(errorDescription: "GitHub answered \(status) for \(address.lastPathComponent).")
        }
        try FileManager.default.moveItem(at: temporary, to: file)
        return file
    }
}
