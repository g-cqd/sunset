import Testing

@testable import SunsetStorage

/// Roadmap 0049: the session is written in the background; a write that comes late must not put an older session over a newer.
@Suite("Writes, the newest last")
struct NewestWritesTests {
    @Test func `a write asked before one already written is dropped; a failed write is not counted`() {
        let disk = NewestWrites()
        var file: [Int] = []
        let first = disk.next()
        let second = disk.next()
        #expect(
            disk.write(second) {
                file.append(2)
                return true
            }
        )
        #expect(
            disk.write(first) {
                file.append(1)
                return true
            },
            "the file holds a newer one"
        )
        #expect(file == [2])
        let third = disk.next()
        #expect(!disk.write(third) { false })
        #expect(
            disk.write(third) {
                file.append(3)
                return true
            },
            "tried again"
        )
        #expect(file == [2, 3])
    }
}
