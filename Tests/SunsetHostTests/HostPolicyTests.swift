import SunsetCore
import SunsetHost
import Testing

@Suite("Host policy") struct HostPolicyTests {
    @Test func `a program writes the clipboard unless the setting says no, which stops no notification`() {
        let write = HostEvent.clipboardWrite("secret")
        let note = HostEvent.notification(title: "done", body: "")
        #expect(HostPolicy().admits(write))
        #expect(!HostPolicy(clipboardWrite: false).admits(write))
        #expect(HostPolicy(clipboardWrite: false).admits(note))
    }
}
