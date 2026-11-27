extension WebContent {
    /// What restarts Sunset, from a page that ended because Sunset's files changed on disk; the app sets it.
    package static var restartApp: (@MainActor () -> Void)?
}
