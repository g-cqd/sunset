// Part of Scripts/lights-probe: where something is drawn in the top 35 pt of a picture of a dark window (2x), by the columns
// that are brighter than its ground. Args: path [rows].
import AppKit

let arguments = CommandLine.arguments
guard arguments.count > 1,
    let picture = NSImage(contentsOfFile: arguments[1])?.representations.first as? NSBitmapImageRep
else {
    print("usage: ink picture.png [rows]")
    exit(1)
}
let rows = arguments.count > 2 ? Int(arguments[2]) ?? 70 : 70

/// Whether the pixel is drawn on: brighter than the window's ground, darker than its text.
func isInk(_ x: Int, _ y: Int) -> Bool {
    guard let colour = picture.colorAt(x: x, y: y) else { return false }
    let light = Double(colour.redComponent + colour.greenComponent + colour.blueComponent) / 3
    return light > 0.24 && light < 0.5
}

var columns: [Int] = []
for x in 0 ..< picture.pixelsWide where (4 ..< rows).contains(where: { isInk(x, $0) }) { columns.append(x) }
var runs: [ClosedRange<Int>] = []
for x in columns {
    if let last = runs.last, x - last.upperBound <= 2 {
        runs[runs.count - 1] = last.lowerBound ... x
    } else {
        runs.append(x ... x)
    }
}
for run in runs where run.count > 12 {
    let inked = (4 ..< rows).filter { y in run.contains { isInk($0, y) } }
    guard let top = inked.first, let bottom = inked.last else { continue }
    let left = Double(run.lowerBound) / 2
    let right = Double(run.upperBound + 1) / 2
    print("ink x \(left)...\(right) pt, y \(Double(top) / 2)...\(Double(bottom + 1) / 2) pt")
}
