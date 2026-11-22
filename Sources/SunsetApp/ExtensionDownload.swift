import Foundation
import SunsetWebModel

/// A store's package fetched into the temporary folder: Chrome's from its update service, Firefox's from the `.xpi` its
/// API names. Nothing of the person is sent: no cookie, no identifier (an ephemeral session).
enum ExtensionDownload {
    struct Failed: LocalizedError {
        let errorDescription: String?
    }

    static func fetch(_ link: ExtensionStoreLink) async throws -> URL {
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        var package = link.source
        if case .firefox = link {
            let (data, _) = try await session.data(from: link.source)
            guard let named = ExtensionStoreLink.firefoxPackage(fromAPI: data) else {
                throw Failed(errorDescription: "Firefox Add-ons did not name a package for it.")
            }
            package = named
        }
        return try await save(package, in: session, suffix: link.isFirefox ? "xpi" : "crx")
    }

    /// A package at an address a page offered: HTTPS only.
    static func fetch(package address: URL) async throws -> URL {
        guard address.scheme == "https" else {
            throw Failed(errorDescription: "Only a package over HTTPS is installed.")
        }
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        return try await save(address, in: session, suffix: address.pathExtension.lowercased() == "xpi" ? "xpi" : "crx")
    }

    private static func save(_ package: URL, in session: URLSession, suffix: String) async throws -> URL {
        let (data, response) = try await session.data(from: package)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw Failed(errorDescription: "The store answered with no package for it.")
        }
        let file = URL(filePath: NSTemporaryDirectory()).appending(path: "sunset-store-\(UUID().uuidString).\(suffix)")
        try data.write(to: file)
        return file
    }
}
