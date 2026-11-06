// Reads a screenshot (in whatever profile the display has: the PNG carries it), converts it to sRGB, finds the eight stripes `paint.sh` drew and prints the
// colour of each next to the one asked for. Exit status 1 when a channel is off by more than the tolerance (argument 2, default 3).
import CoreGraphics
import Foundation
import ImageIO

let expected: [(Int, Int, Int)] = [
    (255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 128, 64), (128, 128, 128), (205, 0, 0), (30, 60, 200), (255, 255, 255)
]
let arguments = CommandLine.arguments
guard arguments.count >= 2,
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: arguments[1]) as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
    let sRGB = CGColorSpace(name: CGColorSpace.sRGB)
else {
    print("usage: measure screenshot.png [tolerance]")
    exit(2)
}
let tolerance = arguments.count > 2 ? Int(arguments[2]) ?? 3 : 3
let width = image.width
var pixels = [UInt8](repeating: 0, count: width * image.height * 4)
let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
    guard
        let context = CGContext(
            data: buffer.baseAddress,
            width: width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: sRGB,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    else { return false }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: image.height))
    return true
}
guard drawn else { exit(2) }
print("screenshot profile:", image.colorSpace?.name as String? ?? "?")

func pixel(_ y: Int) -> (Int, Int, Int) {
    let offset = (y * width + width / 2) * 4
    return (Int(pixels[offset]), Int(pixels[offset + 1]), Int(pixels[offset + 2]))
}
func near(_ a: (Int, Int, Int), _ b: (Int, Int, Int), _ by: Int) -> Bool {
    abs(a.0 - b.0) <= by && abs(a.1 - b.1) <= by && abs(a.2 - b.2) <= by
}
// Runs of one colour down the middle column; the first that is red starts the stripes.
var runs: [(start: Int, length: Int, colour: (Int, Int, Int))] = []
var y = 0
while y < image.height {
    var end = y
    while end + 1 < image.height, near(pixel(end + 1), pixel(y), 6) { end += 1 }
    runs.append((y, end - y + 1, pixel(y + (end - y) / 2)))
    y = end + 1
}
guard let first = runs.firstIndex(where: { $0.length >= 10 && near($0.colour, expected[0], 6) }),
    first + 8 <= runs.count
else {
    print("the stripes were not found")
    exit(2)
}
var worst = 0
for (index, want) in expected.enumerated() {
    let got = runs[first + index].colour
    let error = max(abs(got.0 - want.0), abs(got.1 - want.1), abs(got.2 - want.2))
    worst = max(worst, error)
    print("asked \(want) shown \(got) largest channel error \(error)")
}
print("worst channel error: \(worst) of 255 (tolerance \(tolerance))")
exit(worst > tolerance ? 1 : 0)
