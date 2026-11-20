import AppKit
import SunsetRuntime
import SunsetWeb
import UniformTypeIdentifiers

/// Installing an extension (roadmap 0109 C, ADR-0109): a package or folder picked, read, and a prompt that says what it may do;
/// granted all of it on Add, nothing on Cancel.
extension AppActions {
    /// Into the acting window's profile.
    func installExtension() {
        let tabs = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)
        let profile = tabs.flatMap(PaneContentKinds.profile(of:))
        guard let host = ExtensionHosts.shared.host(for: profile) else { return }
        installExtension(into: host)
    }

    func installExtension(into host: ExtensionHost) {
        let panel = NSOpenPanel()
        panel.title = "Install Extension"
        panel.prompt = "Choose"
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.zip, .folder] + ["crx", "xpi"].compactMap { UTType(filenameExtension: $0) }
        guard panel.runModal() == .OK, let source = panel.url else { return }
        Runtime.live.task { @MainActor in
            do {
                let candidate = try await ExtensionHost.read(source)
                guard ExtensionPrompt.ask(candidate) else { return }
                try await host.install(candidate)
            } catch {
                let alert = NSAlert(error: error)
                alert.messageText = "This extension cannot be installed"
                alert.runModal()
            }
        }
    }
}
