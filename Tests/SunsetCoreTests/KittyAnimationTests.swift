import AemiKernel
import Testing

@testable import SunsetCore

/// Kitty animation per the protocol's "Animation" section (roadmap 0010 E): loading and editing frames, composing
/// rectangles (source at `X,Y`, destination at `x,y`), and terminal-driven playback with gaps, gapless frames, loop
/// counts and loading mode. Pixels are 1×1 or 2×1 RGBA so every byte can be checked.
@Suite("Kitty animation") struct KittyAnimationTests {
    private static let red: [UInt8] = [255, 0, 0, 255]
    private static let green: [UInt8] = [0, 255, 0, 255]
    private static let blue: [UInt8] = [0, 0, 255, 255]

    private func send(_ t: inout Terminal, _ control: String, _ pixels: [UInt8] = []) -> String {
        let payload = pixels.isEmpty ? "" : ";" + Base64.encodedString(pixels)
        t.feed("\(esc)_G\(control)\(payload)\(esc)\\")
        return String(decoding: t.takeReplies(), as: UTF8.self)
    }

    private func ok(_ id: Int) -> String {
        "\(esc)_Gi=\(id);OK\(esc)\\"
    }

    /// A 2×1 image `id` (left red, right green) shown at the cursor.
    private func twoPixelImage(_ id: Int) -> Terminal {
        var t = Terminal(columns: 10, rows: 4)
        t.setCellPixelSize(width: 2, height: 1)
        _ = send(&t, "a=T,q=2,i=\(id),f=32,s=2,v=1", Self.red + Self.green)
        return t
    }

    private func frame(_ t: Terminal, _ id: UInt32) -> [UInt8] {
        t.screen.graphics.images[id]?.activeForRender.pixels ?? []
    }

    @Test func `a frame is composed onto the frame c names, at x and y, replacing with X=1`() {
        var t = twoPixelImage(1)
        #expect(send(&t, "a=f,i=1,c=1,x=1,y=0,s=1,v=1,X=1", Self.blue) == ok(1))
        #expect(send(&t, "a=a,i=1,c=2") == ok(1))
        #expect(frame(t, 1) == Self.red + Self.blue)
        // No `c`: a transparent canvas, or the colour `Y` gives (0x00ff00ff, opaque green).
        #expect(send(&t, "a=f,i=1,Y=16711935,x=0,y=0,s=1,v=1,X=1", Self.blue) == ok(1))
        #expect(send(&t, "a=a,i=1,c=3") == ok(1))
        #expect(frame(t, 1) == Self.blue + Self.green)
    }

    @Test func `r edits the existing frame in place, and the drawn copy changes with it`() {
        var t = twoPixelImage(1)
        _ = send(&t, "a=f,i=1,c=1,X=1,s=1,v=1", Self.blue)
        _ = send(&t, "a=a,i=1,c=2")
        let before = t.screen.graphics.images[1]?.activeForRender.order
        #expect(frame(t, 1) == Self.blue + Self.green)
        // Editing frame 2 at x=1 keeps its left pixel (it is the canvas), not a blank one.
        #expect(send(&t, "a=f,i=1,r=2,x=1,s=1,v=1,X=1", Self.red) == ok(1))
        #expect(frame(t, 1) == Self.blue + Self.red)
        #expect(t.screen.graphics.images[1]?.activeForRender.order != before, "a cached copy would be stale")
    }

    @Test func `a=c takes the source at X,Y and puts it at x,y`() {
        var t = twoPixelImage(1)
        _ = send(&t, "a=f,i=1,c=1,X=1,s=2,v=1", Self.blue + Self.blue)
        // Frame 1's right pixel (green, at X=1) onto frame 2's left pixel (x=0).
        #expect(send(&t, "a=c,i=1,r=1,c=2,w=1,h=1,X=1,Y=0,x=0,y=0,C=1") == ok(1))
        _ = send(&t, "a=a,i=1,c=2")
        #expect(frame(t, 1) == Self.green + Self.blue)
    }

    @Test func `out of bounds, overlapping, or missing frames are refused as the protocol says`() {
        var t = twoPixelImage(1)
        _ = send(&t, "a=f,i=1,c=1,X=1,s=2,v=1", Self.blue + Self.blue)
        let einval = "\(esc)_Gi=1;EINVAL:Not supported\(esc)\\"
        let enoent = "\(esc)_Gi=1;ENOENT:No such image\(esc)\\"
        #expect(send(&t, "a=c,i=1,r=1,c=2,w=2,h=1,X=1") == einval)
        #expect(send(&t, "a=c,i=1,r=2,c=2,w=1,h=1,X=0,x=0") == einval)
        #expect(send(&t, "a=c,i=1,r=3,c=2") == enoent)
        #expect(send(&t, "a=f,i=1,x=2,s=1,v=1", Self.blue) == einval)
        #expect(send(&t, "a=f,i=1,r=9,s=1,v=1", Self.blue) == enoent)
        #expect(send(&t, "a=a,i=1,c=9") == enoent)
        #expect(t.screen.graphics.images[1]?.animation?.frameCount == 2, "nothing refused was kept")
    }

