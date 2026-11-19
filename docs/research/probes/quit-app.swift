// Asks the running app `bundle identifier` to quit as the Dock or Cmd-Q would (a quit Apple event), then waits for it to end.
import AppKit

let id = CommandLine.arguments[1]
guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: id).first else {
    print("not running: \(id)")
    exit(1)
}
let start = Date()
print("terminate sent:", app.terminate())
while !app.isTerminated, Date().timeIntervalSince(start) < 30 {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
}
print(
    app.isTerminated
        ? "ended after \(String(format: "%.1f", Date().timeIntervalSince(start))) s" : "still running after 30 s"
)
