import SunsetConfig
import SunsetShell
import SunsetWeb
import SunsetWebModel
import SwiftUI

/// Settings > Web > Blocking: each list Sunset fetches (roadmap 0022 W-c), how many of its rules are in use, when it was
/// fetched, why one is not in use, each removable; another added by its address (task t109, the owner's note n58); and the
/// sites blocking is paused on, each removable. The addresses are the file's (`web.blockingLists`).
struct BlockingListsSettings: View {
    private let blocker = ContentBlocker.shared
    @State private var adding = ""
    @State private var refusal: String?

    var body: some View {
        if blocker.states.isEmpty {
            Text("Not fetched yet.").foregroundStyle(.secondary)
        }
        ForEach(blocker.states, id: \.address) { state in
            LabeledContent {
                Button("Remove") { remove(state.address) }
            } label: {
                Text(state.address).code().lineLimit(1).truncationMode(.middle)
                Text(detail(state))
            }
        }
        LabeledContent {
            Button("Add") { add() }.disabled(adding.isEmpty)
        } label: {
            TextField("Another list's https address", text: $adding).onSubmit { add() }
            if let refusal { Text(refusal) }
        }
        ForEach(blocker.pauses.paused, id: \.self) { host in
            LabeledContent {
                Button("Resume") {
                    blocker.pauses.set(false, for: host)
                    blocker.reapplyAll()
                }
            } label: {
                Text("Paused on \(Text(host).code())")
            }
        }
    }

    private func add() {
        switch BlockingListPlan.adding(adding, to: AppConfiguration.shared.configuration.web.blockingLists) {
            case .added(let lists):
                AppConfiguration.shared.update { $0.web.blockingLists = lists }
                adding = ""
                refusal = nil
            case .refused(let why):
                refusal = why
        }
    }

    /// No longer fetched; its kept copy deleted (its compiled parts go at the next load).
    private func remove(_ address: String) {
        AppConfiguration.shared.update {
            $0.web.blockingLists = BlockingListPlan.removing(address, from: $0.web.blockingLists)
        }
        let kept = blocker.folder.appending(path: "lists").appending(path: BlockingListPlan.fileName(for: address))
        try? FileManager.default.removeItem(at: kept)
    }

    private func detail(_ state: ContentBlocker.ListState) -> String {
        if let problem = state.problem { return problem }
        let when = state.updated.map { " · fetched " + $0.formatted(.relative(presentation: .named)) } ?? ""
        return "\(state.rules.formatted()) rules in use, \(state.skipped.formatted()) left out" + when
    }
}
