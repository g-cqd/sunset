import Foundation
import SunsetTestSupport
import Testing

@testable import SunsetCredentials

/// The cost a vault file names for its password is read from the file, which anyone who can write it can change: a cost past
/// what Sunset makes is refused before any work (a raised one would hang or exhaust memory; a lowered one opens nothing,
/// since it stretches to another key). The outside audit's HIGH-02, 2026-11-22.
@Suite("Master password: the cost a file names") struct MasterPasswordCostTests {
    @Test(arguments: [
        MasterPassword.Cost(memoryKiB: 64, passes: 100_000, lanes: 1),
        MasterPassword.Cost(memoryKiB: 1 << 32, passes: 1, lanes: 1),
        MasterPassword.Cost(memoryKiB: 64, passes: 1, lanes: 1_000),
        MasterPassword.Cost(memoryKiB: 64, passes: 0, lanes: 1)
    ])
    func `a cost past what Sunset makes is refused at once`(cost: MasterPassword.Cost) {
        let spent = Stopwatch.time {
            #expect(throws: MasterPassword.CostRefused.self) {
                try MasterPassword.stretch("password", salt: Data(repeating: 1, count: 16), cost: cost)
            }
        }
        #expect(spent < .seconds(1))
    }

    @Test func `Sunset's own cost and a test's are within it`() {
        #expect(MasterPassword.Cost.standard.isWithinBounds)
        #expect(MasterPassword.Cost(memoryKiB: 64, passes: 1, lanes: 1).isWithinBounds)
    }
}
