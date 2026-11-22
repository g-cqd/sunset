import Foundation
import SunsetTestSupport
import Testing

/// Addresses, URLs, paths and other code are typed and shown in a monospaced font (the address field and the command bar
/// excepted). A `Text` of a host, an address, a URL or a path is `.code()`; a field for one says so too.
@Suite("Addresses, paths and code in monospace") struct CodeTextTests {
    /// A `Text` whose only argument is a value of that kind: a name ending in host, address, url, path, absoluteString, or a
    /// short address.
    static let codeValue =
        #"Text\((?:[A-Za-z_.]*\.)?(?:[a-z]*[hH]ost|[a-z]*[aA]ddress|url|absoluteString|path|keyword)\)|Text\(AddressChoice\.shortAddress\([^()]*\)\)"#

    @Test func `every Text of an address, a host, a path or a keyword is code`() {
        var plain: [String] = []
        for file in RepositoryFiles.swiftFiles(in: ["Sources"]) {
            let lines = file.text.components(separatedBy: "\n")
            for (index, line) in lines.enumerated()
            where line.range(of: Self.codeValue, options: .regularExpression) != nil {
                // The statement: this line and the modifiers on the lines after it.
                var statement = line
                var next = index + 1
                while next < lines.count, lines[next].trimmingCharacters(in: .whitespaces).hasPrefix(".") {
                    statement += lines[next]
                    next += 1
                }
                if !statement.contains(".code()") { plain.append("\(file.name):\(index + 1)") }
            }
        }
        #expect(plain.isEmpty, "\(plain)")
    }

    /// The fields that take an address, a pattern, a keyword or a file's name.
    static let codeFields: [String: Int] = ["EngineList.swift": 1, "SettingsRow.swift": 2]

    @Test func `the settings that hold an address or a file's name have their field in monospace`() {
        // SunsetCoreTests does not import SunsetConfig: the options say it in their sources.
        let sources = RepositoryFiles.swiftFiles(in: ["Sources/SunsetConfig"])
        for (name, id) in [
            ("SettingsOption+Proxy.swift", "web.proxy"), ("SettingsOption+Appearance.swift", "\"theme\"")
        ] {
            let text = sources.first { $0.name == name }?.text ?? ""
            let after = text.range(of: id).map { text[$0.upperBound...] } ?? ""
            #expect(after.prefix(400).contains(".code()"), "\(name): \(id)")
        }
    }

    @Test func `the fields for addresses and code are code`() {
        for (name, count) in Self.codeFields {
            let file = RepositoryFiles.swiftFiles(in: ["Sources"]).first { $0.name == name }
            let said = (file?.text.components(separatedBy: ".code(").count ?? 1) - 1
            #expect(said >= count, "\(name): \(said) of \(count)")
        }
    }
}
