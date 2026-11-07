import QuartzCore
import Testing

@testable import SunsetPrivate

@Suite("Backdrop blur layer") @MainActor struct BackdropBlurTests {
    @Test func `the layer class and the blur filter are found by name on this system`() {
        #expect(BackdropBlur.isAvailable)
    }

    @Test func `a layer is made with a blur filter of the radius asked for, whole points from 0 to 100`() throws {
        let layer = try #require(BackdropBlur.makeLayer(radius: 24))
        let filters = try #require(layer.filters)
        #expect(filters.count == 1)
        let filter = try #require(filters.first as? NSObject)
        #expect((filter.value(forKey: "inputRadius") as? NSNumber)?.doubleValue == 24)
        let clamped = try #require(BackdropBlur.makeLayer(radius: 5000))
        #expect(((clamped.filters?.first as? NSObject)?.value(forKey: "inputRadius") as? NSNumber)?.doubleValue == 100)
    }

    @Test func `a radius of 0 or less is no layer: there is nothing to blur`() {
        #expect(BackdropBlur.makeLayer(radius: 0) == nil)
        #expect(BackdropBlur.makeLayer(radius: -3) == nil)
        #expect(BackdropBlur.makeLayer(radius: .nan) == nil)
    }

    @Test func `the radius of an existing layer can be changed`() throws {
        let layer = try #require(BackdropBlur.makeLayer(radius: 10))
        BackdropBlur.setRadius(40, on: layer)
        #expect(((layer.filters?.first as? NSObject)?.value(forKey: "inputRadius") as? NSNumber)?.doubleValue == 40)
    }
}
