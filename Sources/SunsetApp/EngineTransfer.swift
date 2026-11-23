import Foundation
import SunsetUpdate

/// The engine's download and checks (ADR-0124): staged beside the app by `UpdateInstaller` (its package from the installed
/// build when published, else its archive), then every framework checked against our team, notarized, and a later build.
enum EngineTransfer {
    static func stage(_ offer: UpdateOffer, place: EnginePlace, after build: Int) async throws {
        let installed = place.state == .off ? place.offFolder : place.engine
        let running = RunningBundle(
            bundle: installed,
            build: build,
            flavour: .engine,
            architecture: RunningApp.architecture
        )
        let installer = UpdateInstaller(fetch: UpdateTransfer.download) { staged in try check(staged, after: build) }
        try await installer.stage(offer, running: running, staging: place.staging)
    }

    /// Whether `engine` may be put in place.
    static func check(_ engine: URL, after build: Int) throws {
        guard let team = SignatureCheck.runningTeam() else { throw SignatureCheck.Failure.unreadable(0) }
        let requirement = "anchor apple generic and certificate leaf[subject.OU] = \"\(team)\" and notarized"
        try EngineCheck.check(engine, requirement: requirement, after: build)
    }
}
