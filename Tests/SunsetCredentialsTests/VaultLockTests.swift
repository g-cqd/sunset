import Foundation
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetCredentials
@testable import SunsetStorage

/// Locked means the vault key is gone. It locks after an idle time (on the Runtime's clock), at quit, when the Mac
/// sleeps or the screen locks, when the last window using it closes, and by hand.
@MainActor
@Suite("A vault's lock")
struct VaultLockTests {
    private let idle = Duration.seconds(300)

    @Test func `unlocked, its key is there; each use puts the idle lock off; left alone, it locks`() async throws {
        let time = TestTime()
        let lock = VaultLock(idle: idle, runtime: time.runtime)
        let key = StorageKey.random()
        #expect(lock.withKey { $0.bytes } == nil, "locked at first")
        let mark = time.mark()
        lock.unlock(with: key)
        try await time.waited(since: mark)
        time.advance(idle / 2)
        #expect(lock.withKey { $0.bytes } == key.bytes)
        try await time.passStillWaiting(idle / 2)
        #expect(!lock.isLocked, "used half way: not idle yet")
        try await time.passToEnd(idle / 2)
        #expect(lock.isLocked && lock.lockedBecause == .idle)
        #expect(lock.withKey { $0.bytes } == nil)
    }

    @Test(arguments: [VaultLock.Reason.quit, .sleep, .screenLocked, .lastWindowClosed, .byHand])
    func `it locks at once, for every reason`(reason: VaultLock.Reason) async throws {
        let time = TestTime()
        let lock = VaultLock(idle: idle, runtime: time.runtime)
        lock.unlock(with: StorageKey.random())
        lock.lock(reason)
        #expect(lock.isLocked && lock.lockedBecause == reason)
        #expect(lock.withKey { $0.bytes } == nil)
        try await time.passToEnd(idle)
    }
}
