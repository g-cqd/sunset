import Foundation
import SunsetUpdate

extension AppUpdates {
    /// Checks the notes of `releases` against their signed indexes (ADR-0125), once each: a failed signature, a missing
    /// index on a release that must have one, or a download that fails, all withhold the notes.
    func checkNotes(of releases: [PublishedRelease]) async {
        for release in releases where notesChecks[release.build] == nil {
            let index = try? await UpdateTransfer.verifiedIndex(for: release)
            let reached = index != nil || release.signedIndexAssets == nil
            notesChecks[release.build] =
                reached
                ? NotesCheck.of(notes: release.notes, index: index, build: release.build) : .mismatch
        }
    }
}
