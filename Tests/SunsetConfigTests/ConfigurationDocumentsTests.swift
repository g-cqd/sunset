import Testing

@testable import SunsetConfig

/// `documents.saveAfter` and `documents.saveOnFocusLoss` (R6, roadmap 0023 step M-d): a file is written by itself only when
/// one of them says so, and neither does by default.
@Suite("Configuration: documents") struct ConfigurationDocumentsTests {
    @Test func `a file is not saved by itself unless the file says when`() throws {
        let plain = try ConfigurationParser.parse("{}").configuration.documents
        #expect(plain.saveAfter == 0 && !plain.saveOnFocusLoss)
        let result = try ConfigurationParser.parse(#"{ "documents": { "saveAfter": 30, "saveOnFocusLoss": true } }"#)
        #expect(result.issues.isEmpty)
        #expect(result.configuration.documents.saveAfter == 30 && result.configuration.documents.saveOnFocusLoss)
        let wrong = try ConfigurationParser.parse(
            #"{ "documents": { "saveAfter": -1, "saveOnFocusLoss": "yes", "other": 1 } }"#
        )
        #expect(
            wrong.issues.map(\.path).sorted() == ["documents.other", "documents.saveAfter", "documents.saveOnFocusLoss"]
        )
        #expect(wrong.configuration.documents == Configuration.Documents())
    }

    @Test func `what is written reads back, and Settings have both under General`() throws {
        var configuration = Configuration()
        configuration.documents.saveAfter = 5
        configuration.documents.saveOnFocusLoss = true
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && back.configuration.documents == configuration.documents)
        #expect(
            SettingsSection.topic("general.documents")?.topic.options.map(\.id) == [
                "documents.saveAfter", "documents.saveOnFocusLoss"
            ]
        )
        #expect(SettingsSection.all.first?.topics.map(\.id) == ["general.startup", "general.documents", "general.file"])
    }
}
