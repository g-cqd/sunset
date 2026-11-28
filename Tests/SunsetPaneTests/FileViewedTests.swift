import Testing

@testable import SunsetPane

/// A file only looked at (a PDF, a picture, a sound or a film) opens in its viewer, the rest as a document; both are the
/// documents' scope, and either is found again by its file.
@Suite("Files only looked at")
struct FileViewedTests {
    @Test func `PDFs, pictures, sounds and films open in a viewer; anything else as a document`() {
        #expect(PaneDescriptor.forFile("/a/b.pdf").kind == PaneDescriptor.fileViewKind)
        for name in ["c.PNG", "d.jpeg", "e.gif", "f.heic", "g.mp4", "h.mov", "i.mp3", "j.m4a"] {
            #expect(PaneDescriptor.isViewed(path: "/x/" + name), "\(name)")
        }
        for name in ["a.md", "b.html", "c.txt", "pdf", ".png"] {
            #expect(PaneDescriptor.forFile("/x/" + name).kind == PaneDescriptor.documentKind, "\(name)")
        }
        #expect(FileViewed(extension: "pdf") == .pdf && FileViewed(extension: "webp") == .picture)
        #expect(FileViewed(extension: "wav") == .media && FileViewed(extension: "zip") == nil)
    }

    @Test func `a viewer is found by its file, and is the documents': off with them`() {
        let viewer = PaneDescriptor.forFile("/x/report.pdf")
        #expect(viewer.documentFile == "/x/report.pdf" && viewer.searchTerms.contains("report.pdf"))
        #expect(Scopes().allows(viewer))
        #expect(!Scopes(documents: false).allows(viewer))
        #expect(Scopes(documents: false).allows(PaneDescriptor.terminal(directory: nil)))
    }
}
