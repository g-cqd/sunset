import Foundation
import SunsetHost
import SunsetRuntime

/// A command typed into the shell for a kept entry (t145), as if typed and then Return: once the shell has drawn its prompt. With shell integration the
/// prompt is known from its mark; without it, once the shell has printed something and gone quiet for a moment. At most `deadline` is waited.
extension TerminalModel {
    private static let quiet = Duration.milliseconds(400)
    private static let deadline = Duration.seconds(6)
    private static let poll = Duration.milliseconds(100)

    package func type(command: String) {
        pendingCommand = command
        if session != nil { deliverPendingCommand() }
    }

    /// Called when the session exists: waits for the prompt, then types what is pending.
    func deliverPendingCommand() {
        guard pendingCommand != nil, let session, commandDelivery == nil else { return }
        commandDelivery = runtime.task { [weak self, runtime] in
            let start = runtime.uptime()
            while runtime.uptime() - start < Self.deadline, !Task.isCancelled {
                let status = session.status()
                if status.atPrompt { break }
                // No marks: the shell printed since the session started and has been quiet for a moment.
                if !status.marksPrompts, let printed = self?.lastActivity, printed > start,
                    runtime.uptime() - printed >= Self.quiet
                {
                    break
                }
                await runtime.sleep(for: Self.poll)
            }
            guard let self, let command = pendingCommand, !Task.isCancelled else { return }
            pendingCommand = nil
            commandDelivery = nil
            await session.send(text: command.replacingOccurrences(of: "\n", with: "\r") + "\r")
        }
    }
}
