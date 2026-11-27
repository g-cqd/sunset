import SunsetRuntime

extension WebContent {
    /// Whether the person clicked or typed in the page a moment ago.
    var hasRecentUserInput: Bool {
        guard let lastUserInput else { return false }
        let now = runtime.uptime()
        return now >= lastUserInput && now - lastUserInput < Self.userInputLasts
    }
}
