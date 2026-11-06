import IOSurface
import Testing

@testable import SunsetRender
@testable import SunsetRenderMac

@Suite("IOSurface presenter") struct IOSurfacePresenterTests {
    /// A surface whose every pixel says where it is and which version of the frame it belongs to.
    private func frame(width: Int, height: Int, version: UInt32) -> Surface {
        var surface = Surface(width: width, height: height)
        for y in 0 ..< height {
            for x in 0 ..< width {
                surface.pixels[y * width + x] = 0xFF00_0000 | version << 16 | UInt32(y) << 8 | UInt32(x)
            }
        }
        return surface
    }

    private func pixels(_ io: IOSurface) -> [UInt32] {
        io.lock(options: .readOnly, seed: nil)
        defer { io.unlock(options: .readOnly, seed: nil) }
        var result: [UInt32] = []
        for y in 0 ..< io.height {
            let row = (io.baseAddress + y * io.bytesPerRow).assumingMemoryBound(to: UInt32.self)
            for x in 0 ..< io.width { result.append(row[x]) }
        }
        return result
    }

    @Test func `the first frame is shown whole, with its stride and its size`() throws {
        let presenter = IOSurfacePresenter()
        #expect(presenter.latest == nil)
        let surface = frame(width: 13, height: 9, version: 1)
        presenter.present(surface, changedRows: 0 ... 8)
        let shown = try #require(presenter.latest)
        #expect(shown.width == 13 && shown.height == 9)
        #expect(pixels(shown) == Array(surface.pixels), "an odd width: rows are padded in memory, not in the frame")
    }

    @Test func `a frame with a few changed rows shows the whole frame, through every buffer in turn`() throws {
        let presenter = IOSurfacePresenter()
        var surface = frame(width: 13, height: 9, version: 1)
        presenter.present(surface, changedRows: 0 ... 8)
        for step in 2 ... 8 {
            let row = step % 9
            for x in 0 ..< 13 {
                surface.pixels[row * 13 + x] = 0xFF00_0000 | UInt32(step) << 16 | UInt32(row) << 8 | UInt32(x)
            }
            presenter.present(surface, changedRows: row ... row)
            let shown = try #require(presenter.latest)
            #expect(pixels(shown) == Array(surface.pixels), "step \(step)")
        }
    }

    @Test func `each frame goes to another surface than the one just shown`() throws {
        let presenter = IOSurfacePresenter()
        let surface = frame(width: 8, height: 4, version: 1)
        presenter.present(surface, changedRows: 0 ... 3)
        let first = try #require(presenter.latest)
        presenter.present(surface, changedRows: 1 ... 1)
        let second = try #require(presenter.latest)
        #expect(first !== second, "the compositor may still be reading the first")
    }

    @Test func `a new size starts again with whole frames`() throws {
        let presenter = IOSurfacePresenter()
        presenter.present(frame(width: 8, height: 4, version: 1), changedRows: 0 ... 3)
        let bigger = frame(width: 20, height: 11, version: 2)
        presenter.present(bigger, changedRows: 5 ... 5)
        let shown = try #require(presenter.latest)
        #expect(shown.width == 20 && shown.height == 11)
        #expect(
            pixels(shown) == Array(bigger.pixels),
            "the changed rows given were not the whole frame, but the size changed"
        )
    }

    @Test func `the surface says its pixels are sRGB, so the compositor converts them on the GPU`() throws {
        let presenter = IOSurfacePresenter()
        presenter.present(frame(width: 4, height: 4, version: 1), changedRows: 0 ... 3)
        let shown = try #require(presenter.latest)
        #expect(shown.attachment(forKey: "IOSurfaceColorSpace") != nil)
    }
}
