import AppKit
import Foundation
import Observation
import SunsetAppCore
import SunsetConfig
import SunsetRuntime
import SunsetUpdate

/// Sunset updating itself from its GitHub releases (roadmap 0122, ADR-0122, n135): it checks at launch and every few
/// hours; with `updates.automatic` it downloads and checks the update on its own and puts it in place when Sunset quits;
/// either way it tells once for each new build, with the notes between the two (`UpdateWindow`). The update centre
/// (Settings, General, Updates) shows where it is.
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

    /// Downloads, stages and checks `offer`; `ready` once it can be put in place.
    func download(_ offer: UpdateOffer) async {
        guard refusal == nil else { return }
        phase = .downloading(offer)
        do {
            staging = try await UpdateTransfer.stage(offer, running: running)
            phase = .ready(offer)
        } catch {
            phase = .failed(
                "The update to build \(offer.release.build) was not installed: \(error.localizedDescription)"
            )
        }
    }

    /// The dialog, once for each build (asked for: always).
    private func tellOnce(_ offer: UpdateOffer, manual: Bool) {
        guard manual || UserDefaults.standard.integer(forKey: told) != offer.release.build else { return }
        UserDefaults.standard.set(offer.release.build, forKey: told)
        UpdateWindow.show(offer)
    }
}
