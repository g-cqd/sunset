import SunsetShell
import SunsetWeb
import SwiftUI

/// Settings > Web > Blocking: each list Sunset fetches (roadmap 0022 W-c), how many of its rules are in use, when it was
/// fetched, why one is not in use; and the sites blocking is paused on, each removable. The addresses are the file's
/// (`web.blockingLists`).
struct BlockingListsSettings: View {
    private let blocker = ContentBlocker.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.xs) {
            if blocker.states.isEmpty {
                Text("Not fetched yet.").font(Design.Text.detail).foregroundStyle(.secondary)
            }
            ForEach(blocker.states, id: \.address) { state in
                VStack(alignment: .leading, spacing: 0) {
                    Text(state.address).lineLimit(1).truncationMode(.middle)
                    Text(detail(state)).font(Design.Text.detail).foregroundStyle(.secondary)
                }
            }
            ForEach(blocker.pauses.paused, id: \.self) { host in
                HStack {
                    Text("Paused on \(host)").foregroundStyle(.secondary)
                    Spacer()
                    Button("Resume") {
                        blocker.pauses.set(false, for: host)
                        blocker.reapplyAll()
                    }
                }
            }
        }
    }

    private func detail(_ state: ContentBlocker.ListState) -> String {
        if let problem = state.problem { return problem }
        let when = state.updated.map { " · fetched " + $0.formatted(.relative(presentation: .named)) } ?? ""
        return "\(state.rules.formatted()) rules in use, \(state.skipped.formatted()) left out" + when
    }
}
