import AppKit
import Foundation

/// Manages Sunset's bundled Quick Look extensions (`SunsetMarkdownPreview.appex` and `SunsetMarkdownThumbnail.appex`)
/// through macOS's `pluginkit`, so the user can toggle Quick Look for Markdown right inside Sunset as well as in System
/// Settings › General › Login Items & Extensions › Quick Look.
@MainActor
enum QuickLookExtension {
    /// The bundle identifiers of Sunset's Quick Look extensions (Release or Dev).
    static func identifiers(appIdentifier: String = Bundle.main.bundleIdentifier ?? "studio.aemi.sunset") -> [String] {
        ["\(appIdentifier).quicklook.preview", "\(appIdentifier).quicklook.thumbnail"]
    }

    /// URLs of the `.appex` bundles embedded in the running Sunset app.
    static func embeddedPlugIns(appBundle: Bundle = .main) -> [URL] {
        guard let plugIns = appBundle.builtInPlugInsURL else { return [] }
        return ["SunsetMarkdownPreview.appex", "SunsetMarkdownThumbnail.appex"]
            .map { plugIns.appendingPathComponent($0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// Current registration and enabled state of Sunset's Quick Look preview extension.
    struct Status: Sendable, Equatable {
        /// Whether the extension bundles are embedded in this build of Sunset.
        var bundled: Bool
        /// Whether macOS currently has the preview extension elected (`+` in `pluginkit -m`).
        var enabled: Bool
        /// Whether an external MarkdownLook extension is also registered.
        var legacyRegistered: Bool
    }

    /// Queries `pluginkit` for the current state.
    static func status() async -> Status {
        let bundled = !embeddedPlugIns().isEmpty
        let previewID = identifiers()[0]
        return await queryStatus(bundled: bundled, previewID: previewID)
    }

    /// Registers the embedded extensions if needed and elects (`use`) or disables (`ignore`) them via `pluginkit`.
    @discardableResult
    static func setEnabled(_ on: Bool) async -> Bool {
        await applyElection(on: on, plugIns: embeddedPlugIns(), ids: identifiers())
    }

    /// Opens System Settings to Login Items & Extensions where Quick Look extensions live.
    static func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
            NSWorkspace.shared.open(url)
        }
    }

    @concurrent
    private nonisolated static func queryStatus(bundled: Bool, previewID: String) async -> Status {
        let output = runPluginKit(["-m", "-p", "com.apple.quicklook.preview"])
        let lines = output.split(separator: "\n")
        let enabled = lines.contains { line in
            line.contains(previewID) && line.trimmingCharacters(in: .whitespaces).hasPrefix("+")
        }
        let legacy = lines.contains { $0.contains("studio.aemi.MarkdownLook.Preview") }
        return Status(bundled: bundled, enabled: enabled, legacyRegistered: legacy)
    }

    @concurrent
    private nonisolated static func applyElection(on: Bool, plugIns: [URL], ids: [String]) async -> Bool {
        if on {
            for url in plugIns { _ = runPluginKit(["-a", url.path]) }
        }
        let election = on ? "use" : "ignore"
        var ok = true
        for id in ids where !runPluginKitSucceeds(["-e", election, "-i", id]) {
            ok = false
        }
        if on {
            for legacy in ["studio.aemi.MarkdownLook.Preview", "studio.aemi.MarkdownLook.Thumbnail"] {
                _ = runPluginKit(["-e", "ignore", "-i", legacy])
            }
        }
        return ok
    }

    private nonisolated static func runPluginKit(_ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(decoding: data, as: UTF8.self)
        } catch {
            return ""
        }
    }

    private nonisolated static func runPluginKitSucceeds(_ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
