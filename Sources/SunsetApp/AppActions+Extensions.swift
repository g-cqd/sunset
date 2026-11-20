import AppKit
import Foundation
import SunsetRuntime
import SunsetWeb
import SunsetWebModel
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
        Runtime.live.task { @MainActor in await self.install(source, into: host) }
    }

    /// Read, asked, installed; an alert when it cannot be.
    func install(_ source: URL, into host: ExtensionHost) async {
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

    /// What a store's page names (roadmap 0109 E): its package fetched from the store, then read, asked and installed into the
    /// page's profile.
    func install(from link: ExtensionStoreLink, profile: UUID?) {
        installFetched(profile: profile) { try await ExtensionDownload.fetch(link) }
    }

    /// A package a page offered (a `.crx` or `.xpi` link): fetched, then read, asked and installed.
    func installPackage(at address: URL, profile: UUID?) {
        installFetched(profile: profile) { try await ExtensionDownload.fetch(package: address) }
    }

    private func installFetched(profile: UUID?, fetch: @escaping @MainActor () async throws -> URL) {
        guard let host = ExtensionHosts.shared.host(for: profile) else { return }
        Runtime.live.task { @MainActor in
            do {
                let file = try await fetch()
                defer { try? FileManager.default.removeItem(at: file) }
                await self.install(file, into: host)
            } catch {
                let alert = NSAlert(error: error)
                alert.messageText = "This extension could not be fetched"
                alert.runModal()
            }
        }
    }
}
