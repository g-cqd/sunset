import Testing

@testable import SunsetPane

/// A Space's colour: one for both schemes, or one in light of its own (design 0009).
@Suite("A Space's colour in light and dark")
struct SpaceSchemeTintTests {
    @Test func `one colour tints both; a light one of its own tints in light only, and both are kept in its look`()
        throws
    {
        var space = Space(name: "Work")
        let blue = try #require(IconColor(hex: "#3366FF"))
        let sand = try #require(IconColor(hex: "#F0E0C0"))
        space.tint = blue
        #expect(space.tint(light: true) == blue && space.tint(light: false) == blue)
        space.lightTint = sand
        #expect(space.tint(light: true) == sand && space.tint(light: false) == blue)
        #expect(space.look?["tint"] == blue.hex && space.look?["tintLight"] == sand.hex)
        space.lightTint = nil
        space.tint = nil
        #expect(space.look == nil)
    }
}
