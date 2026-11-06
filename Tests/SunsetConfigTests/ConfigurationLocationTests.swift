import Testing

@testable import SunsetConfig

@Suite("Configuration: where the file is") struct ConfigurationLocationTests {
    @Test func `SUNSET_CONFIG names the file outright`() {
        let path = ConfigurationLocation.path(
            environment: ["SUNSET_CONFIG": "/tmp/mine.json", "XDG_CONFIG_HOME": "/x"],
            home: "/Users/a"
        )
        #expect(path == "/tmp/mine.json")
    }

    @Test func `XDG_CONFIG_HOME comes next`() {
        #expect(
            ConfigurationLocation.path(environment: ["XDG_CONFIG_HOME": "/x/config"], home: "/Users/a")
                == "/x/config/sunset/config.json"
        )
    }

    @Test func `otherwise it is under the home directory`() {
        #expect(ConfigurationLocation.path(environment: [:], home: "/Users/a") == "/Users/a/.config/sunset/config.json")
    }

    @Test func `empty variables count as unset, and a trailing slash does not double`() {
        #expect(
            ConfigurationLocation.path(environment: ["SUNSET_CONFIG": "", "XDG_CONFIG_HOME": ""], home: "/Users/a/")
                == "/Users/a/.config/sunset/config.json"
        )
        #expect(
            ConfigurationLocation.path(environment: ["XDG_CONFIG_HOME": "/x/"], home: "/h") == "/x/sunset/config.json"
        )
    }
}
