import Foundation
import Testing

@testable import SunsetCredentials

/// What the person is told when a file cannot be read: each reason has its own words, and an encrypted export says what to do about it.
@Suite("Importing: saying why a file was refused")
struct ImportFailureWordsTests {
    @Test func `each reason has a title and a detail of its own`() {
        let all: [LoginImport.Failure] = [.noLoginColumns, .notAnExport, .encrypted]
        let titles = all.map(\.words.title)
        #expect(Set(titles).count == all.count && titles.allSatisfy { !$0.isEmpty })
        #expect(all.allSatisfy { !$0.words.detail.isEmpty })
    }

    @Test func `an encrypted export says to export it again unencrypted`() {
        let words = LoginImport.Failure.encrypted.words
        #expect(words.detail.contains("Bitwarden") && words.detail.localizedCaseInsensitiveContains("unencrypted"))
    }
}
