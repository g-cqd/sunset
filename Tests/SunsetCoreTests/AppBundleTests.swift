import Foundation
import SunsetTestSupport
import Testing

/// What the app says of itself to the Mac (`App/Info.plist`). R6, roadmap 0023 step M-f: Sunset can be chosen to open
/// Markdown, Mermaid and text files (Open With, or "Always Open With"), and never makes itself the app that opens them: that
/// is the person's choice (ADR-0040).
@Suite("The app's Info.plist")
struct AppBundleTests {
    private func plist() throws -> [String: Any] {
        let data = try Data(contentsOf: RepositoryFiles.root.appending(path: "App/Info.plist"))
        let read = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try #require(read as? [String: Any])
    }

    @Test func `Markdown, Mermaid and text can be opened with Sunset, which is never their default`() throws {
        let types = try #require(try plist()["CFBundleDocumentTypes"] as? [[String: Any]])
        let content = types.flatMap { $0["LSItemContentTypes"] as? [String] ?? [] }
        #expect(content.contains("net.daringfireball.markdown") && content.contains("public.plain-text"))
        #expect(content.contains("studio.aemi.sunset.mermaid"))
        #expect(types.allSatisfy { $0["LSHandlerRank"] as? String == "Alternate" })
        #expect(types.allSatisfy { $0["CFBundleTypeRole"] as? String == "Editor" })
    }

    @Test func `a Mermaid file is known by its extensions, as text`() throws {
        let imported = try #require(try plist()["UTImportedTypeDeclarations"] as? [[String: Any]])
        let mermaid = try #require(imported.first { $0["UTTypeIdentifier"] as? String == "studio.aemi.sunset.mermaid" })
        #expect(mermaid["UTTypeConformsTo"] as? [String] == ["public.plain-text"])
        let tags = try #require(mermaid["UTTypeTagSpecification"] as? [String: Any])
        #expect(tags["public.filename-extension"] as? [String] == ["mmd", "mermaid"])
    }

    /// Roadmap 0084: the app's icon is the Icon Composer bundle `App/Sunset.icon` (light, dark, tinted), compiled by Xcode
    /// into the asset catalog and into `Sunset.icns` for `CFBundleIconFile`; Twilight, Dawn and Dusk go in as alternates.
    @Test func `the icon is Sunset.icon, with Twilight, Dawn and Dusk as alternates`() throws {
        let project = try String(contentsOf: RepositoryFiles.root.appending(path: "project.yml"), encoding: .utf8)
        #expect(project.contains("ASSETCATALOG_COMPILER_APPICON_NAME: Sunset"))
        #expect(project.contains("ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES: Twilight Dawn Dusk"))
        #expect(try plist()["CFBundleIconFile"] as? String == "Sunset")
        let files = FileManager.default
        for name in ["Sunset", "Twilight", "Dawn", "Dusk"] {
            let icon = RepositoryFiles.root.appending(path: "App/\(name).icon")
            #expect(files.fileExists(atPath: icon.appending(path: "icon.json").path), "\(name).icon")
            for suffix in ["", "-dark", "-tinted"] {
                let image = icon.appending(path: "Assets/\(name.lowercased())\(suffix).png")
                #expect(files.fileExists(atPath: image.path), "\(image.lastPathComponent)")
            }
        }
        // The icns is made by Xcode from Sunset.icon: a hand-made one beside it would be a second file of the same name.
        #expect(!files.fileExists(atPath: RepositoryFiles.root.appending(path: "App/Sunset.icns").path))
    }

    /// t276: a debug build is another app to the Mac than the installed one (its own defaults, saved state, permissions and
    /// Open With entry), named so that the two are told apart.
    @Test func `a debug build has an identity and a name of its own`() throws {
        let project = try String(contentsOf: RepositoryFiles.root.appending(path: "project.yml"), encoding: .utf8)
        #expect(project.contains("PRODUCT_BUNDLE_IDENTIFIER: studio.aemi.sunset.dev"))
        #expect(project.contains("SUNSET_DISPLAY_NAME: Sunset Dev"))
        #expect(try plist()["CFBundleDisplayName"] as? String == "$(SUNSET_DISPLAY_NAME)")
    }
}
