import Testing

@testable import SunsetConfig

@Suite("Configuration: written file layout") struct ConfigurationWriterLayoutTests {
    @Test func `each section of the file appears once, so that no later copy hides an earlier one`() throws {
        var seen: [String] = []
        var last = ""
        for key in ConfigurationKeys.all {
            let section = key.split(separator: ".").first.map(String.init) ?? key
            if section != last {
                #expect(!seen.contains(section), "the section \(section) is split in the key list")
                seen.append(section)
                last = section
            }
        }
    }
}
