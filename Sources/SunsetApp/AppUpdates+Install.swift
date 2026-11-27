import AppKit
import Foundation
import SunsetRuntime
import SunsetUpdate

extension AppUpdates {
    /// Restart to Update: Sunset quits as it always does (it may ask first); the update goes in place as it ends, and
    /// Sunset opens again.
    func installAndRestart() {
        guard case .ready = phase else { return }
        restart()
    }

    /// Quits and opens again: what waits for it (an update or an engine switch) is swapped in between. The update window
    /// goes first, and the quit is asked for once the button's action has returned: AppKit waits for the quit's answer
    /// (the question, a sheet on a window) inside `terminate`, and asked from within a SwiftUI action the question never
    /// came up and Sunset hung until force-quit (the owner, 2026-11-27).
    func restart() {
        restartsAfterInstall = true
        UpdateWindow.close()
        Runtime.live.task { @MainActor in NSApp.terminate(nil) }
    }

    /// The person kept Sunset open when asked about quitting: it is no longer to open again at its next quit.
    func quitCancelled() {
        restartsAfterInstall = false
    }

    /// As Sunset ends (`applicationWillTerminate`): a ready update checked once more and swapped in; the former app to the
    /// Trash; Sunset opened again when asked to. Anything wrong leaves the running app as it is.
    func installAtQuit() {
        guard case .ready = phase, let staging, refusal == nil else { return }
        let target = stagedFlavour ?? running.flavour
        do {
            try UpdateTransfer.check(staging, running: running, targetFlavour: target)
            try BundleSwap.swap(running: running.bundle, staging: staging)
        } catch {
            restartsAfterInstall = false
            return
        }
        try? FileManager.default.trashItem(at: staging, resultingItemURL: nil)
        if restartsAfterInstall { Self.openWhenGone(running.bundle) }
    }

    /// Opens `app` once this process has ended (a shell that waits on its identifier: no program of ours outlives it),
    /// with Sunset's own variables of this process (a test copy's folders stay its own).
    private static func openWhenGone(_ app: URL) {
        let opener = Process()
        opener.executableURL = URL(filePath: "/bin/sh")
        let script =
            "pid=\"$1\"; shift; while /bin/kill -0 \"$pid\" 2>/dev/null; do /bin/sleep 0.2; done; /usr/bin/open \"$@\""
        let own = ProcessInfo.processInfo.environment.filter { $0.key.hasPrefix("SUNSET_") }.sorted { $0.key < $1.key }
        let options = own.flatMap { ["--env", "\($0.key)=\($0.value)"] }
        opener.arguments =
            ["-c", script, "sh", String(ProcessInfo.processInfo.processIdentifier)] + options + [app.path]
        try? opener.run()
    }
}
