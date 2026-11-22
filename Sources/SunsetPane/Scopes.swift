/// The scopes of the app that are on: terminals, the web, documents. Each is a kind of pane, and can be removed whole;
/// at least one is always on, so that there is something to turn the others back on from.
public struct Scopes: Sendable, Equatable {
    public enum Scope: String, Sendable, CaseIterable {
        case terminal, web, documents
        /// The vault (the Library's Passwords section): not a kind of tab, and off unless turned on.
        case passwords

        /// A scope of tabs: at least one of these stays on.
        public var isTabs: Bool {
            self != .passwords
        }
    }

    private var on: Set<Scope>

    /// The three scopes of tabs all off is terminals on. Passwords is off unless asked for.
    public init(terminal: Bool = true, web: Bool = true, documents: Bool = true, passwords: Bool = false) {
        on = []
        if terminal { on.insert(.terminal) }
        if web { on.insert(.web) }
        if documents { on.insert(.documents) }
        if on.isEmpty { on = [.terminal] }
        if passwords { on.insert(.passwords) }
    }

    /// Whether a scope is on. Turning the last one off is refused.
    public subscript(scope: Scope) -> Bool {
        get {
            on.contains(scope)
        }
        set {
            if newValue { on.insert(scope) } else if canTurnOff(scope) { on.remove(scope) }
        }
    }

    public var terminal: Bool {
        get {
            self[.terminal]
        }
        set {
            self[.terminal] = newValue
        }
    }

    public var web: Bool {
        get {
            self[.web]
        }
        set {
            self[.web] = newValue
        }
    }

    public var documents: Bool {
        get {
            self[.documents]
        }
        set {
            self[.documents] = newValue
        }
    }

    public var passwords: Bool {
        get {
            self[.passwords]
        }
        set {
            self[.passwords] = newValue
        }
    }

    /// It is on, and is not the only scope of tabs on.
    public func canTurnOff(_ scope: Scope) -> Bool {
        on.contains(scope) && (!scope.isTabs || on.count { $0.isTabs } > 1)
    }

    /// The scopes that are off.
    public var off: [Scope] {
        Scope.allCases.filter { !on.contains($0) }
    }

    /// Whether a pane of this kind can be: a kind that is none of the scopes' (the settings) always can.
    public func allows(kind: String) -> Bool {
        Scope.allCases.first { $0.kind == kind }.map(on.contains) ?? true
    }

    /// Whether what `descriptor` says can be made; no descriptor is a terminal.
    public func allows(_ descriptor: PaneDescriptor?) -> Bool {
        allows(kind: descriptor?.kind ?? PaneDescriptor.terminalKind)
    }

    /// Whether a kept entry can be shown and opened: each kind it starts from is on.
    public func allows(_ entry: Favorites.Entry) -> Bool {
        entry.kinds.allSatisfy(allows(kind:))
    }
}
