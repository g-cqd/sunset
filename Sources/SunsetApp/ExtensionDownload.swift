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

    /// A package at an address a page offered: HTTPS only; `.xpi` packages are accepted only from Mozilla's official
    /// Add-ons host (`addons.mozilla.org`), while `.crx` packages are verified by `CRX3Signature` regardless of host (N-S4).
    static func fetch(package address: URL) async throws -> URL {
        guard address.scheme == "https" else {
            throw Failed(errorDescription: "Only a package over HTTPS is installed.")
        }
        let isXPI = address.pathExtension.lowercased() == "xpi"
        if isXPI, !ExtensionPackage.isTrustedFirefoxDownload(address) {
            throw Failed(errorDescription: "Firefox extensions can only be installed from addons.mozilla.org.")
        }
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        return try await save(address, in: session, suffix: isXPI ? "xpi" : "crx")
    }

    private static func save(_ package: URL, in session: URLSession, suffix: String) async throws -> URL {
        let (data, response) = try await session.data(from: package)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw Failed(errorDescription: "The store answered with no package for it.")
        }
        if suffix == "xpi", let finalURL = http.url, !ExtensionPackage.isTrustedFirefoxDownload(finalURL) {
            throw Failed(errorDescription: "Firefox extension redirected to an untrusted host.")
        }
        if suffix == "crx", !data.starts(with: Data("Cr24".utf8)) {
            throw Failed(errorDescription: "Expected a signed CRX3 extension package.")
        }
        let file = URL(filePath: NSTemporaryDirectory()).appending(path: "sunset-store-\(UUID().uuidString).\(suffix)")
        try data.write(to: file)
        return file
    }
}
