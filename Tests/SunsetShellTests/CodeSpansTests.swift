import Foundation
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner's note n26: in a sentence, the host or the address is code, the words are not.
@Suite("A host in a sentence") struct CodeSpansTests {
    @Test func `the host is code, every time it is there, and nothing else`() {
        let text = Text.codeSpans("meet.example wants to use your camera; meet.example asked before.", ["meet.example"])
        let code = text.runs.filter { $0.inlinePresentationIntent == .code }.map { String(text[$0.range].characters) }
        #expect(code == ["meet.example", "meet.example"])
        #expect(Text.codeSpans("This page says", [""]).runs.allSatisfy { $0.inlinePresentationIntent == nil })
    }
}
