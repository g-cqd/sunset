import Foundation
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetCredentials
@testable import SunsetStorage

/// Every open vault locks when the Mac sleeps, the screen locks, another user takes the Mac, Sunset quits or its last
/// window closes: the app reports the event once, to every lock it has (roadmap 0091 D).
@MainActor
@Suite("Every vault locks at once")
struct VaultLocksTests {
    @Test func `an event locks every open vault, with its reason; a vault let go of is not kept`() {
        let time = TestTime()
        let locks = VaultLocks()
        let one = VaultLock(idle: .seconds(300), runtime: time.runtime)
        let two = VaultLock(idle: .seconds(300), runtime: time.runtime)
        locks.add(one)
        locks.add(two)
        one.unlock(with: .random())
        two.unlock(with: .random())
        locks.lockAll(.sleep)
        #expect(one.isLocked && two.isLocked)
        #expect(one.lockedBecause == .sleep && two.lockedBecause == .sleep)
        weak var gone: VaultLock?
        do {
            let short = VaultLock(idle: .seconds(300), runtime: time.runtime)
            locks.add(short)
            gone = short
        }
        #expect(gone == nil, "the list does not keep a vault alive")
        #expect(locks.count == 2)
    }

    @Test func `the system's notifications, by name, are the reasons to lock`() {
        #expect(VaultLocks.reason(forNotificationNamed: "NSWorkspaceWillSleepNotification") == .sleep)
        #expect(VaultLocks.reason(forNotificationNamed: "NSWorkspaceScreensDidSleepNotification") == .sleep)
        #expect(VaultLocks.reason(forNotificationNamed: "com.apple.screenIsLocked") == .screenLocked)
        #expect(
            VaultLocks.reason(forNotificationNamed: "NSWorkspaceSessionDidResignActiveNotification") == .screenLocked
        )
        #expect(VaultLocks.reason(forNotificationNamed: "NSWorkspaceDidWakeNotification") == nil)
        #expect(VaultLocks.reason(forNotificationNamed: "com.apple.screenIsUnlocked") == nil)
    }
}
