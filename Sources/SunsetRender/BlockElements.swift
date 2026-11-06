/// U+2580...U+259F: halves, eighths, quadrants and shades.
enum BlockElements {
    static func draw(_ scalar: UInt32, into canvas: inout Canvas) {
        let width = canvas.width
        let height = canvas.height
        // Eighths are rounded to whole pixels, so the 8/8 block is the whole cell.
        func rows(_ eighths: Int) -> Int { (height * eighths + 4) / 8 }
        func columns(_ eighths: Int) -> Int { (width * eighths + 4) / 8 }
        let halfWidth = width / 2
        let halfHeight = height / 2
        func quadrants(_ upperLeft: Bool, _ upperRight: Bool, _ lowerLeft: Bool, _ lowerRight: Bool) {
            if upperLeft { canvas.fill(x: 0, y: 0, width: halfWidth, height: halfHeight) }
            if upperRight { canvas.fill(x: halfWidth, y: 0, width: width - halfWidth, height: halfHeight) }
            if lowerLeft { canvas.fill(x: 0, y: halfHeight, width: halfWidth, height: height - halfHeight) }
            if lowerRight {
                canvas.fill(x: halfWidth, y: halfHeight, width: width - halfWidth, height: height - halfHeight)
            }
        }
        switch scalar {
            case 0x2580: canvas.fill(x: 0, y: 0, width: width, height: halfHeight)
            case 0x2581 ... 0x2588:
                let covered = rows(Int(scalar - 0x2580))
                canvas.fill(x: 0, y: height - covered, width: width, height: covered)
            case 0x2589 ... 0x258F: canvas.fill(x: 0, y: 0, width: columns(Int(0x2590 - scalar)), height: height)
            case 0x2590: canvas.fill(x: halfWidth, y: 0, width: width - halfWidth, height: height)
            case 0x2591: canvas.fill(x: 0, y: 0, width: width, height: height, value: 64)
            case 0x2592: canvas.fill(x: 0, y: 0, width: width, height: height, value: 128)
            case 0x2593: canvas.fill(x: 0, y: 0, width: width, height: height, value: 192)
            case 0x2594: canvas.fill(x: 0, y: 0, width: width, height: rows(1))
            case 0x2595:
                let covered = columns(1)
                canvas.fill(x: width - covered, y: 0, width: covered, height: height)
            case 0x2596: quadrants(false, false, true, false)
            case 0x2597: quadrants(false, false, false, true)
            case 0x2598: quadrants(true, false, false, false)
            case 0x2599: quadrants(true, false, true, true)
            case 0x259A: quadrants(true, false, false, true)
            case 0x259B: quadrants(true, true, true, false)
            case 0x259C: quadrants(true, true, false, true)
            case 0x259D: quadrants(false, true, false, false)
            case 0x259E: quadrants(false, true, true, false)
            case 0x259F: quadrants(false, true, true, true)
            default: break
        }
    }
}
