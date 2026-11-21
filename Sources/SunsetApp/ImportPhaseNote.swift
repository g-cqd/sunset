import AppKit
import SunsetShell
import SwiftUI

/// What the import sheet says under its choices while it reads, or why it could not.
struct ImportPhaseNote: View {
    let phase: ImportSheet.Phase

    /// System Settings ▸ Privacy & Security ▸ Full Disk Access.
    private static let fullDiskAccess = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    )

    var body: some View {
        switch phase {
            case .reading:
                HStack(spacing: Design.Space.m) {
                    ProgressView().controlSize(.small)
                    Text("Reading\u{2026}").foregroundStyle(.secondary)
                }
            case .needsAccess:
                VStack(alignment: .leading, spacing: Design.Space.s) {
                    Text(
                        "macOS keeps this browser\u{2019}s data private. To import it, allow Sunset in Full Disk Access, then quit and reopen Sunset."
                    )
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    if let url = Self.fullDiskAccess {
                        Button("Open Full Disk Access Settings") { NSWorkspace.shared.open(url) }
                    }
                }
            case .failed(let why):
                Text(why).foregroundStyle(.secondary)
            case .choosing, .done:
                EmptyView()
        }
    }
}
