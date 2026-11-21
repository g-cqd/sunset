import CoreGraphics
import Testing

@testable import SunsetShellModel

/// Seen on screen (n72): a terminal's card was its whole window shrunk, the prompt a yellow dot. It shows the top left,
/// 80 columns wide, at the card's ratio.
@Suite("A terminal's share card")
struct TerminalPreviewCropTests {
    @Test func `a wide terminal shows its top-left 80 columns, at the card's ratio`() {
        let rect = TerminalPreviewCrop.rect(
            frame: CGSize(width: 2900, height: 1800),
            cellWidth: 16,
            padding: 10,
            ratio: 0.625
        )
        #expect(rect.width == 1300)
        #expect(rect.height == 812.5)
        #expect(rect.minX == 0)
        #expect(rect.maxY == 1800, "the top, in Core Image's coordinates")
    }

    @Test func `a narrow one, or one without cells yet, shows whole; never taller than the frame`() {
        let narrow = CGSize(width: 900, height: 1800)
        #expect(
            TerminalPreviewCrop.rect(frame: narrow, cellWidth: 16, padding: 10, ratio: 0.625)
                == CGRect(x: 0, y: 1237.5, width: 900, height: 562.5)
        )
        let frame = CGSize(width: 2900, height: 1800)
        #expect(TerminalPreviewCrop.rect(frame: frame, cellWidth: nil, padding: 10, ratio: 0.625).height == 1800)
        let flat = CGSize(width: 2900, height: 300)
        #expect(
            TerminalPreviewCrop.rect(frame: flat, cellWidth: 16, padding: 10, ratio: 0.625)
                == CGRect(x: 0, y: 0, width: 1300, height: 300)
        )
    }
}
