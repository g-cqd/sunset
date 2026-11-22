import Testing

@testable import SunsetPane

/// Help is a tab of its own kind: its descriptor names the topic it shows, and its title.
@Suite("Help's tab") struct HelpDescriptorTests {
    @Test func `help's descriptor keeps its topic and is of its own kind`() {
        let help = PaneDescriptor.help(topic: "keepAwake")
        #expect(help.kind == PaneDescriptor.helpKind && help.kind != PaneDescriptor.settingsKind)
        #expect(help.state["topic"] == "keepAwake" && help.state["title"] == "Help")
    }
}
