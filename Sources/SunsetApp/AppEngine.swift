import Foundation
import Observation
import SunsetAppCore
import SunsetConfig
import SunsetUpdate

/// The WebKit engine as a component of the native app (roadmap 0113, ADR-0124; the owner: use it or the system's, delete
/// it, update it automatically or by hand). What the person asks is made as Sunset quits (`applyAtQuit`), since the
/// frameworks in use cannot change under it, and takes effect when it opens again.
@MainActor @Observable
final class AppEngine {
    static let shared = AppEngine()

    enum Phase: Equatable {
        case idle
        case downloading
        case failed(String)
    }

    let place: EnginePlace
    /// What this process runs on, from its images at launch.
    let runningOn: EngineFolder.Running
    /// Whether this copy can have an engine beside it: the native build, where it may write.
    let available: Bool
    private(set) var phase = Phase.idle
    /// The latest engine published, when later than the one installed (or none installed).
    private(set) var offer: UpdateOffer?
    /// An engine downloaded and checked, put in place at quit.
    private(set) var staged: EngineManifest?
    /// Use the engine (true) or the system's (false) from the next start; nil: as it is.
    var wantsEngine: Bool?
    /// Delete the engine at quit.
    var removing = false

    private init() {
        let app = Bundle.main.bundleURL
        place = EnginePlace(beside: app)
        runningOn = EngineFolder.running(images: EngineImages.loaded(), engine: EngineFolder.frameworks(app: app.path))
        available = RunningApp.current.flavour == .native && AppUpdates.shared.refusal == nil
    }

    /// The installed engine, on or off.
    var installed: EngineManifest? {
        place.installed
    }

    /// Whether a change waits for Sunset to start again.
    var changesAtRestart: Bool {
        staged != nil || removing || (wantsEngine != nil && wantsEngine != (place.state == .on))
    }

    /// The latest engine in `releases`; downloaded at once when `automatic` and one is installed (a first one is asked for).
    func consider(_ releases: [PublishedRelease], automatic: Bool, prereleases: Bool) async {
        guard available else { return }
        offer = UpdateChoice.offer(
            in: releases,
            flavour: .engine,
            architecture: RunningApp.architecture,
            running: max(installed?.build ?? 0, staged?.build ?? 0),
            prereleases: prereleases
        )
        if automatic, installed != nil, !removing, offer != nil { await download() }
    }

    /// Downloads the offered engine, stages it beside the app and checks it whole.
    func download() async {
        guard available, let offer, phase != .downloading else { return }
        phase = .downloading
        do {
            try await EngineTransfer.stage(offer, place: place, after: installed?.build ?? 0)
            staged = EngineManifest.read(from: place.staging)
            removing = false
            if installed == nil { wantsEngine = true }
            self.offer = nil
            phase = .idle
        } catch {
            phase = .failed("The engine was not downloaded: \(error.localizedDescription)")
        }
    }

    /// Delete it at quit (and what is staged); undone by downloading again.
    func remove() {
        removing = true
        wantsEngine = nil
        if staged != nil { try? FileManager.default.removeItem(at: place.staging) }
        staged = nil
    }
}
