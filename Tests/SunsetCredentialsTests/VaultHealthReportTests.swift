import Testing

@testable import SunsetCredentials

/// Password Health looks at passwords only (roadmap 0092 F): a card's security code or PIN, a licence key or an API
/// secret is hidden but is not a password, and is neither weak nor reused for this report.
@Suite("Password Health: what counts as a password") struct VaultHealthReportTests {
    private func entry(_ template: EntryTemplate, _ values: [String: String]) throws -> VaultEntry {
        var made = template.makeEntry(title: template.name)
        for (name, value) in values {
            made.set(try #require(made.field(named: name)?.id), value)
        }
        return made
    }

    @Test func `cards, PINs and keys are not counted; logins', servers' and Wi-Fi passwords are`() throws {
        let cardA = try entry(.card, ["Security Code": "123", "PIN": "0000"])
        let cardB = try entry(.card, ["Security Code": "123", "PIN": "0000"])
        let bank = try entry(EntryTemplate.shipped[7], ["PIN": "0000"])
        let login = try entry(.login, ["Password": "short"])
        let server = try entry(.server, ["Password": "short"])
        let wifi = try entry(EntryTemplate.shipped[6], ["Password": "Corr3ct-Horse-Battery-Staple"])
        let report = VaultHealthReport.analyze([cardA, cardB, bank, login, server, wifi])
        #expect(EntryTemplate.shipped[6].name == "Wi-Fi" && EntryTemplate.shipped[7].name == "Bank Account")
        #expect(report.totalPasswords == 3)
        #expect(Set(report.weak.map(\.entryID)) == [login.id, server.id])
        #expect(Set(report.reused.map(\.entryID)) == [login.id, server.id])
    }
}
