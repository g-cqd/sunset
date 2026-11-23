import Foundation
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetCredentials
@testable import SunsetStorage

/// The idle time is a setting (the owner, 2026-11-23): changed while unlocked, it counts from the last use; none, it never
/// locks by itself.
@MainActor
@Suite("A vault's idle time, set")
struct VaultLockIdleSettingTests {
    @Test func `shortened, it locks after the new time; none, it does not lock by itself`() async throws {
        let time = TestTime()
        let lock = VaultLock(idle: .seconds(600), runtime: time.runtime)
        var mark = time.mark()
        lock.unlock(with: StorageKey.random())
        try await time.waited(since: mark)
        mark = time.mark()
        lock.idle = .seconds(60)
        try await time.waited(since: mark)
        try await time.passToEnd(.seconds(60))
        #expect(lock.isLocked && lock.lockedBecause == .idle)
        lock.idle = nil
        lock.unlock(with: StorageKey.random())
        try await time.pass(.seconds(24 * 3600))
        #expect(!lock.isLocked)
    }
}
