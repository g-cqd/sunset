import Foundation
import SunsetImport

/// The reading part of an import, off the main thread: a browser's folder can be large (a Firefox history database is
/// copied to be read).
enum ImportRun {
    /// What one source gives: a browser's profile, or an exported file.
    enum Source: Equatable {
        case profile(Browser, BrowserProfile)
        case file(URL)
    }

    static var home: String {
        FileManager.default.homeDirectoryForCurrentUser.path
    }

    static func browsers() -> [Browser] {
        BrowserCatalog.installed(home: home) { FileManager.default.fileExists(atPath: $0) }
    }

    @concurrent static func profiles(of browser: Browser) async throws -> [BrowserProfile] {
        try BrowserImport.profiles(of: browser, home: home)
    }

    @concurrent static func read(_ source: Source) async throws -> ImportedProfile {
        switch source {
            case .profile(let browser, let profile):
                return try BrowserImport.read(profile, of: browser, home: home)
            case .file(let url):
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                guard let data = try BrowserImport.contents(url.path) else {
                    throw BrowserImport.Failure.unreadable(url.path)
                }
                return ImportedProfile(bookmarks: NetscapeBookmarks.read(String(decoding: data, as: UTF8.self)))
        }
    }

    /// The name of the folder the bookmarks go in, and of a Space made for them.
    static func names(_ source: Source) -> (folder: String, space: String) {
        switch source {
            case .profile(let browser, let profile):
                let named = profile.name == browser.name ? browser.name : "\(browser.name) (\(profile.name))"
                return (named, browser.name)
            case .file(let url):
                let name = url.deletingPathExtension().lastPathComponent
                return (name, "Imported")
        }
    }
}
