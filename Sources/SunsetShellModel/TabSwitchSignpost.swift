package import os

/// Signposts around a switch of tab (n56, t298): what each step of a switch costs in the app, read with
/// `log stream --signpost --predicate 'subsystem == "studio.aemi.sunset"'` or Instruments' os_signpost track. With nothing
/// reading them they cost a flag test.
package enum TabSwitchSignpost {
    package static let signposter = OSSignposter(subsystem: "studio.aemi.sunset", category: "tab-switch")

    /// `body`, as an interval named `name`.
    package static func interval<T>(_ name: StaticString, _ body: () -> T) -> T {
        let state = signposter.beginInterval(name)
        defer { signposter.endInterval(name, state) }
        return body()
    }

    /// One content shown or hidden, named by its kind, so that a slow kind shows by its name.
    /// `kind` is asked only when something reads the signposts: a descriptor can be costly to make.
    package static func setState(kind: @autoclosure () -> String, shown: Bool, _ body: () -> Void) {
        guard signposter.isEnabled else { return body() }
        let state = signposter.beginInterval("setState")
        body()
        let named = kind()
        signposter.endInterval("setState", state, "\(named, privacy: .public) shown=\(shown)")
    }

    /// A moment: a view's body was evaluated, a view appeared.
    package static func event(_ name: StaticString) {
        signposter.emitEvent(name)
    }
}
