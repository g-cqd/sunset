import Foundation
import SunsetUpdate
import Testing

/// What the update centre says when an update or an engine switch is refused: a sentence, not a type's name.
struct UpdateFailureTextTests {
    @Test func everyRefusalReadsAsASentence() {
        let failures: [any Error] = [
            ReleaseIndex.Failure.untrustedSignature, ReleaseIndex.Failure.malformed,
            DeltaArchive.Failure.hashMismatch, DeltaArchive.Failure.unsafeLink("Contents/x"),
            BoundedLZMA.Failure.outputLimitExceeded, BinaryDelta.Failure.otherOldFile,
            SignatureCheck.Failure.refused(-67050), SignatureCheck.Failure.notLater(running: 9, staged: 8)
        ]
        for failure in failures {
            let text = failure.localizedDescription
            #expect(!text.contains("SunsetUpdate."), "\(text)")
            #expect(!text.contains("operation couldn"), "\(text)")
        }
        #expect(ReleaseIndex.Failure.untrustedSignature.localizedDescription.contains("signed"))
    }
}
