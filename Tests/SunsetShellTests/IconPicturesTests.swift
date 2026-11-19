import AppKit
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The symbols of the icon grid as pictures (the owner, 2026-11-17: rendering and scrolling "should also be
/// instantaneous"). Drawing never waits for a symbol: what is not rendered yet is rendered off the main actor and drawn
/// when it is there.
@MainActor
@Suite("The symbols' pictures")
struct IconPicturesTests {
    @Test
    func `a symbol is rendered off the main actor, in the colour given; a name the system has not is not asked twice`()
        async
    {
        let pictures = IconPictures()
        pictures.use(scale: 2, ink: [1, 0, 0, 1])
        #expect(pictures.kept("folder") == nil, "nothing is rendered by asking")
        await withCheckedContinuation { done in
            pictures.prepare(["folder", "no.such.symbol.zz", "folder.fill"]) { done.resume() }
        }
        let folder = pictures.kept("folder")
        #expect(folder != nil && pictures.kept("folder.fill") != nil && pictures.kept("no.such.symbol.zz") == nil)
        let width = folder?.image.width ?? 0
        #expect((folder?.size.width ?? 0) > 8 && width == Int(((folder?.size.width ?? 0) * 2).rounded(.up)))
        let bytes = folder?.image.dataProvider?.data.map { Array($0 as Data) } ?? []
        let pixels = stride(from: 0, to: bytes.count - 3, by: 4).map { Array(bytes[$0 ..< $0 + 4]) }
        let covered = pixels.count { $0[3] > 128 }
        #expect(covered > pixels.count / 30 && covered < pixels.count / 2, "an outline: \(covered) of \(pixels.count)")
        #expect(pixels.allSatisfy { $0[1] == 0 && $0[2] == 0 } && pixels.contains { $0[0] > 200 }, "red, and only red")
        #expect(pictures.missing(["folder", "no.such.symbol.zz", "trash"]) == ["trash"])
        // Another colour, or another scale, starts again.
        pictures.use(scale: 2, ink: [0, 0, 0, 1])
        #expect(pictures.kept("folder") == nil && pictures.missing(["no.such.symbol.zz"]).isEmpty, "still no symbol")
    }

    /// What reaches the screen: the symbol where it was asked for, upright, and nothing around it.
    @Test func `a symbol is drawn from its picture, upright in a flipped view`() async throws {
        let pictures = IconPictures()
        pictures.use(scale: 2, ink: [1, 0, 0, 1])
        await withCheckedContinuation { done in pictures.prepare(["arrow.up.to.line"]) { done.resume() } }
        let (width, height) = (80, 80)
        let context = try #require(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        // As a flipped view at 2x: the origin at the top left.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 2, y: -2)
        #expect(!pictures.paint("folder", centredOn: CGPoint(x: 20, y: 20), in: context), "not rendered: not drawn")
        #expect(pictures.paint("arrow.up.to.line", centredOn: CGPoint(x: 20, y: 20), in: context))
        let pixels = try #require(context.data).assumingMemoryBound(to: UInt8.self)
        func covered(_ row: Int) -> Int {
            (0 ..< width).count { unsafe pixels[(row * width + $0) * 4 + 3] > 200 }
        }
        let inked = (0 ..< height).filter { covered($0) > 0 }
        let (top, bottom) = (try #require(inked.first), try #require(inked.last))
        #expect(
            top > 15 && bottom < 65 && bottom - top > 14,
            "around the centre, not the whole bitmap: \(top)...\(bottom)"
        )
        // The line the arrow points to is at the top: the widest row is in the upper half of the symbol.
        let widest = try #require(inked.max { covered($0) < covered($1) })
        #expect(widest < (top + bottom) / 2, "upright: the bar is above the arrow")
    }
}
