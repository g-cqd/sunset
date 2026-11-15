import Foundation
import Testing

@testable import SunsetStorage

/// Whether FileVault protects the disk, as the Mac says (`fdesetup isactive`): the volume's "encrypted" flag does not say
/// (diary 2026-11-15-01).
@Suite("FileVault's state") struct FileVaultStateTests {
    @Test func `the Mac's answer is read; anything else is not known`() {
        #expect(FileVaultState(answer: "true\n") == .on)
        #expect(FileVaultState(answer: "false\n") == .off)
        #expect(FileVaultState(answer: "") == .unknown)
        #expect(FileVaultState(answer: "fdesetup: command not found") == .unknown)
    }

    @Test func `the Mac is asked, and answers`() async {
        let state = await FileVaultState.read()
        #expect(state != .unknown, "fdesetup did not answer true or false")
    }

    @Test func `a program that is not there is not known, and does not hang`() async {
        #expect(await FileVaultState.read(tool: "/nowhere/fdesetup") == .unknown)
    }
}
