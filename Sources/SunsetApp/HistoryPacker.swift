import SunsetCore
import SunsetHost

/// Packs a terminal's old history once the terminal has been quiet for a while (owner note n14): a tab nobody types in and that prints nothing keeps its
/// history in a tenth of the memory, and reads of it (scrolling back) decode what they touch. Output and keys wake it, and it goes back to sleep: nothing
/// polls. It packs in small steps so that the terminal is locked for a moment at a time, and does nothing while activity goes on.
@MainActor
final class HistoryPacker {
    /// How long a terminal is quiet before its history is packed.
    static let quietTime = Duration.seconds(10)
    /// Full chunks (128 lines each) that stay as cells: the lines near the live screen are the ones that are read.
    static let keptRecent = 8
    /// Chunks packed per step (a step locks the terminal for about a millisecond and a half).
    static let step = 8

    private let session: TerminalSession
    /// Told when a pass has packed: the screen as it is now, whose history the owner's older copy takes in place of its own.
    private let packed: (Screen) -> Void
    private var last = ContinuousClock.now
    private var task: Task<Void, Never>?

    init(_ session: TerminalSession, packed: @escaping (Screen) -> Void) {
        self.session = session
        self.packed = packed
    }

    /// Something happened (output, a key): the quiet time starts again, and the packer wakes if it was asleep.
    func noteActivity() {
        last = .now
        guard task == nil else { return }
        task = Task { [weak self] in await self?.run() }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func run() async {
        while !Task.isCancelled {
            let due = last + Self.quietTime
            if ContinuousClock.now < due {
                try? await Task.sleep(until: due, clock: .continuous)
                continue
            }
            // Quiet: pack in steps, looking at the activity between them.
            let session = session
            let quietSince = last
            var didPack = false
            while !Task.isCancelled, last == quietSince {
                if session.packHistory(keepingRecent: Self.keptRecent, limit: Self.step) == 0 { break }
                didPack = true
                await Task.yield()
            }
            // What reading decoded goes too, and the owner's copy of the screen lets go of the cells that are packed now; then sleep until something happens.
            if last == quietSince {
                session.releaseDecodedHistory()
                if didPack { packed(session.screenCopy()) }
            }
            task = nil
            return
        }
    }
}
