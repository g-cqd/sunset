import Testing

@testable import SunsetWeb

@Suite("Names and kinds of downloaded files") struct DownloadNamingTests {
    @Test func `a taken name gets -2, then -3, before its extension; a partial file counts as taken`() {
        let taken: Set = ["a.zip", "a-2.zip.download", "notes"]
        #expect(DownloadNaming.free("a.zip") { taken.contains($0) } == "a-3.zip")
        #expect(DownloadNaming.free("notes") { taken.contains($0) } == "notes-2")
        #expect(DownloadNaming.free("b.pdf") { taken.contains($0) } == "b.pdf")
        // Finishing: its own partial file is not another download's.
        #expect(DownloadNaming.free("c.zip", ownPartial: true) { $0 == "c.zip.download" } == "c.zip")
    }

    @Test func `a suggested name cannot leave the folder or hide`() {
        #expect(DownloadNaming.cleaned("../../etc/passwd") == "-..-etc-passwd")
        #expect(DownloadNaming.cleaned(".hidden") == "hidden" && DownloadNaming.cleaned("  ") == "download")
    }

    @Test func `apps, installers and scripts need an approval, disk images do not; pictures and PDF are safe`() {
        #expect(DownloadNaming.isSuspicious("Tool.pkg") && DownloadNaming.isSuspicious("run.COMMAND"))
        #expect(!DownloadNaming.isSuspicious("App.dmg") && !DownloadNaming.isSuspicious("README"))
        #expect(DownloadNaming.isSafe("a.PDF") && !DownloadNaming.isSafe("a.zip"))
    }
}
