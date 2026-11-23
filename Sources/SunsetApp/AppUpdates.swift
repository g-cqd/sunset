import AppKit
import Foundation
import Observation
import SunsetAppCore
import SunsetConfig
import SunsetRuntime
import SunsetUpdate

/// Sunset updating itself — and switching between System WebKit and Sunset's WebKit — from its GitHub releases
/// (ADR-0122, ADR-0125): checks at launch and every few hours; with `updates.automatic` it downloads and checks updates
/// on its own and swaps them in on quit; either way it notifies once per build with the release notes between versions.
@MainActor @Observable
final class AppUpdates {
    static let shared = AppUpdates()

    enum Phase: Equatable {
        case idle
        case checking
        case upToDate
        case found(UpdateOffer)
        case downloading(UpdateOffer)
        /// Downloaded, staged and checked: put in place when Sunset quits.
        case ready(UpdateOffer)
        case failed(String)
    }

    private(set) var phase = Phase.idle
    /// Fraction downloaded during `.downloading` (0...1), nil when unknown.
    private(set) var downloadProgress: Double?
    /// The flavour staged in `staging` (equals `running.flavour` for a normal update, the other for an engine switch).
    private(set) var stagedFlavour: Flavour?
    /// Latest releases read from the feed (used to offer switching between System WebKit and Sunset's WebKit).
    private(set) var latestReleases: [PublishedRelease] = []
    private(set) var checked: Date?
    /// Why this copy cannot update itself; nil when it can.
    let refusal: UpdatePlace.Refusal?
    let running = RunningApp.current
    /// Restart once the update is in place (Restart to Update), rather than only quit.
    @ObservationIgnored var restartsAfterInstall = false
    @ObservationIgnored var staging: URL?
    @ObservationIgnored private var schedule: Task<Void, Never>?
    @ObservationIgnored private let told = "updatesToldForBuild"

    static let interval = Duration.seconds(6 * 3600)

    private init() {
        refusal = UpdatePlace.refusal(
            path: running.bundle.path,
            team: SignatureCheck.runningTeam(),
            writable: FileManager.default.isWritableFile(atPath: running.bundle.deletingLastPathComponent().path)
                && FileManager.default.isWritableFile(atPath: running.bundle.path)
        )
    }

    var settings: (automatic: Bool, prereleases: Bool) {
        let updates = AppConfiguration.shared.configuration.updates
        return (updates.automatic, updates.prereleases)
    }

    /// The other engine variant (Native <-> WebKit) offered for switching at the current or newer build.
    var otherEngineOffer: UpdateOffer? {
        let other: Flavour = running.flavour == .native ? .webKit : .native
        return UpdateChoice.offer(
            in: latestReleases,
            flavour: other,
            architecture: RunningApp.architecture,
            running: running.build,
            prereleases: settings.prereleases,
            allowingEqual: true
        )
    }

    /// At launch: a first check soon, then every `interval`. A copy that cannot update itself does not check on its own.
    static func start() {
        let updates = shared
        guard updates.refusal == nil, updates.schedule == nil else { return }
        updates.schedule = Runtime.live.task(role: .observation) { [weak updates] in
            guard await Runtime.live.sleep(for: .seconds(20)) else { return }
            while true {
                await updates?.check(manual: false)
                guard await Runtime.live.sleep(for: interval) else { return }
            }
        }
    }

    /// Reads the releases and decides: nothing, an offer, or (automatic) the download.
    func check(manual: Bool) async {
        switch phase {
            case .checking, .downloading, .ready: return
            default: break
        }
        phase = .checking
        do {
            let releases = try await UpdateTransfer.releases()
            latestReleases = releases
            checked = Runtime.live.now()
            guard
                let offer = UpdateChoice.offer(
                    in: releases,
                    flavour: running.flavour,
                    architecture: RunningApp.architecture,
                    running: running.build,
                    prereleases: settings.prereleases
                )
            else {
                phase = .upToDate
                return
            }
            phase = .found(offer)
            if settings.automatic && refusal == nil { await download(offer) }
            tellOnce(offer, manual: manual)
        } catch {
            phase = .failed("Could not read Sunset\u{2019}s releases: \(error.localizedDescription)")
        }
    }

    /// Downloads, stages and checks `offer` for `flavour` (default: the running flavour); `ready` once it can swap in.
    func download(_ offer: UpdateOffer, flavour: Flavour? = nil) async {
        guard refusal == nil else { return }
        let target = flavour ?? running.flavour
        phase = .downloading(offer)
        downloadProgress = 0
        do {
            staging = try await UpdateTransfer.stage(offer, running: running, targetFlavour: target) { fraction in
                Runtime.live.task { @MainActor in AppUpdates.shared.downloadProgress = fraction }
            }
            stagedFlavour = target
            downloadProgress = nil
            phase = .ready(offer)
        } catch {
            downloadProgress = nil
            phase = .failed(
                "The update to build \(offer.release.build) was not installed: \(error.localizedDescription)"
            )
        }
    }

    /// Switches to the other engine variant (System WebKit <-> Sunset's WebKit) by downloading it from the latest
    /// release and staging it for restart (ADR-0125).
    func switchEngine() async {
        guard refusal == nil else { return }
        if latestReleases.isEmpty { await check(manual: false) }
        guard let offer = otherEngineOffer else {
            phase = .failed("No release found for the other web engine.")
            return
        }
        let target: Flavour = running.flavour == .native ? .webKit : .native
        await download(offer, flavour: target)
    }

    /// The dialog, once for each build (asked for: always).
    private func tellOnce(_ offer: UpdateOffer, manual: Bool) {
        guard manual || UserDefaults.standard.integer(forKey: told) != offer.release.build else { return }
        UserDefaults.standard.set(offer.release.build, forKey: told)
        UpdateWindow.show(offer)
    }
}
