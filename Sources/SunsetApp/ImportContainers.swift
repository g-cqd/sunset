import SunsetImport
import SunsetShell
import SunsetShellModel
import SwiftUI

/// Another browser's containers, offered as profiles: each keeps its sites' data apart, as the container did; made on
/// the person's press, once.
struct ImportContainers: View {
    let containers: [BrowserContainer]
    let tabs: TabsModel
    @State private var made: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            Text("Containers").font(Design.Text.title)
            Text(containers.map(\.name).joined(separator: ", ")).foregroundStyle(.secondary)
            if let made {
                Text(
                    made == 0
                        ? "Each already has a profile of its name." : "\(made) made, in Settings \u{25B8} Profiles."
                )
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
            } else {
                Button("Make Each a Profile") {
                    made = tabs.spaces?.profiles.adopt(named: containers.map(\.name)).count ?? 0
                }
                Text("A profile keeps its sites\u{2019} cookies and data apart, as a container does.")
                    .font(Design.Text.detail)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
