import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetShellModel
import SwiftUI

/// Settings > General > What Sunset does (roadmap 0033; ADR-0056): a switch for each scope. Turning one off closes what
/// is open of it, after a question when there is anything; the last one on cannot be turned off.
struct FeaturesSettings: View {
    @Binding var features: Configuration.Features
    @State private var asking: Scopes.Scope?

    var body: some View {
        Group {
            ForEach(Scopes.Scope.allCases, id: \.self) { scope in
                LabeledContent {
                    Toggle(scope.title, isOn: binding(scope)).settingSwitch().labelsHidden()
                        .disabled(isOn(scope) && features.count == 1)
                        .accessibilityLabel(scope.title)
                } label: {
                    Text(scope.title)
                }
            }
        }
        .sunsetAlert(item: $asking) { scope in
            SunsetAlert(
                title: "Turn off \(Self.name(scope))?",
                message: AppScopes.sentence(closing: scope),
                buttons: [.cancel("Cancel"), .destructive("Turn Off and Close")],
                defaultButton: 0
            )
        } answer: { scope, pressed in
            if pressed == 1 { set(scope, false) }
        }
    }

    private func isOn(_ scope: Scopes.Scope) -> Bool {
        switch scope {
            case .terminal: features.terminal
            case .web: features.web
            case .documents: features.documents
        }
    }

    private func set(_ scope: Scopes.Scope, _ value: Bool) {
        switch scope {
            case .terminal: features.terminal = value
            case .web: features.web = value
            case .documents: features.documents = value
        }
    }

    /// On at once; off at once when nothing of the scope is open, else after the question.
    private func binding(_ scope: Scopes.Scope) -> Binding<Bool> {
        Binding(
            get: { isOn(scope) },
            set: { value in
                if value || AppScopes.openCount(of: scope) == 0 { set(scope, value) } else { asking = scope }
            }
        )
    }

    static func name(_ scope: Scopes.Scope) -> String {
        switch scope {
            case .terminal: "terminals"
            case .web: "the web"
            case .documents: "documents"
        }
    }
}
