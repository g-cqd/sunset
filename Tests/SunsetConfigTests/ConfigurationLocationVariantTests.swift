import Testing

@testable import SunsetConfig

/// A variant of Sunset reads its own configuration file, so that its settings never touch his.
@Suite("A variant's configuration file") struct ConfigurationLocationVariantTests {
    @Test func `Sunset Lab reads its own file; the variables still win`() {
        #expect(
            ConfigurationLocation.path(environment: [:], home: "/Users/a", variant: "lab")
                == "/Users/a/.config/sunset-lab/config.json"
        )
        #expect(
            ConfigurationLocation.path(environment: ["XDG_CONFIG_HOME": "/x"], home: "/Users/a", variant: "lab")
                == "/x/sunset-lab/config.json"
        )
        #expect(
            ConfigurationLocation.path(environment: ["SUNSET_CONFIG": "/t/c.json"], home: "/a", variant: "lab")
                == "/t/c.json"
        )
        #expect(
            ConfigurationLocation.path(environment: [:], home: "/Users/a", variant: nil)
                == "/Users/a/.config/sunset/config.json"
        )
    }
}

extension ConfigurationLocationVariantTests {
    /// What `Scripts/install-lab.sh` writes for Sunset Lab, the first time: read without an issue, the tab bar shown at the top.
    @Test func `the Lab's first file is read without an issue`() throws {
        let read = try ConfigurationParser.parse(#"{ "tabs": { "mode": "internal", "bar": { "position": "top" } } }"#)
        #expect(read.issues.isEmpty, "\(read.issues)")
        #expect(read.configuration.tabs.mode == .internal && read.configuration.tabs.bar.position == .top)
    }
}
