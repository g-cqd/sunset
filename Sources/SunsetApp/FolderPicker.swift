import AppKit
import SunsetConfig
import SwiftUI

/// A folder chosen in the system's panel, for a setting that holds one (the owner's note n36): written as the file writes it
/// (`~` under the home folder). The field beside it stays, for a path typed or pasted.
struct FolderPicker: View {
    let title: String
    @Binding var path: String

    var body: some View {
        Button("Choose\u{2026}") {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.canCreateDirectories = true
            panel.allowsMultipleSelection = false
            panel.prompt = "Choose"
            panel.message = title
            panel.directoryURL = URL(filePath: (path.isEmpty ? "~" : path as NSString).expandingTildeInPath)
            guard panel.runModal() == .OK, let url = panel.url else { return }
            path = SettingsOption.written(folder: url.path, home: NSHomeDirectory())
        }
        .help("Choose a folder")
    }
}
