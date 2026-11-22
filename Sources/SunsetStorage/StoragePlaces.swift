import Foundation

/// Where each thing Sunset keeps is: one folder, and the names in it. The only place that knows.
///
/// `$SUNSET_SESSION` names the session's file itself and puts everything else beside it; else `$SUNSET_CONFIG` (a test, a second
/// setup) puts everything beside that file, so that it never touches the person's own; else
/// `~/Library/Application Support/Sunset`. Empty variables count as unset.
///
/// A development build (a bundle identifier that ends in `.dev`: every debug build) is another app than the installed one:
/// started with nothing named it keeps `~/Library/Application Support/Sunset Dev` and keys of its own in the Keychain, so it
/// never reads or writes the person's session and never asks for his keys.
public struct StoragePlaces: Sendable, Equatable {
    public let directory: String
    /// The open tabs, the folders and the Favorites: one file, sealed, read whole.
    public let session: String
    /// The session's file of before sealing (`session.json`, plain), read once when there is no sealed one; nil for a setup
    /// that names its session file, which is read whichever it is and written sealed.
    public let legacySession: String?
    /// The person's own setup, not one named by a variable (a test, a second setup).
    public let isDefault: Bool
    /// Not the installed build: its bundle identifier ends in `.dev`.
    public let isDevelopment: Bool
    /// Another app than the person's: `lab` for `studio.aemi.sunset.lab`; nil for his and a development build.
    public let variant: String?
    /// A build that shares Sunset's data: the variant it was before, whose places are merged once.
    let formerVariant: String?
    private let home: String

    /// The builds that keep Sunset's own data rather than their own: Sunset WebKit.
    static let sharing: Set<String> = ["webkit"]

    /// The variant a bundle identifier names: what follows `studio.aemi.sunset.`, but `dev` and the builds that share
    /// Sunset's data.
    public static func variant(of identifier: String?) -> String? {
        named(identifier).flatMap { sharing.contains($0) ? nil : $0 }
    }

    /// The other builds that keep the store `identifier` keeps: only one of them may have it open.
    public static func sharers(of identifier: String?) -> [String] {
        let root = "studio.aemi.sunset"
        let all = [root] + sharing.sorted().map { root + "." + $0 }
        guard let identifier, all.contains(identifier) else { return [] }
        return all.filter { $0 != identifier }
    }

    /// What follows `studio.aemi.sunset.`, but `dev`.
    private static func named(_ identifier: String?) -> String? {
        let root = "studio.aemi.sunset."
        guard let identifier, identifier.hasPrefix(root) else { return nil }
        let name = String(identifier.dropFirst(root.count))
        return name.isEmpty || name == "dev" || name.contains(".") ? nil : name
    }

    /// - Parameters:
    ///   - environment: the process's variables.
    ///   - home: the home folder.
    ///   - identifier: the bundle identifier of the app that runs, when there is one.
    public init(environment: [String: String], home: String, identifier: String? = nil) {
        self.init(environment: environment, home: home, identifier: identifier, variant: Self.variant(of: identifier))
    }

    private init(environment: [String: String], home: String, identifier: String?, variant: String?) {
        isDevelopment = identifier?.hasSuffix(".dev") ?? false
        self.variant = variant
        self.home = home
        formerVariant = Self.named(identifier).flatMap { Self.sharing.contains($0) ? $0 : nil }
        if let file = environment["SUNSET_SESSION"], !file.isEmpty {
            session = file
            legacySession = nil
            directory = Self.folder(of: file)
            isDefault = false
            return
        }
        if let config = environment["SUNSET_CONFIG"], !config.isEmpty {
            directory = Self.folder(of: config)
            isDefault = false
        } else {
            var base = home
            while base.count > 1, base.hasSuffix("/") { base.removeLast() }
            let name = variant.map { "Sunset " + $0.prefix(1).uppercased() + $0.dropFirst() }
            directory = base + "/Library/Application Support/" + (name ?? (isDevelopment ? "Sunset Dev" : "Sunset"))
            isDefault = true
        }
        session = directory + "/session.sealed"
        legacySession = directory + "/session.json"
    }

    /// Where this build kept its data before it shared Sunset's, to be merged once; nil for every other build.
    public var former: StoragePlaces? {
        guard let formerVariant, isDefault else { return nil }
        return StoragePlaces(environment: [:], home: home, identifier: nil, variant: formerVariant)
    }

    /// The same setup in another folder: a copy of its store opened there, not the store itself. Its key is where it was (the
    /// Keychain), or the copy's file for a named setup.
    package func moved(to folder: String) -> StoragePlaces {
        StoragePlaces(self, directory: folder)
    }

    private init(_ other: StoragePlaces, directory: String) {
        self.directory = directory
        session = directory + "/" + (other.session as NSString).lastPathComponent
        legacySession = other.legacySession.map { directory + "/" + ($0 as NSString).lastPathComponent }
        isDefault = other.isDefault
        isDevelopment = other.isDevelopment
        variant = other.variant
        formerVariant = nil
        home = other.home
    }

    /// The places of this run.
    public static let current = StoragePlaces(
        environment: ProcessInfo.processInfo.environment,
        home: NSHomeDirectory(),
        identifier: Bundle.main.bundleIdentifier
    )

    /// The small records: page history, site zoom, site permissions, downloads (ST-3).
    public var state: String {
        directory + "/state.sqlite"
    }
    /// The documents, one file each (ST-4).
    public var documents: String {
        directory + "/Documents"
    }
    /// The extensions installed, a folder per profile.
    public var extensions: String {
        directory + "/Extensions"
    }
    /// What the library shows of the documents; rebuilt from them (ST-4).
    public var library: String {
        directory + "/library.sqlite"
    }

    /// Where the key that seals all this is kept: for the person's own setup, the data-protection keychain, the key wrapped by
    /// this Mac's Secure Enclave, moved there from the login Keychain, where it stays for a build that cannot use the new
    /// place; a file beside the others for a named one, which must not touch the Keychain.
    public var keyVault: any KeyVault {
        guard isDefault else { return FileKeyVault(path: directory + "/storage.key") }
        return MovingKeyVault(
            new: EnclaveKeyVault(backing: KeychainKeyVault(service: keyService + ".enclave", dataProtection: true)),
            old: KeychainKeyVault(service: keyService)
        )
    }

    /// The Keychain item of the key that seals the store: a development build has its own.
    public var keyService: String {
        serviceRoot + ".storage-key"
    }
    /// The Keychain item of the key that seals the commands of kept terminals: a development build has its own.
    public var commandSealService: String {
        serviceRoot + ".command-seal"
    }
    /// Where that key is for a named setup, which must not touch the Keychain.
    public var commandSealFile: String {
        directory + "/command-seal.key"
    }

    private var serviceRoot: String {
        variant.map { "studio.aemi.sunset." + $0 } ?? (isDevelopment ? "studio.aemi.sunset.dev" : "studio.aemi.sunset")
    }

    // The files of before the database, imported once by ST-3.
    public var legacyZoom: String {
        directory + "/site-zoom.json"
    }
    public var legacyHistory: String {
        directory + "/history.sqlite"
    }
    public var legacyDownloads: String {
        directory + "/downloads.json"
    }
    public var legacyPermissions: String {
        directory + "/site-permissions.json"
    }

    private static func folder(of path: String) -> String {
        path.lastIndex(of: "/").map { String(path[..<$0]) } ?? "."
    }
}
