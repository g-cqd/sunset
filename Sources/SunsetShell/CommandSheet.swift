package import SunsetPane
package import SwiftUI

/// The dialog that shows a kept terminal's command whole and edits it (R3, t145): the only way a command is written. Empty removes it.
package struct CommandSheet: View {
    let tabs: TabsModel
    let entry: Favorites.NodeID
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss

    package init(tabs: TabsModel, entry: Favorites.NodeID) {
        self.tabs = tabs
        self.entry = entry
    }

    package var body: some View {
        let saved = tabs.favorites.favorites.entry(entry)
        VStack(alignment: .leading, spacing: 10) {
            Text("Command for \u{201C}\(saved?.title ?? "this favourite")\u{201D}").font(.headline)
            Text(
                "Typed into the shell, then Return, each time this favourite starts: when it is opened, and when Sunset comes back with it open."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            if let directory = saved?.home.contents[saved?.home.focused ?? PaneID()]?.directory {
                Text("In \(directory)").font(.callout.monospaced()).foregroundStyle(.secondary)
            }
            if tabs.favorites.unconfirmed.contains(entry) {
                Label(
                    "This command was not written by Sunset (the session file was changed by something else). It was not run. Save it to trust it.",
                    systemImage: "exclamationmark.shield"
                )
                .font(.callout)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
            }
            TextEditor(text: $text)
                .font(.body.monospaced())
                .frame(minHeight: 80)
                .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(.separator) }
            HStack {
                Spacer()
                SwiftUI.Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                SwiftUI.Button("Save") {
                    tabs.favorites.setCommand(text, for: entry)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 460)
        .onAppear { text = saved?.command ?? "" }
    }
}
