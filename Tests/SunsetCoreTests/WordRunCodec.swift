@testable import SunsetCore

/// A small codec for tests: runs of equal 8-byte words as (word, run length) pairs. It shrinks lines of one repeated cell and cannot shrink varied ones.
struct WordRunCodec: HistoryCodec {
    func pack(_ bytes: UnsafeRawBufferPointer) -> [UInt8]? {
        let words = bytes.count / 8
        var out: [UInt8] = []
        var index = 0
        while index < words {
            let word = unsafe bytes.loadUnaligned(fromByteOffset: index * 8, as: UInt64.self)
            var run = 1
            while index + run < words,
                unsafe bytes.loadUnaligned(fromByteOffset: (index + run) * 8, as: UInt64.self) == word
            { run += 1 }
            withUnsafeBytes(of: word) { out.append(contentsOf: $0) }
            withUnsafeBytes(of: UInt32(run)) { out.append(contentsOf: $0) }
            index += run
        }
        return out.count < bytes.count ? out : nil
    }

    func unpack(_ packed: [UInt8], into output: UnsafeMutableRawBufferPointer) -> Bool {
        var offset = 0
        var at = 0
        while at + 12 <= packed.count {
            let word = packed.withUnsafeBytes { unsafe $0.loadUnaligned(fromByteOffset: at, as: UInt64.self) }
            let run = packed.withUnsafeBytes { unsafe $0.loadUnaligned(fromByteOffset: at + 8, as: UInt32.self) }
            for _ in 0 ..< Int(run) {
                guard offset + 8 <= output.count else { return false }
                unsafe output.storeBytes(of: word, toByteOffset: offset, as: UInt64.self)
                offset += 8
            }
            at += 12
        }
        return offset == output.count
    }
}
