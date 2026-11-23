import SunsetShell
import SwiftUI

/// The update centre's components (roadmap 0122 G, 0113): today the web engine, which comes with the app: the system's
/// for Sunset, updated by macOS; Sunset WebKit's own, updated with Sunset WebKit, with its age.
struct UpdateComponentRow: View {
    var body: some View {
        LabeledContent {
            Text(detail).foregroundStyle(.secondary)
        } label: {
            VStack(alignment: .leading, spacing: Design.Space.hair) {
                Text("Web engine")
                Text(name).font(Design.Text.detail).foregroundStyle(.secondary)
            }
        }
    }

    private var name: String {
        AppEngineFreshness.engine.map { "WebKit \($0.base.prefix(12))" } ?? "The system\u{2019}s WebKit"
    }

    private var detail: String {
        guard let engine = AppEngineFreshness.engine else { return "Updated by macOS" }
        let age = engine.weeks.map { "\($0) week\($0 == 1 ? "" : "s") old, " } ?? ""
        return age + "updated with Sunset WebKit"
    }
}
