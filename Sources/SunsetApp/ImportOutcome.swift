import SunsetImport

/// What an import did, for the sheet to say.
struct ImportOutcome: Equatable {
    var report: ImportReport
    var folder: String
    var space: String
    var extensions: [BrowserExtension]
    var containers: [BrowserContainer]
}
