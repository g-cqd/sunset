import Foundation
import SunsetRuntime
import SunsetWebModel
package import WebKit

/// One profile's extensions running (roadmap 0109 B, ADR-0109): WebKit's controller, persistent and the profile's own, holding
/// each extension installed and on, granted what the person granted at install; in private pages only where allowed.
@MainActor package final class ExtensionHost {
    package let controller: WKWebExtensionController
    private let store: ExtensionStore
    private var loading: Task<Void, Never>?

    init(root: URL, profile: UUID?, runtime: Runtime = .live) {
        store = ExtensionStore(root: root, profile: profile)
        // A profile's own storage for its extensions; the default profile's is WebKit's default.
        let configuration =
            profile.map { WKWebExtensionController.Configuration(identifier: $0) } ?? .default()
        controller = WKWebExtensionController(configuration: configuration)
        loading = runtime.task { @MainActor [store, controller] in
            for entry in store.installed where entry.enabled {
                guard let loaded = try? await WKWebExtension(resourceBaseURL: store.file(of: entry)) else { continue }
                let context = WKWebExtensionContext(for: loaded)
                Self.grant(entry.granted, in: context, asked: loaded)
                context.hasAccessToPrivateData = entry.inPrivate
                try? controller.load(context)
            }
        }
    }

    /// Done loading what is installed.
    package func ready() async {
        await loading?.value
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
