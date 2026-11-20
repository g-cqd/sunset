package import AppKit
import Foundation
import Observation
import SunsetRuntime
package import SunsetWebModel
package import WebKit

/// One profile's extensions running (roadmap 0109 B, C; ADR-0109): WebKit's controller, persistent and the profile's own,
/// holding each extension installed and on, granted what the person granted at install; in private pages only where allowed.
/// Installed, turned on or off, allowed in private windows or removed while Sunset runs.
@MainActor @Observable package final class ExtensionHost {
    /// What an extension package says of itself, read before it is installed: for the prompt (ADR-0109: granted at install).
    package struct Candidate {
        package let source: URL
        package let name: String
        package let version: String
        package let summary: String
        package let permissions: [String]
        package let sites: [String]
        package let icon: NSImage?

        /// What the prompt lists.
        package var lines: [String] {
            ExtensionWording.lines(permissions: permissions, sites: sites)
        }
    }

    @ObservationIgnored package let controller: WKWebExtensionController
    private var store: ExtensionStore
    @ObservationIgnored private var contexts: [UUID: WKWebExtensionContext] = [:]
    @ObservationIgnored private var loading: Task<Void, Never>?
    @ObservationIgnored private let runtime: Runtime
    /// Bumped when an action changes (its badge, its title): the buttons are drawn again.
    var revision = 0
    @ObservationIgnored var anchors: [String: NSView] = [:]
    /// The puzzle piece, while an extension chosen from its list opens its popup.
    @ObservationIgnored var popupAnchor: NSView?
    @ObservationIgnored private let delegate = ExtensionControllerDelegate()
    /// Shows an action's popup; by default WebKit's popover under its button. Tests watch it.
    @ObservationIgnored package var presentPopup: (ExtensionActionItem, WKWebExtension.Action) -> Void = { _, _ in }

    /// Its profile: the windows it sees are that profile's.
    @ObservationIgnored let profile: UUID?

    init(root: URL, profile: UUID?, runtime: Runtime = .live) {
        self.profile = profile
        store = ExtensionStore(root: root, profile: profile)
        self.runtime = runtime
        // A profile's own storage for its extensions; the default profile's is WebKit's default.
        let configuration = profile.map { WKWebExtensionController.Configuration(identifier: $0) } ?? .default()
        ExtensionPageShim.install(on: configuration)
        controller = WKWebExtensionController(configuration: configuration)
        delegate.host = self
        controller.delegate = delegate
        presentPopup = { [weak self] item, action in self?.showPopover(of: action, anchoredTo: item.id) }
        loading = runtime.task { @MainActor [weak self] in
            guard let self else { return }
            for entry in store.installed where entry.enabled { await load(entry) }
        }
    }

    /// What is installed, on or off.
    package var installed: [ExtensionStore.Installed] {
        store.installed
    }

    /// Done loading what is installed.
    package func ready() async {
        await loading?.value
    }

    /// Reads a package (a folder, a `.zip`, `.xpi` or `.crx`) for the prompt; refused when WebKit cannot load it.
    package static func read(_ source: URL) async throws -> Candidate {
        let loaded = try await WKWebExtension(resourceBaseURL: loadable(source))
        return Candidate(
            source: source,
            name: loaded.displayName ?? source.deletingPathExtension().lastPathComponent,
            version: loaded.displayVersion ?? loaded.version ?? "",
            summary: loaded.displayDescription ?? "",
            permissions: loaded.requestedPermissions.map(\.rawValue).sorted(),
            sites: loaded.requestedPermissionMatchPatterns.map(\.string).sorted(),
            icon: loaded.icon(for: CGSize(width: 64, height: 64))
        )
    }

    /// Installs what was read, granted all it asks (the person said yes to the prompt), and runs it.
    @discardableResult
    package func install(_ candidate: Candidate) async throws -> ExtensionStore.Installed {
        let entry = try store.install(
            from: candidate.source,
            name: candidate.name,
            granted: candidate.permissions + candidate.sites
        )
        await load(entry)
        return entry
    }

    package func set(_ id: UUID, enabled: Bool) {
        store.set(id, enabled: enabled)
        guard let entry = store.installed.first(where: { $0.id == id }) else { return }
        if enabled {
            runtime.task { @MainActor [weak self] in await self?.load(entry) }
        } else {
            unload(id)
        }
    }

    package func set(_ id: UUID, inPrivate: Bool) {
        store.set(id, inPrivate: inPrivate)
        contexts[id]?.hasAccessToPrivateData = inPrivate
    }

    /// The windows WebKit was told of, and the one in front.
    @ObservationIgnored private var known: [ObjectIdentifier: ExtensionWindow] = [:]
    @ObservationIgnored private weak var front: ExtensionWindow?

    func sync(_ windows: [ExtensionWindow], focused: ExtensionWindow?) {
        let now = Dictionary(windows.map { (ObjectIdentifier($0), $0) }, uniquingKeysWith: { first, _ in first })
        for (id, window) in known where now[id] == nil { controller.didCloseWindow(window) }
        for (id, window) in now where known[id] == nil { controller.didOpenWindow(window) }
        known = now
        let focus = focused.flatMap { now[ObjectIdentifier($0)] }
        if focus !== front {
            controller.didFocusWindow(focus)
            front = focus
        }
    }

    /// Moves an extension in the order (Settings' list, a button's menu).
    package func moveEntry(_ id: UUID, by offset: Int) {
        store.move(id, by: offset)
    }

    package func moveEntry(_ id: UUID, to index: Int) {
        store.move(id, to: index)
    }

    package func remove(_ id: UUID) {
        unload(id)
        store.remove(id)
    }

    private func load(_ entry: ExtensionStore.Installed) async {
        guard contexts[entry.id] == nil,
            let loaded = try? await WKWebExtension(resourceBaseURL: store.file(of: entry))
        else { return }
        let context = WKWebExtensionContext(for: loaded)
        Self.grant(entry.granted, in: context, asked: loaded)
        context.hasAccessToPrivateData = entry.inPrivate
        guard (try? controller.load(context)) != nil else { return }
        contexts[entry.id] = context
    }

    func context(of id: UUID) -> WKWebExtensionContext? {
        contexts[id]
    }

    func contextWith(identifier: String) -> WKWebExtensionContext? {
        contexts.values.first { $0.uniqueIdentifier == identifier }
    }

    private func unload(_ id: UUID) {
        guard let context = contexts.removeValue(forKey: id) else { return }
        try? controller.unload(context)
    }

    /// A package WebKit loads as it is: a folder or a zip; a `.crx` is turned into its zip, beside it in the temporary folder.
    static func loadable(_ source: URL) throws -> URL {
        var isFolder: ObjCBool = false
        if FileManager.default.fileExists(atPath: source.path, isDirectory: &isFolder), isFolder.boolValue {
            return source
        }
        let zip = try ExtensionPackage.zip(from: Data(contentsOf: source))
        let file = URL(filePath: NSTemporaryDirectory()).appending(path: "sunset-ext-\(UUID().uuidString).zip")
        try zip.write(to: file)
        return file
    }

    /// What was granted at install, each as the manifest named it: API permissions, and site patterns. Nothing else.
    static func grant(_ granted: [String], in context: WKWebExtensionContext, asked loaded: WKWebExtension) {
        for permission in loaded.requestedPermissions where granted.contains(permission.rawValue) {
            context.setPermissionStatus(.grantedExplicitly, for: permission)
        }
        for pattern in loaded.requestedPermissionMatchPatterns where granted.contains(pattern.string) {
            context.setPermissionStatus(.grantedExplicitly, for: pattern)
        }
    }
}
