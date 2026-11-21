import SunsetConfig
import SunsetPane
import SunsetShell
import SwiftUI

/// The welcome's features: a switch each, its name and what it is. The last one on stays on; one whose tabs are open is
/// turned off in Settings, which asks first.
struct WelcomeFeatures: View {
    let store: AppConfiguration

    private var features: Configuration.Features {
        store.configuration.features
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Welcome.row) {
            ForEach(Scopes.Scope.allCases, id: \.self) { scope in
                HStack(alignment: .firstTextBaseline, spacing: Design.Space.xl) {
                    Image(systemName: Self.symbol(scope)).font(.title3).frame(width: Design.Space.xxl)
                        .foregroundStyle(.secondary)
                    WelcomeOption(title: scope.title, detail: Self.detail(scope))
                    Spacer(minLength: Design.Space.xl)
                    Toggle(scope.title, isOn: binding(scope)).settingSwitch().labelsHidden()
                        .disabled(!canChange(scope))
                }
            }
            if Scopes.Scope.allCases.contains(where: { features[scope: $0] && AppScopes.openCount(of: $0) > 0 }) {
                Text("A feature with tabs open is turned off in Settings, which asks first.").font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func binding(_ scope: Scopes.Scope) -> Binding<Bool> {
        Binding(get: { features[scope: scope] }, set: { value in store.update { $0.features[scope: scope] = value } })
    }

    private func canChange(_ scope: Scopes.Scope) -> Bool {
        !features[scope: scope] || (features.count > 1 && AppScopes.openCount(of: scope) == 0)
    }

    static func symbol(_ scope: Scopes.Scope) -> String {
        switch scope {
            case .terminal: "terminal"
            case .web: "globe"
            case .documents: "doc.text"
        }
    }

    static func detail(_ scope: Scopes.Scope) -> String {
        switch scope {
            case .terminal: "Shells in tabs and panes, with sessions kept."
            case .web: "Pages, Spaces and extensions, with ads and trackers blocked."
            case .documents: "Markdown and text files, read and edited."
        }
    }
}
