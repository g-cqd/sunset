import SunsetConfig
import SunsetPane

extension Configuration.Features {
    /// Whether `scope` is on: what Settings ▸ General and the welcome switch.
    subscript(scope scope: Scopes.Scope) -> Bool {
        get {
            switch scope {
                case .terminal: terminal
                case .web: web
                case .documents: documents
            }
        }
        set {
            switch scope {
                case .terminal: terminal = newValue
                case .web: web = newValue
                case .documents: documents = newValue
            }
        }
    }
}
