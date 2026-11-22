import Foundation
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Mock-ups of Settings, Storage: where things are, what protects them, the recovery code, exporting. Drawn with plain
/// shapes to choose from; nothing is built.
extension DesignCatalogTests {
    /// A line of a page: a name, what it says, and a button or nothing.
    func storageLine(_ name: String, _ value: String, button: String? = nil, warn: Bool = false) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.system(size: 12)).lineLimit(1)
                Text(value).font(.system(size: 10)).foregroundStyle(warn ? .orange : .secondary).lineLimit(2)
            }
            Spacer(minLength: 4)
            if let button {
                Text(button).font(.system(size: 11))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.primary.opacity(0.12)))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
    }

    func storagePage(_ title: String, @ViewBuilder _ groups: () -> some View) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.system(size: 14, weight: .semibold))
                groups()
            }
            .padding(12).frame(width: 430, alignment: .topLeading)
            .background(Color(white: 0.14))
        )
    }

    var storageWhere: AnyView {
        storagePage("Storage \u{203A} What is kept") {
            settingGroup("Sealed with your key") {
                storageLine("Documents", "12 documents, 84 KB", button: "Show in Finder")
                storageLine("Tabs, folders and Favorites", "session.sealed, 6 KB")
                storageLine(
                    "History, zoom, permissions, downloads",
                    "state.sqlite, 1.2 MB; addresses and titles are sealed"
                )
            }
            settingGroup("Not sealed") {
                storageLine(
                    "Website data",
                    "Cookies and sites' storage are WebKit's, 6.5 MB. FileVault is their only protection: it is on.",
                    button: "Clear\u{2026}"
                )
                storageLine("Configuration file", "config.json: yours, plain, to read and edit")
            }
            settingGroup("Set aside") {
                storageLine(
                    "session.sealed.damaged-2026-11-14",
                    "It did not read, and was moved aside. Nothing was dropped.",
                    button: "Show in Finder",
                    warn: true
                )
            }
        }
    }

    var storageWhereOff: AnyView {
        storagePage("Storage \u{203A} What is kept") {
            settingGroup("Not sealed") {
                storageLine(
                    "Website data",
                    "Cookies and sites' storage are WebKit's, 6.5 MB. FileVault is their only protection: it is off.",
                    button: "Open FileVault\u{2026}",
                    warn: true
                )
            }
        }
    }

    func storageKey(shown: Bool) -> AnyView {
        storagePage("Storage \u{203A} Key and recovery") {
            settingGroup("The key") {
                storageLine("Kept in", "The login Keychain of this Mac. It is not synced.")
                if shown {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("4KQ2M-7XH0P-9TB3D-W1ZRC-5N8YE-GJ6VA\nF0SMK-2D7QX-HB9TP-R3W5C-1Z8N")
                            .font(.system(size: 12, design: .monospaced))
                        Text(
                            "Whoever has this code and the files reads everything. Write it down; it is hidden again when you leave."
                        )
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            ForEach(["Copy", "Print\u{2026}", "Hide"], id: \.self) { name in
                                Text(name).font(.system(size: 11)).padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(.primary.opacity(0.12))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 7)
                } else {
                    storageLine(
                        "Recovery code",
                        "The key in a form to write down. Without the key or this code, nothing sealed can be read.",
                        button: "Show\u{2026}"
                    )
                }
            }
            settingGroup("On another Mac, or after losing the Keychain") {
                storageLine(
                    "Enter a recovery code",
                    "Puts a key back so that what it sealed opens again.",
                    button: "Enter\u{2026}"
                )
            }
        }
    }

    var storageExport: AnyView {
        storagePage("Storage \u{203A} Export") {
            settingGroup("Out of the store, as plain files") {
                storageLine(
                    "Export all documents",
                    "Each as Title.md (or .mmd, .txt) in a folder you choose.",
                    button: "Export\u{2026}"
                )
                storageLine(
                    "Export the history",
                    "Addresses, titles and dates as one CSV file.",
                    button: "Export\u{2026}"
                )
            }
            settingGroup("Old files, once imported") {
                settingRow("Plain files Sunset has imported go to", value: "The Trash")
            }
        }
    }

    var storageSheet: CatalogSheet {
        CatalogSheet(
            title: "Settings, Storage (mock-up, 0030 ST-6)",
            note:
                "Three topics of a Storage section. What is kept: each thing, its size, whether it is sealed; the website data's "
                + "sentence with FileVault's state, read from the Mac; the files that did not read and were set aside. Key and "
                + "recovery: where the key is, the code behind a button, a way to enter one. Export: the documents as plain "
                + "files; what becomes of plain files once imported.",
            columns: [
                .init(
                    title: "What is kept",
                    examples: [
                        .init(label: "FileVault on, one file set aside", view: storageWhere),
                        .init(label: "FileVault off", view: storageWhereOff)
                    ]
                ),
                .init(
                    title: "Key and recovery",
                    examples: [
                        .init(label: "at rest", view: storageKey(shown: false)),
                        .init(label: "the code shown", view: storageKey(shown: true))
                    ]
                ),
                .init(title: "Export", examples: [.init(label: "", view: storageExport)])
            ],
            width: 430
        )
    }

    @Test func `Settings, Storage, drawn to choose from`() throws {
        guard let folder = ProcessInfo.processInfo.environment["SUNSET_CATALOG"].map({ URL(fileURLWithPath: $0) })
        else { return }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        #expect(storageSheet.write(to: folder.appending(path: "storage-settings.png")))
    }
}
