import Foundation
import SunsetUpdate

/// The network and disk side of an update or variant switch (ADR-0122, ADR-0125): GitHub's list, optional signed
/// `release-index.json`, the single range-addressed `.deltas` archive (falling back to legacy `.update` or full `.zip`),
/// staging, and Apple signature + notarization checks. Ephemeral sessions only; host-pinned to GitHub over HTTPS.
enum UpdateTransfer {
    struct Failed: LocalizedError {
        let errorDescription: String?
    }

    /// GitHub's list of Sunset's releases; `$SUNSET_UPDATES_FEED` names another list (a test's, on files).
    static func releases() async throws -> [PublishedRelease] {
        let named = ProcessInfo.processInfo.environment["SUNSET_UPDATES_FEED"].flatMap { URL(string: $0) }
        guard let address = named ?? ReleaseFeed.address else { return [] }
        let file = try await download(address)
        defer { try? FileManager.default.removeItem(at: file) }
        return try ReleaseFeed.decode(Data(contentsOf: file))
    }

    /// Downloads and verifies `release-index.json` + `.sig` when published with `release` (nil on older releases that
    /// predate ADR-0125). Throws if the index is present but fails Ed25519 verification.
    static func verifiedIndex(for release: PublishedRelease) async throws -> ReleaseIndex? {
        guard let pair = release.signedIndexAssets else { return nil }
        let indexFile = try await download(pair.index.url)
        defer { try? FileManager.default.removeItem(at: indexFile) }
        let sigFile = try await download(pair.signature.url)
        defer { try? FileManager.default.removeItem(at: sigFile) }
        let indexData = try Data(contentsOf: indexFile)
        let sigData = try Data(contentsOf: sigFile)
        return try ReleaseIndex.verify(data: indexData, signature: sigData)
    }

