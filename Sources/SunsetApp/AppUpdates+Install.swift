import AppKit
import Foundation
import SunsetUpdate

extension AppUpdates {
    /// Restart to Update: Sunset quits as it always does (it may ask first); the update goes in place as it ends, and
    /// Sunset opens again.
    func installAndRestart() {
        guard case .ready = phase else { return }
        restart()
    }

    /// Quits and opens again: what waits for it (an update, a change of engine) is made in between.
    func restart() {
        restartsAfterInstall = true
        NSApp.terminate(nil)
    }

    /// As Sunset ends (`applicationWillTerminate`): a ready update checked once more and swapped in; the former app to the
    /// Trash; Sunset opened again when asked to. Anything wrong leaves the running app as it is.
    func installAtQuit() {
        AppEngine.shared.applyAtQuit()
        guard case .ready = phase, let staging, refusal == nil else {
            if restartsAfterInstall { Self.openWhenGone(running.bundle) }
            return
        }
        do {
            try UpdateTransfer.check(staging, running: running)
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
