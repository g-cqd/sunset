/// Where the saved session (the open tabs) lives.
public enum SessionLocation {
    /// `$SUNSET_SESSION` if set (the file itself); else, when `$SUNSET_CONFIG` is set (a test or a second setup), `session.json` beside that file, so that it never
    /// touches the user's own; else `~/Library/Application Support/Sunset/session.json`. Empty variables count as unset.
    public static func path(environment: [String: String], home: String) -> String {
        if let file = environment["SUNSET_SESSION"], !file.isEmpty { return file }
        if let config = environment["SUNSET_CONFIG"], !config.isEmpty {
            let directory = config.lastIndex(of: "/").map { String(config[..<$0]) } ?? "."
            return directory + "/session.json"
        }
        var base = home
        while base.count > 1, base.hasSuffix("/") { base.removeLast() }
        return base + "/Library/Application Support/Sunset/session.json"
    }

    /// The file of the zoom each site was given (web step d), beside the session's.
    public static func zoomPath(environment: [String: String], home: String) -> String {
        let session = path(environment: environment, home: home)
        let directory = session.lastIndex(of: "/").map { String(session[..<$0]) } ?? "."
        return directory + "/site-zoom.json"
    }
}
