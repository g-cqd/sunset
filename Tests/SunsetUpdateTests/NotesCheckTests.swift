import Foundation
import SunsetUpdate
import Testing

/// The update window shows a release's notes only as its signed index has them (ADR-0125): a hijacked account cannot put
/// words in Sunset's mouth. Releases from before signed indexes say so.
struct NotesCheckTests {
    static func index(notes: String) -> ReleaseIndex {
        ReleaseIndex(tag: "v1", build: 9, notesSHA256: BundleManifest.hex(Data(notes.utf8)), variants: [])
    }

    @Test func notesMatchTheirIndexOrAreWithheld() {
        #expect(
            NotesCheck.of(notes: "Fixed things.\n", index: Self.index(notes: "Fixed things.\n"), build: 9) == .verified
        )
        #expect(
            NotesCheck.of(notes: "Fixed things!\n", index: Self.index(notes: "Fixed things.\n"), build: 9) == .mismatch
        )
        #expect(NotesCheck.of(notes: "Anything", index: nil, build: 825) == .unsigned)
        #expect(
            NotesCheck.of(notes: "Anything", index: nil, build: 829) == .mismatch,
            "signed since alpha.13: an index removed"
        )
        #expect(
            NotesCheck.mismatch.showsNotes == false && NotesCheck.verified.showsNotes && NotesCheck.unsigned.showsNotes
        )
    }
}
