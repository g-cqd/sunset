@testable import SunsetShell

/// A sealer with a fixed secret: a seal is the secret and the text.
struct TestSealer: CommandSealing {
    var secret = "k"
    func seal(_ command: String) -> String { secret + ":" + command }
    func verifies(_ command: String, seal: String?) -> Bool { seal == secret + ":" + command }
}
