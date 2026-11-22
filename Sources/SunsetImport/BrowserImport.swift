public import Foundation

/// Reads a browser's profiles and what each holds, from its folder.
public enum BrowserImport {
    public enum Failure: Error, Equatable {
        /// macOS refuses the folder or a file in it: Safari's always, another app's data unless the person allows it
        /// (System Settings ▸ Privacy & Security ▸ Full Disk Access).
        case needsAccess(String)
        /// It is there but not as the browser writes it.
        case unreadable(String)
    }

    /// The browser's profiles; one, the folder itself, when it lists none (Opera; Safari).
    public static func profiles(of browser: Browser, home: String) throws -> [BrowserProfile] {
        let root = BrowserCatalog.path(of: browser, home: home)
        let whole = [BrowserProfile(folder: "", name: browser.name)]
        switch browser.kind {
            case .safari:
                return whole
            case .chromium:
                guard let data = try contents(root + "/Local State") else { return whole }
                let listed = try decoded(root + "/Local State") { try ChromiumProfiles.read(data) }
                return listed.isEmpty ? whole : listed
            case .firefox:
                guard let data = try contents(root + "/profiles.ini") else { return [] }
                return FirefoxProfiles.read(String(decoding: data, as: UTF8.self))
        }
    }

    /// What `profile` holds; what is missing is empty.
    public static func read(_ profile: BrowserProfile, of browser: Browser, home: String) throws -> ImportedProfile {
        let root = BrowserCatalog.path(of: browser, home: home)
        let folder =
            profile.folder.hasPrefix("/") ? profile.folder : root + (profile.folder.isEmpty ? "" : "/" + profile.folder)
        switch browser.kind {
            case .safari:
                let file = root + "/Bookmarks.plist"
                guard let data = try contents(file) else { return ImportedProfile() }
                do {
                    return ImportedProfile(bookmarks: try SafariBookmarks.read(data))
                } catch {
                    throw Failure.unreadable(file)
                }
            case .chromium:
                let file = folder + "/Bookmarks"
                let bookmarks =
                    try contents(file).map { data in try decoded(file) { try ChromiumBookmarks.read(data) } } ?? []
                return ImportedProfile(
                    bookmarks: bookmarks,
                    extensions: ChromiumExtensions.read(profile: URL(filePath: folder))
                )
            case .firefox:
                return try firefox(folder)
        }
    }

    private static func firefox(_ folder: String) throws -> ImportedProfile {
        let places = folder + "/places.sqlite"
        var bookmarks: [BookmarkNode] = []
        if try contents(places, readingAll: false) != nil {
            do {
                bookmarks = FirefoxBookmarks.tree(try FirefoxPlaces.rows(of: URL(filePath: places)))
            } catch {
                throw Failure.unreadable(places)
            }
        }
        let extensionsFile = folder + "/extensions.json"
        let extensions =
            try contents(extensionsFile)
            .map { data in try decoded(extensionsFile) { try FirefoxExtensions.read(data) } } ?? []
        let containersFile = folder + "/containers.json"
        let containers =
            try contents(containersFile)
            .map { data in try decoded(containersFile) { try FirefoxContainers.read(data) } } ?? []
        return ImportedProfile(bookmarks: bookmarks, extensions: extensions, containers: containers)
    }

    /// The file's bytes; nil when it does not exist. Throws `needsAccess` when macOS refuses it. With `readingAll` false,
    /// only whether it can be read (an empty `Data`).
    public static func contents(_ path: String, readingAll: Bool = true) throws -> Data? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        do {
            let handle = try FileHandle(forReadingFrom: URL(filePath: path))
            defer { try? handle.close() }
            return readingAll ? try handle.readToEnd() ?? Data() : Data()
        } catch {
            throw refused(error as NSError) ? Failure.needsAccess(path) : Failure.unreadable(path)
        }
    }

    /// Whether macOS refused it: Foundation's "no permission" (read or, opening a handle, write: 257, 513), or the system
    /// call's `EPERM` (privacy protection) or `EACCES` beneath.
    static func refused(_ error: NSError) -> Bool {
        if error.domain == NSPOSIXErrorDomain { return [EPERM, EACCES].contains(Int32(error.code)) }
        if error.domain == NSCocoaErrorDomain,
            [CocoaError.fileReadNoPermission.rawValue, CocoaError.fileWriteNoPermission.rawValue].contains(error.code)
        {
            return true
        }
        return (error.userInfo[NSUnderlyingErrorKey] as? NSError).map(refused) ?? false
    }

    private static func decoded<T>(_ path: String, _ read: () throws -> T) throws -> T {
        do {
            return try read()
        } catch {
            throw Failure.unreadable(path)
        }
    }
}
