import SunsetConfig
import SunsetPane
import SunsetShellModel
import SwiftUI

/// Settings > General > Keyboard shortcuts: each command of the menus with its key, by menu; a key is recorded by
/// pressing it, and one the file gave can be put back to the table's.
struct KeysSettings: View {
    let config: any SettingsStore
    private let keys = CommandKeys.shared

    var body: some View {
        let scopes = AppScopes.current
        let commands = AppCommand.table.filter { $0.scope.map { scopes[$0] } ?? true }
        let menus = commands.map(\.menu).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        ForEach(menus, id: \.self) { menu in
            Section(menu) {
                ForEach(commands.filter { $0.menu == menu }) { command in
                    LabeledContent {
                        HStack(spacing: 6) {
                            if keys.isGiven(command.id) {
                                Button("Put back", systemImage: "arrow.uturn.backward") {
                                    give(command.key, to: command.id)
                                }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.borderless)
                                .help("Put back \(command.key?.symbols ?? "no key")")
                            }
                            KeyRecorder(key: keys.key(for: command.id)) { chord in give(chord, to: command.id) }
                        }
                    } label: {
                        Label(command.title, systemImage: command.symbol)
                    }
                }
            }
        }
    }

    private func give(_ chord: KeyChord?, to id: AppCommand.ID) {
        config.update { $0.keys = keys.giving(chord, to: id, in: $0.keys) }
    }
}
