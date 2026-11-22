import Foundation
import Testing

@testable import SunsetCredentials

/// ADR-0091: "secrets live in locked, zeroed buffers": kept out of swap while held, zeroed when let go.
@Suite("A secret's buffer")
struct SecretBufferTests {
    @Test func `it holds the bytes, pinned in memory; wiped, it holds nothing and its memory is zero`() {
        let secret = Data((0 ..< 32).map { UInt8($0 + 1) })
        let buffer = SecretBuffer(secret)
        #expect(buffer.isPinned)
        #expect(buffer.withBytes { Data($0) } == secret)
        var seen: [UInt8] = []
        buffer.wipe(observing: { seen = Array($0) })
        #expect(seen == [UInt8](repeating: 0, count: 32), "zero before it is given back")
        #expect(buffer.withBytes { Data($0) } == nil)
        buffer.wipe(observing: { _ in })
    }
}
