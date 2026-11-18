import SunsetShell
import SunsetStorage
import SwiftUI

/// The key and its recovery code; entering a code; exporting.
extension StorageRows {
    @ViewBuilder var key: some View {
        line(
            "The key",
            storage.places.isDefault
                ? "In the login Keychain of this Mac. It is not synced."
                : "In a file beside the others: this is a named setup, which does not use the Keychain."
        )
        if let code = storage.code {
            VStack(alignment: .leading, spacing: Design.Space.m) {
                // No accessibility label on this text: a label on selectable text sends SwiftUI's accessibility into a loop
                // that ends the app as soon as anything reads the element (seen 2026-11-15, diary). It is read as what it says.
                Text(code).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                Text(
                    "Whoever has this code and the files reads everything. Write it down; it is hidden again when you leave."
                )
                .font(Design.Text.detail).foregroundStyle(.secondary)
                HStack {
                    FeedbackButton("Copy") { storage.copyCode() }
                    Button("Hide") { storage.hideCode() }
                }
            }
            .onDisappear { storage.hideCode() }
        } else {
            line(
                "Recovery code",
                storage.codeProblem
                    ?? (storage.hasKey
                        ? "The key in a form to write down. Without the key or this code, nothing sealed can be read."
                        : "There is no key here to show: enter the code of the key that sealed what is kept."),
                warn: storage.codeProblem != nil || !storage.hasKey
            ) {
                Button("Show\u{2026}") { Task { await storage.showCode() } }.disabled(!storage.hasKey)
            }
        }
    }

    var enterCode: some View {
        line(
            "Enter a recovery code",
            "On another Mac, or after losing the Keychain: puts a key back so that what it sealed opens again."
        ) {
            Button("Enter\u{2026}") { entersCode = true }
        }
        .sheet(isPresented: $entersCode) { RecoveryCodeSheet(storage: storage) }
    }

    @ViewBuilder var export: some View {
        line(
            "Export all",
            "Every document as a plain file, the history as CSV and the session as JSON, in a folder you choose. They stay in "
                + "Sunset: an export is a copy, and is not sealed."
        ) {
            Button("Export\u{2026}") { exported = StorageExport.ask() ?? exported }
        }
        if let exported {
            line("Last export", exported.sentence) {
                if let folder = exported.folder { Button("Show in Finder") { reveal(folder.path) } }
            }
        }
    }
}
