import Testing

@testable import SunsetConfig

/// `storage.importedFiles` (R12, the owner on 2026-11-15: a setting, the Trash by default).
@Suite("Configuration: storage") struct ConfigurationStorageTests {
    @Test func `the plain files of before go to the Trash unless the file says they are deleted`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.storage.importedFiles == .trash)
        let result = try ConfigurationParser.parse(#"{ "storage": { "importedFiles": "delete" } }"#)
        #expect(result.issues.isEmpty && result.configuration.storage.importedFiles == .delete)
        let wrong = try ConfigurationParser.parse(#"{ "storage": { "importedFiles": "keep", "other": 1 } }"#)
        #expect(wrong.issues.map(\.path).sorted() == ["storage.importedFiles", "storage.other"])
        #expect(wrong.configuration.storage.importedFiles == .trash)
    }

    @Test func `what is written reads back, and Settings have it under Privacy and security`() throws {
        var configuration = Configuration()
        configuration.storage.importedFiles = .delete
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && back.configuration.storage == configuration.storage)
        #expect(
            SettingsSection.all.last?.topics.map(\.title) == [
                "Programs in a terminal", "Browsing", "What is kept", "Key and recovery", "Export"
            ]
        )
        #expect(
            SettingsSection.topic("privacy.export")?.topic.options.map(\.id) == [
                "storage.export", "storage.importedFiles"
            ]
        )
        #expect(
            SettingsSection.topic("privacy.kept")?.topic.options.map(\.id) == [
                "storage.sealed", "storage.websiteData", "storage.setAside"
            ]
        )
        #expect(SettingsSection.topic("privacy.key")?.topic.options.map(\.id) == ["storage.key", "storage.enterCode"])
    }
}
