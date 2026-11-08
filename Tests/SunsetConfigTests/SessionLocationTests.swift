import Testing

@testable import SunsetConfig

@Suite("Session file location") struct SessionLocationTests {
    @Test func `SUNSET_SESSION names the file itself`() {
        #expect(SessionLocation.path(environment: ["SUNSET_SESSION": "/x/s.json"], home: "/h") == "/x/s.json")
    }

    @Test func `with a configuration file set by the environment the session sits beside it`() {
        #expect(
            SessionLocation.path(environment: ["SUNSET_CONFIG": "/tmp/lk2/c.json"], home: "/h")
                == "/tmp/lk2/session.json"
        )
        #expect(SessionLocation.path(environment: ["SUNSET_CONFIG": "c.json"], home: "/h") == "./session.json")
    }

    @Test func `by default it is in the user's application support, empty variables count as unset`() {
        let expected = "/h/Library/Application Support/Sunset/session.json"
        #expect(SessionLocation.path(environment: [:], home: "/h") == expected)
        #expect(SessionLocation.path(environment: ["SUNSET_SESSION": "", "SUNSET_CONFIG": ""], home: "/h/") == expected)
    }
}
