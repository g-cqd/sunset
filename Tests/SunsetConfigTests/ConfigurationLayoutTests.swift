import Testing

@testable import SunsetConfig

@Suite("Configuration: layout metrics") struct ConfigurationLayoutTests {
    private func read(_ text: String) throws(ConfigurationError) -> ConfigurationParser.Result {
        try ConfigurationParser.parse(text)
    }

    @Test func `the defaults are the values the sidebar had when they were fixed`() {
        let layout = Configuration().layout
        #expect(layout.tabSpacing == 4 && layout.tabSideInset == 2)
        #expect(layout.tabPaddingLeading == 8 && layout.tabPaddingTrailing == 4 && layout.tabPaddingVertical == 3)
        #expect(layout.tabRadius == 6 && layout.closeButtonSize == 20 && layout.closeButtonRadius == 4)
        #expect(layout.lightsInset == 8 && layout.lightsGap == 10 && layout.floatingLightsExtra == 0)
        #expect(layout.pinButtonSize == 24 && layout.pinButtonRadius == 5)
        #expect(layout.hairlineWidth == 0.5 && layout.hairlineOpacity == 0.12)
        #expect(layout.revealStripWidth == 10 && layout.hideDelay == 0.35 && layout.animation == 0.15)
        #expect(layout.terminalRadius == nil && layout.panelRadius == nil, "nil: concentric with the window")
    }

    @Test func `the floating panel has tab metrics of its own (its spacing half the old one) and a handle width`()
        throws
    {
        let layout = Configuration().layout
        #expect(layout.floatingTabSpacing == 3 && layout.floatingTabSideInset == 4)
        #expect(layout.floatingTabPaddingLeading == layout.tabPaddingLeading)
        #expect(layout.floatingTabPaddingTrailing == layout.tabPaddingTrailing)
        #expect(layout.floatingTabPaddingVertical == layout.tabPaddingVertical)
        #expect(layout.floatingTabRadius == layout.tabRadius)
        #expect(layout.floatingCloseButtonSize == layout.closeButtonSize)
        #expect(layout.floatingCloseButtonRadius == layout.closeButtonRadius)
        #expect(layout.resizeHandleWidth == 8)
        let set = try read(
            #"{ "layout": { "floatingTabSpacing": 2, "floatingTabRadius": 12, "resizeHandleWidth": 12 } }"#
        )
        #expect(set.issues.isEmpty)
        #expect(set.configuration.layout.floatingTabSpacing == 2 && set.configuration.layout.floatingTabRadius == 12)
        #expect(set.configuration.layout.resizeHandleWidth == 12)
        #expect(set.configuration.layout.tabSpacing == 4, "the docked metric is untouched")
    }

    @Test func `the tab metrics the floating panel draws with are its own`() {
        var layout = Configuration.Layout()
        layout.floatingTabSpacing = 1
        layout.floatingTabRadius = 14
        layout.tabRadius = 3
        let floating = layout.floatingTabs
        #expect(floating.tabSpacing == 1 && floating.tabRadius == 14)
        #expect(layout.tabRadius == 3, "the original is not changed")
        #expect(floating.lightsInset == layout.lightsInset, "metrics that are not tab metrics are carried over")
    }

    @Test func `every metric can be set in the layout section`() throws {
        let result = try read(
            """
            { "layout": { "tabSpacing": 2, "tabSideInset": 0, "tabPaddingLeading": 10, "tabPaddingTrailing": 6,
              "tabPaddingVertical": 5, "tabRadius": 9, "closeButtonSize": 16, "closeButtonRadius": 3,
              "lightsInset": 8, "lightsGap": 12, "floatingLightsExtra": 4, "pinButtonSize": 28, "pinButtonRadius": 8,
              "hairlineWidth": 1, "hairlineOpacity": 0.3, "revealStripWidth": 14, "hideDelay": 0.5, "animation": 0.25,
              "terminalRadius": 12, "panelRadius": 14 } }
            """
        )
        #expect(result.issues.isEmpty)
        let layout = result.configuration.layout
        #expect(layout.tabSpacing == 2 && layout.tabSideInset == 0 && layout.tabPaddingLeading == 10)
        #expect(layout.tabPaddingTrailing == 6 && layout.tabPaddingVertical == 5 && layout.tabRadius == 9)
        #expect(layout.closeButtonSize == 16 && layout.closeButtonRadius == 3 && layout.lightsInset == 8)
        #expect(layout.lightsGap == 12 && layout.floatingLightsExtra == 4 && layout.pinButtonSize == 28)
        #expect(layout.pinButtonRadius == 8 && layout.hairlineWidth == 1 && layout.hairlineOpacity == 0.3)
        #expect(layout.revealStripWidth == 14 && layout.hideDelay == 0.5 && layout.animation == 0.25)
        #expect(layout.terminalRadius == 12 && layout.panelRadius == 14)
    }

    @Test func `a radius of null goes back to following the window, nonsense is an issue and changes nothing`() throws {
        #expect(try read(#"{ "layout": { "terminalRadius": null } }"#).configuration.layout.terminalRadius == nil)
        let bad = try read(#"{ "layout": { "tabRadius": 99, "tabSpacing": "wide", "bogus": 1 } }"#)
        #expect(bad.issues.map(\.path).sorted() == ["layout.bogus", "layout.tabRadius", "layout.tabSpacing"])
        #expect(bad.configuration.layout == Configuration.Layout())
    }

    @Test func `a theme may set the layout`() throws {
        let result = try ConfigurationParser.parse(#"{ "layout": { "tabRadius": 10 } }"#, scope: .theme)
        #expect(result.issues.isEmpty && result.configuration.layout.tabRadius == 10)
    }

    @Test func `a changed layout is its own group`() {
        var new = Configuration()
        new.layout.tabRadius = 2
        #expect(new.changes(from: Configuration()) == [.layout])
    }

    @Test func `the layout goes to the file and back`() throws {
        var configuration = Configuration()
        configuration.layout.tabSpacing = 3.5
        configuration.layout.terminalRadius = 11
        let text = ConfigurationWriter.text(for: configuration)
        #expect(try read(text).configuration.layout == configuration.layout)
        #expect(text.contains("\"panelRadius\": null"))
    }
}
