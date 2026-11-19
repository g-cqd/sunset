import AppKit
import SunsetConfig
import SunsetRuntime
import SunsetShell
import SunsetStorage
import SwiftUI

/// The rows of Settings, Storage (R12, roadmap 0030 step ST-6; the owner: topics of Privacy and security): what is sealed, the
/// website data, the files set aside; the key and its recovery code; exporting.
struct StorageRows: View {
    @Environment(\.runtime) var runtime

    let custom: SettingsControl.Custom
    let storage = StorageSettings.shared
    @State var confirmsClearing = false
    @State var entersCode = false
    @State var exported: ExportAll.Outcome?

    var body: some View {
        Group {
            switch custom {
                case .storageSealed: sealed
                case .storageWebsiteData: websiteData
                case .storageSetAside: setAside
                case .storageKey: key
                case .storageEnterCode: enterCode
                case .storageExport: export
                default: EmptyView()
            }
        }
        .onAppear { if custom == .storageSealed || custom == .storageWebsiteData { storage.refresh() } }
    }

    /// A line: what it is, what is said of it, and what can be done.
    func line(
        _ title: String,
        _ detail: String,
        warn: Bool = false,
        @ViewBuilder actions: () -> some View = { EmptyView() }
    )
        -> some View
    {
        LabeledContent {
            actions()
        } label: {
            Text(title)
            Text(detail).foregroundStyle(warn ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
        }
    }

    func size(_ bytes: Int) -> String {
        Int64(bytes).formatted(.byteCount(style: .file))
    }

    func reveal(_ path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }
}
