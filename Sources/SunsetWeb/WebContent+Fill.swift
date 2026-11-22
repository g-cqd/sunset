import WebKit

extension WebContent {
    /// Fills the page's sign-in form with a username and a password, on the person's act (roadmap 0094 C): the main frame's visible
    /// fields only, from Sunset's own world. Returns whether a password field was filled.
    package func fill(username: String, password: String) async -> Bool {
        guard let view = webView else { return false }
        let filled = try? await view.callAsyncJavaScript(
            PasswordFillScript.fill,
            arguments: ["username": username, "secret": password],
            in: nil,
            contentWorld: .defaultClient
        )
        return filled as? Bool ?? false
    }
}
