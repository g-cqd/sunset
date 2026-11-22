import SunsetConfig
import SunsetShell
import SwiftUI

/// The search engines the person added (`web.engines`), rows of their section: each folds open on its name and keyword, every field
/// labelled, Remove under them, the search and suggestion addresses with `%s`; added and removed here.
struct EngineList: View {
    @Binding var engines: [Configuration.Web.Engine]
    /// The engines folded open: a new one is.
    @State private var open: Set<Int> = []

    var body: some View {
        if engines.isEmpty {
            Text("None added. Google, DuckDuckGo and the others above are always there.")
                .foregroundStyle(.secondary)
        }
        ForEach(engines.indices, id: \.self) { index in
            DisclosureGroup(isExpanded: expanded(index)) {
                FoldContent {
                    field("Name", text(index, \.name), prompt: "Shown in the list")
                    field("Keyword", text(index, \.keyword), prompt: "One short word", code: true)
                    field("Search address", text(index, \.search), prompt: "An address with %s", code: true)
                    field("Suggestion address", suggest(index), prompt: "Optional, with %s", code: true)
                    // Here, not in the label: macOS makes the label one control with the disclosure, and a press on it would
                    // remove the engine (seen, 2026-11-18).
                    LabeledContent {
                        Button("Remove Engine", role: .destructive) { remove(index) }
                    } label: {
                        EmptyView()
                    }
                }
            } label: {
                label(index)
            }
        }
        LabeledContent {
            Button("Add Search Engine") {
                // Valid at once: the file's reader leaves out an engine with no name or no %s.
                engines.append(
                    .init(name: "Engine \(engines.count + 1)", keyword: "", search: "https://example.org/search?q=%s")
                )
                open.insert(engines.count - 1)
            }
        } label: {
            EmptyView()
        }
    }

    private func label(_ index: Int) -> some View {
        let engine = engines.indices.contains(index) ? engines[index] : nil
        return HStack(spacing: Design.Space.s) {
            Text(engine.map { $0.name.isEmpty ? "New engine" : $0.name } ?? "")
            if let keyword = engine?.keyword, !keyword.isEmpty {
                Text(keyword).code().foregroundStyle(.secondary)
            }
        }
    }

    private func remove(_ index: Int) {
        guard engines.indices.contains(index) else { return }
        open = Set(open.compactMap { $0 == index ? nil : ($0 > index ? $0 - 1 : $0) })
        engines.remove(at: index)
    }

    /// A labelled field; `code`, an address or a keyword, in monospace.
    private func field(_ title: String, _ text: Binding<String>, prompt: String, code: Bool = false) -> some View {
        LabeledContent {
            TextField(title, text: text, prompt: Text(prompt))
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .code(code)
                .multilineTextAlignment(.leading)
                .frame(width: Design.Size.settingsField)
        } label: {
            Text(title)
        }
    }

    private func expanded(_ index: Int) -> Binding<Bool> {
        Binding(
            get: { open.contains(index) },
            set: { shown in if shown { open.insert(index) } else { open.remove(index) } }
        )
    }

    private func text(_ index: Int, _ path: WritableKeyPath<Configuration.Web.Engine, String>) -> Binding<String> {
        Binding(
            get: { engines.indices.contains(index) ? engines[index][keyPath: path] : "" },
            set: { if engines.indices.contains(index) { engines[index][keyPath: path] = $0 } }
        )
    }

    private func suggest(_ index: Int) -> Binding<String> {
        Binding(
            get: { engines.indices.contains(index) ? engines[index].suggest ?? "" : "" },
            set: { if engines.indices.contains(index) { engines[index].suggest = $0.isEmpty ? nil : $0 } }
        )
    }
}
