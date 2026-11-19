import Foundation
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Which section each sidebar shows (roadmap 0031).
@Suite("The sections of the sidebars") struct SidebarSectionsTests {
    @Test func `the opposite panel has History, Documents and Downloads; the Library's rail has Tabs first`() {
        #expect(SidebarSection.panel == [.history, .documents, .downloads])
        #expect(SidebarSection.rail == [.tabs, .documents, .history, .downloads])
        #expect(SidebarSection.allCases.allSatisfy { !$0.title.isEmpty && !$0.symbol.isEmpty })
    }

    @Test func `the Library opens on the section it last showed, and Tabs, the glyph again and closing all go back`() {
        var sections = SidebarSections()
        #expect(!sections.isLibraryOpen && sections.library == .tabs && sections.opposite == .history)
        sections.toggleLibrary()
        #expect(sections.isLibraryOpen && sections.library == .documents, "documents the first time")
        sections.show(library: .downloads)
        sections.toggleLibrary()
        #expect(!sections.isLibraryOpen)
        sections.toggleLibrary()
        #expect(sections.library == .downloads, "where it was")
        sections.show(library: .tabs)
        #expect(!sections.isLibraryOpen)
        sections.show(library: .history)
        sections.closeLibrary()
        #expect(!sections.isLibraryOpen)
        sections.toggleLibrary()
        #expect(sections.library == .history)
    }

    @Test func `each sidebar is on its own section`() {
        var sections = SidebarSections()
        sections.show(library: .history)
        sections.opposite = .documents
        #expect(sections.library == .history && sections.opposite == .documents)
        sections.opposite = .tabs
        #expect(sections.opposite == .documents, "Tabs is not a section of the opposite panel")
    }
}
