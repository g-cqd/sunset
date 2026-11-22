import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The sections of the sidebars when a scope of the app is off: History and Downloads are the web's, Documents is the
/// documents'.
@Suite("The sidebars' sections and the scopes that are off")
struct SectionScopesTests {
    @Test func `a section of a scope that is off is not listed; the downloads stay when documents are off`() {
        #expect(SidebarSection.rail(for: Scopes()) == SidebarSection.rail.filter { $0 != .passwords })
        #expect(SidebarSection.rail(for: Scopes(documents: false)) == [.tabs, .history, .downloads])
        #expect(SidebarSection.rail(for: Scopes(web: false)) == [.tabs, .documents])
        #expect(SidebarSection.panel(for: Scopes(web: false)) == [.documents])
        #expect(SidebarSection.panel(for: Scopes(web: false, documents: false)).isEmpty)
        #expect(SidebarSection.rail(for: Scopes(web: false, documents: false)) == [.tabs], "nothing for a Library")
    }

    @Test func `Passwords is in the Library only while the vault is turned on; never in the panel opposite the tabs`() {
        var scopes = Scopes()
        #expect(!SidebarSection.rail(for: scopes).contains(.passwords), "off by default")
        scopes.passwords = true
        #expect(SidebarSection.rail(for: scopes) == [.tabs, .documents, .history, .downloads, .passwords])
        #expect(!SidebarSection.panel(for: scopes).contains(.passwords))
        #expect(SidebarSection.rail(for: Scopes(web: false, documents: false, passwords: true)) == [.tabs, .passwords])
        #expect(SidebarSection.passwords.title == "Passwords" && SidebarSection.passwords.symbol == "key")
    }

    @Test func `a sidebar on a section that goes off goes to one that is on; the Library with none closes`() {
        var sections = SidebarSections()
        sections.show(library: .history)
        sections.opposite = .downloads
        sections.settle(for: Scopes(web: false))
        #expect(sections.library == .tabs && sections.opposite == .documents)
        sections.toggleLibrary()
        #expect(sections.library == .documents, "what the glyph opens is a section that is on")
        sections.settle(for: Scopes(web: false, documents: false))
        #expect(sections.library == .tabs)
        sections.toggleLibrary()
        #expect(!sections.isLibraryOpen, "nothing to open")
        sections.settle(for: Scopes())
        sections.toggleLibrary()
        #expect(sections.isLibraryOpen)
    }
}
