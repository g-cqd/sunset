import AppKit
import SunsetRuntime
import SunsetStorage

/// Sunset and Sunset WebKit keep one store (ADR-0114), and only one may have it open: both would write the same session.
/// Opened while the other runs, the second says so before it reads anything, and offers to quit the other (which saves its
/// session as it quits) or itself. Only for the person's own store: a test's or a named setup's run is left alone.
@MainActor
enum OtherBuildAtLaunch {
    /// How long the other is waited for once asked to quit.
    private static let patience = Duration.seconds(15)

    static func settle() {
        guard StoragePlaces.current.isDefault, let own = Bundle.main.bundleIdentifier else { return }
        let me = ProcessInfo.processInfo.processIdentifier
        let other = StoragePlaces.sharers(of: own)
            .flatMap { NSRunningApplication.runningApplications(withBundleIdentifier: $0) }
            .first { $0.processIdentifier != me && !$0.isTerminated }
        guard let other else { return }
        let name = other.localizedName ?? "Sunset"
        let alert = NSAlert()
        alert.messageText = "\(name) is open"
        alert.informativeText =
            "\(name) and this app keep the same windows, tabs and documents, and only one can have them open at a time. "
            + "Quit \(name) to open them here; it saves them as it quits."
        alert.addButton(withTitle: "Quit \(name)")
        alert.addButton(withTitle: "Quit This One")
        guard alert.runModal() == .alertFirstButtonReturn else { exit(EXIT_SUCCESS) }
        other.terminate()
        // Before the app runs: its run loop turned by hand while the other quits.
        let runtime = Runtime.live
        let deadline = runtime.uptime() + patience
        while !other.isTerminated, runtime.uptime() < deadline {
            RunLoop.current.run(until: runtime.now().addingTimeInterval(0.1))
        }
        guard other.isTerminated else {
            let stuck = NSAlert()
            stuck.messageText = "\(name) did not quit"
            stuck.informativeText =
                "It may be asking something in one of its windows. Quit it there, then open this one again."
            stuck.runModal()
            exit(EXIT_SUCCESS)
        }
    }
}
