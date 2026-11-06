internal import Darwin

/// A pipe used as a wake-up signal for a thread that waits on a poll or a kqueue with no timeout: `poke` makes the read end readable. Both ends are
/// non-blocking and close-on-exec; -1 when the pipe could not be made.
struct WakePipe: Sendable {
    let readEnd: Int32
    let writeEnd: Int32

    init() {
        var ends: [Int32] = [-1, -1]
        if pipe(&ends) == 0 {
            for end in ends {
                _ = fcntl(end, F_SETFL, fcntl(end, F_GETFL) | O_NONBLOCK)
                _ = fcntl(end, F_SETFD, FD_CLOEXEC)
            }
        } else {
            ends = [-1, -1]
        }
        (readEnd, writeEnd) = (ends[0], ends[1])
    }

    func poke() {
        guard writeEnd >= 0 else { return }
        var byte: UInt8 = 1
        _ = unsafe write(writeEnd, &byte, 1)
    }

    func close() {
        if readEnd >= 0 { Darwin.close(readEnd) }
        if writeEnd >= 0 { Darwin.close(writeEnd) }
    }
}
