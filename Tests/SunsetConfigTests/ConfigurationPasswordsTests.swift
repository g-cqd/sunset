import Testing

@testable import SunsetConfig

/// `passwords.*` (the owner, 2026-11-23): the vault locks after a time without use, and, when asked, on leaving its tab
/// for another of the window, or when its window is no longer the one in front; a sign-in form is filled on load only when
/// asked (ADR-0094).
@Suite("Configuration: passwords") struct ConfigurationPasswordsTests {
    @Test
    func `ten minutes without use, and neither on leaving the tab nor the window, unless the file says otherwise`()
        throws
    {
        let plain = try ConfigurationParser.parse("{}").configuration.passwords
        #expect(plain.lockAfter == 10 && !plain.lockOnLeavingTab && !plain.lockOnWindowBlur)
        #expect(plain.backupFolder.isEmpty && plain.backupKeep == 10 && !plain.autoFill)
        let result = try ConfigurationParser.parse(
            #"{ "passwords": { "lockAfter": 0, "lockOnLeavingTab": true, "lockOnWindowBlur": true, "autoFill": true, "backupFolder": "/tmp/backups", "backupKeep": 5 } }"#
        )
        #expect(result.issues.isEmpty)
        let read = result.configuration.passwords
        #expect(read.lockAfter == 0 && read.lockOnLeavingTab && read.lockOnWindowBlur)
        #expect(read.backupFolder == "/tmp/backups" && read.backupKeep == 5 && read.autoFill)
        let wrong = try ConfigurationParser.parse(#"{ "passwords": { "lockAfter": -3, "backupKeep": 0, "other": 1 } }"#)
        #expect(wrong.issues.map(\.path).sorted() == ["passwords.backupKeep", "passwords.lockAfter", "passwords.other"])
    }

    @Test func `what is written reads back, and Settings have it under Privacy and security`() throws {
        var configuration = Configuration()
        configuration.passwords.lockAfter = 30
        configuration.passwords.lockOnWindowBlur = true
        configuration.passwords.backupFolder = "/tmp/vault-backups"
        configuration.passwords.backupKeep = 7
        configuration.passwords.autoFill = true
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && back.configuration.passwords == configuration.passwords)
        #expect(
            SettingsSection.topic("privacy.passwords")?.topic.options.map(\.id) == [
                "passwords.lockAfter", "passwords.lockOnLeavingTab", "passwords.lockOnWindowBlur",
                "passwords.autoFill", "passwords.backupFolder", "passwords.backupKeep"
            ]
        )
    }
}
