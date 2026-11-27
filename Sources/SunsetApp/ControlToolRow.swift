import AppKit
import SunsetConfig
import SunsetShell
import SwiftUI

/// Settings › General › Control from outside: where the `sunset` tool is (in the app's Helpers), and a link to it in
/// `~/.local/bin`, where a shell finds it.
struct ControlToolRow: View {
    let title: String
    @State private var linked = Self.isLinked
    @State private var problem: String?

    /// The tool inside the running app.
    static var tool: URL {
        Bundle.main.bundleURL.appending(path: "Contents/Helpers/sunset")
    }

    /// Where the link goes.
    static var link: URL {
        FileManager.default.homeDirectoryForCurrentUser.appending(path: ".local/bin/sunset")
    }

    static var isLinked: Bool {
        (try? FileManager.default.destinationOfSymbolicLink(atPath: link.path)) == tool.path
    }

    var body: some View {
        let exists = FileManager.default.isExecutableFile(atPath: Self.tool.path)
        VStack(alignment: .leading, spacing: Design.Space.m) {
            LabeledContent {
                Text(exists ? Self.tool.path : "Not in this build: swift build --product sunset")
                    .code().font(Design.Text.secondary).textSelection(.enabled)
                    .lineLimit(1).truncationMode(.middle)
            } label: {
                SettingsLabel(title)
            }
            HStack {
                Spacer()
                Button(linked ? "Linked in ~/.local/bin" : "Link in ~/.local/bin", action: makeLink)
                    .disabled(!exists || linked)
            }
            if let problem { Label(problem, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
        }
    }

    /// `~/.local/bin/sunset` pointing at the app's tool; an older link of ours replaced, a file of someone else's not.
    private func makeLink() {
        let manager = FileManager.default
        do {
            try manager.createDirectory(at: Self.link.deletingLastPathComponent(), withIntermediateDirectories: true)
            if (try? manager.destinationOfSymbolicLink(atPath: Self.link.path))?.hasSuffix("/Contents/Helpers/sunset")
                == true
            {
                try manager.removeItem(at: Self.link)
            }
            try manager.createSymbolicLink(at: Self.link, withDestinationURL: Self.tool)
            linked = true
            problem = nil
        } catch {
            problem = "Not linked: \(error.localizedDescription)"
        }
    }
}
