import AppKit
import SunsetShell
import SunsetStorage
import SwiftUI

/// What is kept: sealed, not sealed, set aside.
extension StorageRows {
    @ViewBuilder var sealed: some View {
        let inventory = storage.inventory
        if !storage.hasKey {
            line(
                "Nothing is kept in this run",
                "The key that seals what Sunset keeps is not here (see Key and recovery). What is in the folder is left as it is.",
                warn: true
            )
        }
        line(
            "Documents",
            (inventory.documents == 1 ? "1 document" : "\(inventory.documents) documents")
                + ", \(size(inventory.documentBytes)) with their index. Each is a sealed file."
        ) {
            Button("Show in Finder") { reveal(storage.places.documents) }.disabled(inventory.documents == 0)
        }
        line("Tabs, folders and Favorites", "The session, \(size(inventory.sessionBytes)), sealed whole.")
        line(
            "History, zoom, permissions, downloads",
            "One database, \(size(inventory.stateBytes)). Addresses and titles are sealed in it."
        ) {
            Button("Show in Finder") { reveal(storage.places.directory) }
        }
    }

    @ViewBuilder var websiteData: some View {
        line("Website data", websiteSentence, warn: storage.fileVault == .off) {
            if storage.fileVault == .off {
                Button("Open FileVault\u{2026}") { openFileVault() }
            }
            Button("Clear\u{2026}") { confirmsClearing = true }
        }
        .confirmationDialog("Clear all website data?", isPresented: $confirmsClearing) {
            Button("Clear Website Data", role: .destructive) {
                WebClearing.clear(since: .distantPast, history: false, websiteData: true, siteZoom: false)
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    storage.refresh()
                }
            }
        } message: {
            Text(
                "Cookies and what sites have stored are removed. You are signed out of the sites you were signed in to."
            )
        }
        line("Configuration file", "Yours, plain, to read and edit: it is not sealed.") {
            Button("Show in Finder") { reveal(AppConfiguration.shared.path) }.disabled(!AppConfiguration.shared.hasFile)
        }
    }

    /// Cookies and sites' storage are WebKit's: Sunset cannot seal them (R12). FileVault is what protects them.
    private var websiteSentence: String {
        let kept = storage.websiteBytes.map { ", \(size($0))" } ?? ""
        let vault =
            switch storage.fileVault {
                case .on: "FileVault is their only protection: it is on."
                case .off: "FileVault is their only protection, and it is off: anyone with the disk can read them."
                case .unknown: "FileVault is their only protection; this Mac did not say whether it is on."
            }
        return "Cookies and what sites store are kept by WebKit\(kept), not sealed by Sunset. \(vault)"
    }

    private func openFileVault() {
        let address = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?FileVault"
        if let url = URL(string: address) { NSWorkspace.shared.open(url) }
    }

    @ViewBuilder var setAside: some View {
        if storage.inventory.setAside.isEmpty {
            line("Files set aside", "None. A file that does not read is moved aside under a dated name, never dropped.")
        }
        ForEach(storage.inventory.setAside) { file in
            line(
                file.name,
                "It did not read and was moved aside, \(size(file.bytes)). Nothing of it was dropped.",
                warn: true
            ) {
                Button("Show in Finder") { reveal(file.path) }
            }
        }
    }
}