    /// Stages `offer` (for `targetFlavour`: either an update of the running flavour or a variant switch to the other)
    /// beside the running app and checks its Apple signature, team, identifier, notarization, and build order.
    static func stage(
        _ offer: UpdateOffer,
        running: RunningApp,
        targetFlavour: Flavour,
        onProgress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> URL {
        let staging = running.staging
        try? FileManager.default.removeItem(at: staging)
        let index = try await verifiedIndex(for: offer.release)
        let variant = index?.variant(for: targetFlavour, architecture: RunningApp.architecture)

        // 1. Try SSDLTA2 single-archive range download (ADR-0125)
        if let deltas = offer.release.deltasArchive(for: targetFlavour, architecture: RunningApp.architecture) {
            let ok =
                (try? await stageDeltas(
                    deltas: deltas,
                    expectedTOCSHA256: variant?.deltasTOCSHA256,
                    running: running,
                    staging: staging,
                    onProgress: onProgress
                )) != nil
            if ok {
                try check(staging, running: running, targetFlavour: targetFlavour)
                return staging
            }
            try? FileManager.default.removeItem(at: staging)
        }

        // 2. Fall back to legacy .update (when same flavour) or full .zip via UpdateInstaller
        let bundle = RunningBundle(
            bundle: running.bundle,
            build: running.build,
            flavour: targetFlavour,
            architecture: RunningApp.architecture
        )
        let expectedZipHash = variant?.archiveSHA256
        let installer = UpdateInstaller(
            fetch: { url in
                let file = try await download(url, onProgress: onProgress)
                if url == offer.archive.url, let expectedZipHash {
                    let actual = BundleManifest.hex(try Data(contentsOf: file, options: .mappedIfSafe))
                    guard actual == expectedZipHash else {
                        try? FileManager.default.removeItem(at: file)
                        throw Failed(
                            errorDescription: "downloaded archive hash did not match the signed release index."
                        )
                    }
                }
                return file
            },
            trust: { staged in try check(staged, running: running, targetFlavour: targetFlavour) }
        )
        try await installer.stage(offer, running: bundle, staging: staging)
        return staging
    }

    /// Two-request SSDLTA2 range fetch: 64 KiB prefix (header + TOC) -> local preflight -> single contiguous payload
    /// range with `If-Match: <ETag>` -> bounded staging.
    private static func stageDeltas(
        deltas: ReleaseAsset,
        expectedTOCSHA256: String?,
        running: RunningApp,
        staging: URL,
        onProgress: (@Sendable (Double) -> Void)?
    ) async throws {
        let initial = try await fetchRange(url: deltas.url, start: 0, length: 65_536)
        let header = try DeltaArchive.Header.decode(initial.data)
        if let expectedTOCSHA256, header.tocSHA256 != expectedTOCSHA256 {
            throw DeltaArchive.Failure.hashMismatch
        }
        let tocEnd = DeltaArchive.Header.size + header.tocLength
        let tocBytes: Data
        if initial.data.count >= tocEnd {
            tocBytes = Data(initial.data[DeltaArchive.Header.size ..< tocEnd])
        } else {
            let rest = try await fetchRange(
                url: initial.resolvedURL,
                start: initial.data.count,
                length: tocEnd - initial.data.count,
                expectedETag: initial.etag
            )
            tocBytes = Data(initial.data[DeltaArchive.Header.size...]) + rest.data
        }
        let toc = try DeltaArchive.decodeTOC(tocBytes, expectedSHA256: header.tocSHA256)
        let sourceKey = running.flavour.sourceKey(build: running.build)
        guard let plan = toc.sources[sourceKey] else { throw DeltaArchive.Failure.missingSource(sourceKey) }
        guard try DeltaArchive.preflight(plan: plan, running: running.bundle) else {
            throw DeltaArchive.Failure.hashMismatch
        }
        let payload = try await fetchRange(
            url: initial.resolvedURL,
            start: tocEnd + plan.rangeOffset,
            length: plan.rangeLength,
            expectedETag: initial.etag
        ) { received, total in
            guard total > 0 else { return }
            onProgress?(min(1.0, Double(received) / Double(total)))
        }
        try DeltaArchive.stage(
            toc: toc,
            plan: plan,
            payload: payload.data,
            running: running.bundle,
            staging: staging
        )
    }

    /// Whether `staging` may replace the running app: Developer ID + team + identifier + notarized + build order
    /// (allowing equal build strictly when switching engine variant, ADR-0125).
    static func check(_ staging: URL, running: RunningApp, targetFlavour: Flavour) throws {
        do {
            guard let team = SignatureCheck.runningTeam() else { throw SignatureCheck.Failure.unreadable(0) }
            try SignatureCheck.check(
                bundle: staging,
                requirement: SignatureCheck.requirement(team: team, identifier: running.identifier)
            )
            try SignatureCheck.checkLater(
                bundle: staging,
                than: running.build,
                allowingEqual: targetFlavour != running.flavour
            )
        } catch {
            throw Failed(errorDescription: error.localizedDescription)
        }
    }

    @Sendable
    static func download(_ address: URL, onProgress: (@Sendable (Double) -> Void)? = nil) async throws -> URL {
        let file = URL(filePath: NSTemporaryDirectory()).appending(path: "sunset-update-\(UUID().uuidString)")
        if address.isFileURL {
            guard allowsLocalFeed else { throw Failed(errorDescription: "local update address is not allowed.") }
            try FileManager.default.copyItem(at: address, to: file)
            onProgress?(1.0)
            return file
        }
        try enforcePolicy(address)
        let delegate = RangeDownloadDelegate { received, total in
            if total > 0 { onProgress?(min(1.0, Double(received) / Double(total))) }
        }
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let (temporary, response) = try await session.download(from: address, delegate: delegate)
        let http = response as? HTTPURLResponse
        guard let http, http.statusCode == 200 else {
            throw Failed(errorDescription: "GitHub answered \(http?.statusCode ?? 0) for \(address.lastPathComponent).")
        }
        if let finalURL = http.url { try enforcePolicy(finalURL) }
        try FileManager.default.moveItem(at: temporary, to: file)
        onProgress?(1.0)
        return file
    }
}
