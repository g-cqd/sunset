import Foundation
import Testing

/// The owner's note n11: a click, or a drop, that is blocked says so. Every drop a view performs answers through
/// `Feedback.dropped(_:)`, which taps the trackpad and tells VoiceOver when the drop was refused.
@Suite("A refused drop says so") struct DropFeedbackGateTests {
    @Test func `every performDrop answers through Feedback.dropped`() {
        var silent: [String] = []
        for file in RepositoryFiles.swiftFiles(in: ["Sources"]) {
            let parts = file.text.components(separatedBy: "func performDrop(info: DropInfo) -> Bool {").dropFirst()
            for part in parts {
                // The body: up to the first line that closes it at the function's indentation.
                let body = part.components(separatedBy: "\n    }\n").first ?? part
                if !body.contains("Feedback.dropped(") { silent.append(file.name) }
            }
        }
        #expect(silent.isEmpty, "\(silent)")
    }
}
