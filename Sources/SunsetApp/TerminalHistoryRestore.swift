import AppKit
import Foundation
import SunsetAppCore
import SunsetConfig
import SunsetCore
import SunsetPane
import SunsetRuntime
import SunsetShell
import SunsetShellModel
import SunsetStorage
import SunsetTerminalModel

/// Coordinates saving and replaying terminal screen & scrollback snapshots, clean-shutdown crash detection (`session.running`),
/// and launch restore confirmation (roadmap 0024 S-1..S-4 / t190, t213–t215).
@MainActor
enum TerminalHistoryRestore {
    /// Checks whether the previous Sunset run exited cleanly (`session.running` absent), plants the marker for this run,
    /// and resolves `tabs.restore` + `tabs.restorePolicy` into whether the saved session should be reopened.
    /// After a crash, or when `tabs.restorePolicy == .ask`, asks the person synchronously via `NSAlert` before windows open.
    static func decideAtLaunch(
        places: StoragePlaces,
        configuration: Configuration,
        hasSavedSession: Bool
    ) -> Bool {
        let fm = FileManager.default
        let markerPath = places.runningMarker
        let crashed = fm.fileExists(atPath: markerPath)
        plantRunningMarker(at: markerPath)

        guard configuration.tabs.restore else { return false }
        let decision = LaunchRestoreDecision.evaluate(
            policy: configuration.tabs.restorePolicy.rawValue,
            crashedLastRun: crashed,
            hasSavedSession: hasSavedSession
        )
        switch decision {
            case .restoreNow:
                return true
            case .startFresh:
                return false
            case .ask(let afterCrash):
                return promptForRestore(afterCrash: afterCrash)
        }
    }

    /// Removes the `session.running` sentinel on clean shutdown so the next launch knows Sunset did not crash.
    static func markCleanShutdown(places: StoragePlaces = SunsetStore.shared.places) {
        try? FileManager.default.removeItem(atPath: places.runningMarker)
    }

    /// Snapshots every live non-private `TerminalModel` across all Spaces and Favorites, saving compressed (and
    /// optionally Keychain-sealed) snapshots on disk and pruning orphans (S-1, S-4).
    static func saveAllLiveTerminals(at now: Date = Runtime.live.now()) {
        let config = AppConfiguration.shared.configuration
        let store = SunsetStore.shared.terminalSnapshots
        guard config.tabs.restore, config.tabs.restoreTerminalHistory else {
            store.removeAll()
            return
        }
        let encrypted = config.storage.encryptTerminalHistory
        var activeIDs: Set<UUID> = []
        let models = allNonPrivateTerminals()
        let encoder = JSONEncoder()
        for model in models {
            activeIDs.insert(model.snapshotID)
            guard let snap = model.captureSnapshot(at: now),
                let data = try? encoder.encode(snap)
            else { continue }
            store.save(data, for: model.snapshotID, encrypted: encrypted)
        }
        // Keep snapshots referenced by unloaded pending descriptors too so unloaded tabs keep their history.
        for id in pendingSnapshotIDs() { activeIDs.insert(id) }
        store.prune(keeping: activeIDs)
    }

    /// Snapshots one window's non-private terminals right before its last window closes (so `closeWithLastWindow == false`
    /// keeps their scrollback for the next window or launch).
    static func saveTerminals(in tabs: TabsModel, at now: Date = Runtime.live.now()) {
        let config = AppConfiguration.shared.configuration
        guard !tabs.isPrivateWindow, config.tabs.restore, config.tabs.restoreTerminalHistory else { return }
        let store = SunsetStore.shared.terminalSnapshots
        let encrypted = config.storage.encryptTerminalHistory
        let encoder = JSONEncoder()
        for content in tabs.space.contents.values {
            guard let model = content as? TerminalModel, !model.isPrivate,
                let snap = model.captureSnapshot(at: now),
                let data = try? encoder.encode(snap)
            else { continue }
            store.save(data, for: model.snapshotID, encrypted: encrypted)
        }
    }

    /// Loads any saved snapshot referenced by `descriptor` and returns replay bytes (`old lines + divider`) when
    /// `tabs.restoreTerminalHistory` is enabled.
    static func loadReplayBytes(for descriptor: PaneDescriptor?) -> (snapshotID: UUID, replay: [UInt8]) {
        guard let rawID = descriptor?.state["snapshot"], let id = UUID(uuidString: rawID) else {
            return (UUID(), [])
        }
        guard AppConfiguration.shared.configuration.tabs.restoreTerminalHistory,
            let data = SunsetStore.shared.terminalSnapshots.load(for: id),
            let snap = try? JSONDecoder().decode(ScreenSnapshot.self, from: data),
            snap.version == ScreenSnapshot.currentVersion
        else { return (id, []) }
        return (id, snap.replayBytes())
    }

    private static func plantRunningMarker(at path: String) {
        let fm = FileManager.default
        let dir = (path as NSString).deletingLastPathComponent
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        fm.createFile(atPath: path, contents: Data("1\n".utf8), attributes: [.posixPermissions: 0o600])
    }

    private static func promptForRestore(afterCrash: Bool) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = afterCrash ? .warning : .informational
        alert.messageText = afterCrash ? "Sunset quit unexpectedly last time" : "Restore your previous session?"
        alert.informativeText =
            afterCrash
            ? "Restore your previous tabs and terminal scrollback, or start fresh?"
            : "Bring back your open tabs and saved terminal scrollback from the last session?"
        alert.addButton(withTitle: "Restore Session")
        alert.addButton(withTitle: "Start Fresh")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static func allNonPrivateTerminals() -> [TerminalModel] {
        var found: [TerminalModel] = []
        var seen: Set<ObjectIdentifier> = []
        for space in AppSpaces.all.spaces {
            for content in space.contents.values {
                guard let model = content as? TerminalModel, !model.isPrivate,
                    seen.insert(ObjectIdentifier(model)).inserted
                else { continue }
                found.append(model)
            }
            for content in space.favorites.contents.values {
                guard let model = content as? TerminalModel, !model.isPrivate,
                    seen.insert(ObjectIdentifier(model)).inserted
                else { continue }
                found.append(model)
            }
        }
        return found
    }

    private static func pendingSnapshotIDs() -> Set<UUID> {
        var ids: Set<UUID> = []
        for space in AppSpaces.all.spaces {
            for desc in space.pending.values {
                if let raw = desc.state["snapshot"], let id = UUID(uuidString: raw) { ids.insert(id) }
            }
        }
        return ids
    }
}
