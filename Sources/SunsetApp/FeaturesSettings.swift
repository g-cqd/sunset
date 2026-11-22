import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetShellModel
import SwiftUI

/// Settings > General > What Sunset does: a switch for each scope. Turning one off closes what is open of it, after a
/// question when there is anything; the last one on cannot be turned off.
struct FeaturesSettings: View {
    @Binding var features: Configuration.Features
    @State private var asking: Scopes.Scope?

    var body: some View {
        Group {
            ForEach(Scopes.Scope.allCases, id: \.self) { scope in
                LabeledContent {
                    Toggle(scope.title, isOn: binding(scope)).settingSwitch().labelsHidden()
                        .disabled(isOn(scope) && scope.isTabs && features.count == 1)
                        .accessibilityLabel(scope.title)
                } label: {
                    Text(scope.title)
                }
            }
        }
        .sunsetAlert(item: $asking) { scope in
            SunsetAlert(
                title: "Turn off \(scope.name)?",
                message: AppScopes.sentence(closing: scope),
                buttons: [.cancel("Cancel"), .destructive("Turn Off and Close")],
                defaultButton: 0
            )
        } answer: { scope, pressed in
            if pressed == 1 { set(scope, false) }
        }
    }

    private func isOn(_ scope: Scopes.Scope) -> Bool {
        features[scope: scope]
    }

    private func set(_ scope: Scopes.Scope, _ value: Bool) {
        features[scope: scope] = value
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
}
