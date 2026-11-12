import SunsetConfig
import SunsetShell
import SwiftUI

/// The search engines the person added (`web.engines`): name, keyword, search and suggestion addresses with `%s`; added and removed here.
struct EngineList: View {
    @Binding var engines: [Configuration.Web.Engine]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Added search engines").font(Design.Text.title)
            Text("%s stands for the words. The suggestion address must answer in the OpenSearch JSON format.")
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
            ForEach(engines.indices, id: \.self) { index in row(index) }
            Button("Add Engine") {
                engines.append(
                    .init(name: "Engine \(engines.count + 1)", keyword: "", search: "https://example.com/search?q=%s")
                )
            }
        }
    }

    private func row(_ index: Int) -> some View {
        HStack(alignment: .top) {
            VStack(spacing: 4) {
                HStack {
                    TextField("Name", text: $engines[index].name)
                    TextField("Keyword", text: $engines[index].keyword).frame(width: 80)
                }
                TextField("Search address", text: $engines[index].search)
                TextField("Suggestion address (optional)", text: suggest(index))
            }
            .textFieldStyle(.roundedBorder)
            .labelsHidden()
            .multilineTextAlignment(.leading)
            Button {
                engines.remove(at: index)
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .help("Remove")
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(Design.Fill.faint)))
    }

    private func suggest(_ index: Int) -> Binding<String> {
        Binding(
            get: { engines.indices.contains(index) ? engines[index].suggest ?? "" : "" },
            set: { engines[index].suggest = $0.isEmpty ? nil : $0 }
        )
    }
}
