/// What seals a kept terminal's command and checks the seal (t145); the app's is keyed by a secret in the Keychain (`SunsetHost.CommandSeal`).
package protocol CommandSealing: Sendable {
    func seal(_ command: String) -> String
    func verifies(_ command: String, seal: String?) -> Bool
}