    @Test func `a PNG root's pixels are never read as blank`() {
        var t = Terminal(columns: 10, rows: 4)
        let png: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52,
            0, 0, 0, 2, 0, 0, 0, 1, 8, 6, 0, 0, 0, 0, 0, 0, 0
        ]
        _ = send(&t, "a=T,q=2,i=5,f=100", png)
        #expect(send(&t, "a=f,i=5,c=1,s=1,v=1", Self.blue) == "\(esc)_Gi=5;EINVAL:Not supported\(esc)\\")
        #expect(send(&t, "a=f,i=5,s=2,v=1", Self.blue + Self.blue) == ok(5), "a whole frame needs no root pixels")
    }

    @Test func `playback follows the gaps, skips gapless frames, and loops back v - 1 times`() {
        var t = twoPixelImage(1)
        _ = send(&t, "a=f,i=1,z=100,s=2,v=1", Self.blue + Self.blue)
        _ = send(&t, "a=f,i=1,z=-1,s=2,v=1", Self.green + Self.green)
        _ = send(&t, "a=f,i=1,z=50,s=2,v=1", Self.red + Self.red)
        _ = send(&t, "a=a,i=1,r=1,z=30,v=2,s=3")
        func tick(_ now: Int64) -> Screen.AnimationTick {
            t.advanceAnimations(nowMilliseconds: now)
        }
        func current() -> Int? {
            t.screen.graphics.images[1]?.animation?.currentFrame
        }
        #expect(tick(1_000) == .init(changed: false, next: 1_030), "timed from the first tick")
        #expect(tick(1_029) == .init(changed: false, next: 1_030))
        #expect(tick(1_030) == .init(changed: true, next: 1_130) && current() == 2)
        #expect(tick(1_130) == .init(changed: true, next: 1_180) && current() == 4, "frame 3 is gapless")
        #expect(tick(1_180) == .init(changed: true, next: 1_210) && current() == 1, "back to the first: loop 1 of 1")
        _ = tick(1_210)
        _ = tick(1_310)
        #expect(current() == 4)
        #expect(tick(1_360) == .init(changed: false, next: nil), "the loop is spent: stopped at the last frame")
        #expect(t.screen.graphics.images[1]?.animation?.state == .stopped)
    }

    @Test func `loading mode waits at the last frame and goes on when one arrives`() {
        var t = twoPixelImage(1)
        _ = send(&t, "a=f,i=1,z=10,s=2,v=1", Self.blue + Self.blue)
        _ = send(&t, "a=a,i=1,r=1,z=10,s=2")
        _ = t.advanceAnimations(nowMilliseconds: 0)
        _ = t.advanceAnimations(nowMilliseconds: 10)
        #expect(t.screen.graphics.images[1]?.animation?.currentFrame == 2)
        #expect(t.advanceAnimations(nowMilliseconds: 20).changed == false, "waits, does not loop")
        _ = send(&t, "a=f,i=1,z=10,s=2,v=1", Self.red + Self.red)
        _ = t.advanceAnimations(nowMilliseconds: 25)
        _ = t.advanceAnimations(nowMilliseconds: 40)
        #expect(t.screen.graphics.images[1]?.animation?.currentFrame == 3)
    }

    @Test func `an image off screen does not advance, and comes back where it was`() {
        var t = twoPixelImage(1)
        _ = send(&t, "a=f,i=1,z=10,s=2,v=1", Self.blue + Self.blue)
        _ = send(&t, "a=a,i=1,r=1,z=10,s=3")
        _ = send(&t, "a=d,d=a")
        #expect(t.advanceAnimations(nowMilliseconds: 0) == .init(changed: false, next: nil))
        _ = send(&t, "a=p,q=2,i=1")
        _ = t.advanceAnimations(nowMilliseconds: 5_000)
        #expect(t.advanceAnimations(nowMilliseconds: 5_010).changed)
        #expect(t.screen.graphics.images[1]?.animation?.currentFrame == 2, "one frame on, not 500")
    }

    @Test func `a changed frame marks only the image's rows, and d=f drops the frames`() {
        var t = twoPixelImage(1)
        _ = send(&t, "a=f,i=1,z=10,s=2,v=1", Self.blue + Self.blue)
        _ = send(&t, "a=a,i=1,r=1,z=10,s=3")
        _ = t.advanceAnimations(nowMilliseconds: 0)
        t.clearDirty()
        #expect(t.advanceAnimations(nowMilliseconds: 10).changed)
        #expect(t.screen.isDirty(row: 0) && !t.screen.isDirty(row: 2))
        _ = send(&t, "a=d,d=f,i=1")
        let anim = t.screen.graphics.images[1]?.animation
        #expect(anim?.frameCount == 1 && anim?.currentFrame == 1 && anim?.state == .stopped)
        #expect(frame(t, 1) == Self.red + Self.green)
    }
}
