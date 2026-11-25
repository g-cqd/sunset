import Foundation
import Testing

@testable import SunsetStorage

/// Compressed & optionally Keychain-sealed terminal snapshot store (`TerminalSnapshotStore`, S-1 / S-4) and launch
/// restore crash/policy evaluation (`LaunchRestoreDecision`, S-3).
@Suite("Terminal snapshot persistence & launch restore policy")
struct TerminalSnapshotStoreTests {
    @Test func `saves, loads, encrypts with Seal, rejects tampering, and prunes orphan snapshots`() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "sunset-snaps-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        let key = StorageKey.random()
        let store = TerminalSnapshotStore(directory: dir, key: key)
        let idA = UUID()
        let idB = UUID()
        let payload = Data(String(repeating: "scrollback line with repeated tokens\n", count: 200).utf8)

        // Sealed (encrypted) mode: file on disk starts with SNSL seal magic, 0600 permissions, round-trips cleanly.
        store.save(payload, for: idA, encrypted: true)
        let fileA = store.fileURL(for: idA)
        let rawA = try Data(contentsOf: fileA)
        #expect(Seal.isSealed(rawA))
        #expect(rawA.count < payload.count, "LZFSE compression should shrink repetitive scrollback")
        let perms = try FileManager.default.attributesOfItem(atPath: fileA.path)[.posixPermissions] as? Int
        #expect(perms == 0o600)
        #expect(store.load(for: idA) == payload)

        // Plain compressed mode (when storage.encryptTerminalHistory == false): still compressed, not sealed.
        store.save(payload, for: idB, encrypted: false)
        let rawB = try Data(contentsOf: store.fileURL(for: idB))
        #expect(!Seal.isSealed(rawB))
        #expect(store.load(for: idB) == payload)

        // Cross-pane substitution (moving A's sealed bytes to B's path) must fail AAD identity check.
        try rawA.write(to: store.fileURL(for: idB), options: .atomic)
        #expect(store.load(for: idB) == nil)

        // Pruning drops snapshots not in the keeping set.
        store.prune(keeping: [idA])
        #expect(FileManager.default.fileExists(atPath: fileA.path))
        #expect(!FileManager.default.fileExists(atPath: store.fileURL(for: idB).path))
    }

    @Test func `launch restore decision always asks after a crash and respects always/ask/never otherwise`() {
        #expect(
            LaunchRestoreDecision.evaluate(policy: "always", crashedLastRun: false, hasSavedSession: true)
                == .restoreNow
        )
        #expect(
            LaunchRestoreDecision.evaluate(policy: "ask", crashedLastRun: false, hasSavedSession: true)
                == .ask(afterCrash: false)
        )
        #expect(
            LaunchRestoreDecision.evaluate(policy: "never", crashedLastRun: false, hasSavedSession: true)
                == .startFresh
        )
        // Crash overrides even "always" and "never" when a saved session exists.
        #expect(
            LaunchRestoreDecision.evaluate(policy: "always", crashedLastRun: true, hasSavedSession: true)
                == .ask(afterCrash: true)
        )
        #expect(
            LaunchRestoreDecision.evaluate(policy: "always", crashedLastRun: true, hasSavedSession: false)
                == .startFresh
        )
    }
}
