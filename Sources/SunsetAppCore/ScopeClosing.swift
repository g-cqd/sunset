package import SunsetPane

/// What the question says before a scope with open tabs is turned off (roadmap 0033; 0086 D: `AppScopes` said it in the app
/// target).
package enum ScopeClosing {
    package static func sentence(_ scope: Scopes.Scope, open count: Int) -> String {
        let what = count == 1 ? "1 tab of it is open and closes" : "\(count) tabs of it are open and close"
        let running = scope == .terminal ? " What runs in them is stopped." : ""
        let edits = scope == .documents ? " Edits that are not saved are kept, and asked about when Sunset quits." : ""
        return what + "." + running + edits + " What is kept of it (pinned, favorites) is hidden until it is on again."
    }
}
