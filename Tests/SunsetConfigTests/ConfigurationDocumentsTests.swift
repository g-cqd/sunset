import Testing

@testable import SunsetConfig

/// `documents.saveAfter` and `documents.saveOnFocusLoss`: when a file is written by itself. By default two seconds
/// after an edit and when it loses focus; the file can say never.
@Suite("Configuration: documents") struct ConfigurationDocumentsTests {
    @Test
    func `a file is saved by itself two seconds after an edit and on losing focus, unless the file says otherwise`()
        throws
    {
        let plain = try ConfigurationParser.parse("{}").configuration.documents
        #expect(plain.saveAfter == 2 && plain.saveOnFocusLoss)
        let never = try ConfigurationParser.parse(#"{ "documents": { "saveAfter": 0, "saveOnFocusLoss": false } }"#)
        #expect(never.issues.isEmpty)
        #expect(never.configuration.documents.saveAfter == 0 && !never.configuration.documents.saveOnFocusLoss)
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
                "documents.saveAfter", "documents.saveOnFocusLoss", "documents.largerHeadings", "documents.linksOpen",
                "documents.pagesReachNetwork", "documents.quickLook", "documents.textSize", "documents.fullWidth",
                "documents.alignsLeft",
                "documents.smartPunctuation", "documents.textFont", "documents.headingFont", "documents.codeFont",
                "documents.diagramFont", "documents.fontFeatures", "documents.highlightsCode",
                "documents.showsLanguage",
                "documents.copyButton", "documents.tabSize", "documents.rowLines", "documents.columnLines",
                "documents.outerBorder", "documents.scrollsTables", "documents.bleedsTables", "documents.drawsDiagrams",
                "documents.opensFrontMatter"
            ]
        )
        #expect(
            SettingsSection.documents.topics.map(\.id) == ["general.documents", "documents.library"]
        )
    }

    /// `documents.largerHeadings`: the source shows a heading at the page's size for its level, closer to what it
    /// becomes; on by default, so the source looks like its page.
    @Test func `the source's headings are at the page's size unless the file says otherwise`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.documents.largerHeadings)
        let off = try ConfigurationParser.parse(#"{ "documents": { "largerHeadings": false } }"#)
        #expect(off.issues.isEmpty && !off.configuration.documents.largerHeadings)
        var configuration = Configuration()
        configuration.documents.largerHeadings = false
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.issues.isEmpty && back.configuration.documents == configuration.documents)
        #expect(
            SettingsSection.topic("general.documents")?.topic.options.map(\.id).contains("documents.largerHeadings")
                == true
        )
    }
}
