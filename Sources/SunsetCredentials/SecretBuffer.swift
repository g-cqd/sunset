import Foundation

/// A secret's bytes in memory of their own (ADR-0091: "secrets live in locked, zeroed buffers"): pinned (`mlock`) so that
/// they are not written to swap, zeroed (`memset_s`, which the compiler may not leave out) before the memory is given back.
/// Copies made from it (a key handed to CryptoKit) are the caller's, for as long as its closure runs.
final class SecretBuffer {
    /// The bytes, and the whole allocation they are in (at least a byte), for zeroing and giving back.
    private var memory: UnsafeMutableRawBufferPointer?
    private var base: UnsafeMutableRawBufferPointer?
    /// Whether the system pinned it; false where `mlock` was refused (the bytes are still zeroed).
    private(set) var isPinned = false

    init(_ bytes: Data) {
        let memory = UnsafeMutableRawBufferPointer.allocate(byteCount: max(bytes.count, 1), alignment: 16)
        isPinned = mlock(memory.baseAddress, memory.count) == 0
        bytes.copyBytes(to: memory)
        self.memory = UnsafeMutableRawBufferPointer(rebasing: memory[0 ..< bytes.count])
        base = memory
    }

    /// `body` with the bytes; nil once wiped.
    func withBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R? {
        guard let memory else { return nil }
        return try body(UnsafeRawBufferPointer(memory))
    }

    /// Zeroes the bytes and gives the memory back; `observing` sees them zeroed (tests). Again, nothing.
    func wipe(observing: (UnsafeRawBufferPointer) -> Void = { _ in }) {
        guard let base, let memory else { return }
        _ = memset_s(base.baseAddress, base.count, 0, base.count)
        observing(UnsafeRawBufferPointer(memory))
        if isPinned { munlock(base.baseAddress, base.count) }
        base.deallocate()
        self.base = nil
        self.memory = nil
    }

    deinit {
        wipe()
    }
}
