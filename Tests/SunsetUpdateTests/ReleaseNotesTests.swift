import SunsetUpdate
import Testing

/// A release's notes as the update window shows them (n135, the owner: the dialog to have the craft of the others):
/// paragraphs and list items of the Markdown our notes are written in, wrapped lines joined, the install instructions
/// that do not apply to an update left out.
struct ReleaseNotesTests {
    @Test func readsParagraphsAndNestedItemsWithTheirWrappedLinesJoined() {
        let notes = """
            Build 786.

            The eleventh alpha, a day after
            alpha.10.

            **What changed.**
            - **Passwords.**
              - Unlocking asks once (it asked
                twice).
            - A click on a menu
              no longer opens a second one.
            """
        #expect(
            ReleaseNotes.blocks(notes) == [
                .paragraph("The eleventh alpha, a day after alpha.10."),
                .paragraph("**What changed.**"),
                .item(level: 0, "**Passwords.**"),
                .item(level: 1, "Unlocking asks once (it asked twice)."),
                .item(level: 0, "A click on a menu no longer opens a second one.")
            ]
        )
    }

    @Test func leavesOutWhatIsAboutInstallingByHandAndTheBuildLine() {
        let notes = """
            Build 9.

            ## Fixes
            * One.

            **Install.** Unzip, move the app to Applications.

            **Check the download.** `shasum -a 256 -c NAME.zip.sha256`.

            Report what breaks.
            """
        #expect(
            ReleaseNotes.blocks(notes) == [
                .heading("Fixes"), .item(level: 0, "One."), .paragraph("Report what breaks.")
            ]
        )
    }

    /// Over several releases, each one's changes, not the footer every release has (`Scripts/release-notes.sh`).
    @Test func stopsAtTheFooterEveryReleaseHas() {
        let notes = """
            Build 990.

            - Light terminal.

            ---

            **Two variants.** Sunset shows pages with the system's WebKit.
            """
        #expect(ReleaseNotes.blocks(notes) == [.item(level: 0, "Light terminal.")])
    }
}
