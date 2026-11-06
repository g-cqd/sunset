extension BoxDrawing {
    // MARK: Dashes

    static func drawDashes(_ scalar: UInt32, into canvas: inout Canvas, light: Int) {
        let isHorizontal: Bool
        let count: Int
        switch scalar {
            case 0x2504, 0x2505: (isHorizontal, count) = (true, 3)
            case 0x2506, 0x2507: (isHorizontal, count) = (false, 3)
            case 0x2508, 0x2509: (isHorizontal, count) = (true, 4)
            case 0x250A, 0x250B: (isHorizontal, count) = (false, 4)
            case 0x254C, 0x254D: (isHorizontal, count) = (true, 2)
            default: (isHorizontal, count) = (false, 2)
        }
        let heavyOnes: Set<UInt32> = [0x2505, 0x2507, 0x2509, 0x250B, 0x254D, 0x254F]
        let t = heavyOnes.contains(scalar) ? 2 * light : light
        let length = isHorizontal ? canvas.width : canvas.height
        for index in 0 ..< count {
            let start = index * length / count
            let end = (index + 1) * length / count
            let gap = max(1, (end - start) / 3)
            let from = start + gap / 2
            let span = (end - start) - gap
            if isHorizontal {
                canvas.fill(x: from, y: (canvas.height - t) / 2, width: span, height: t)
            } else {
                canvas.fill(x: (canvas.width - t) / 2, y: from, width: t, height: span)
            }
        }
    }

    // MARK: Arcs and diagonals

    static func drawArc(_ scalar: UInt32, into canvas: inout Canvas, light: Int) {
        let width = Double(canvas.width)
        let height = Double(canvas.height)
        let t = Double(light)
        let radius = max(2.0, min(width, height) / 2)
        let lineX = width / 2
        let lineY = height / 2
        // 256D right+down, 256E left+down, 256F left+up, 2570 right+up.
        let goesRight = scalar == 0x256D || scalar == 0x2570
        let goesDown = scalar == 0x256D || scalar == 0x256E
        let centerX = goesRight ? lineX + radius : lineX - radius
        let centerY = goesDown ? lineY + radius : lineY - radius
        for y in 0 ..< canvas.height {
            for x in 0 ..< canvas.width {
                let px = Double(x) + 0.5
                let py = Double(y) + 0.5
                let inQuadrant =
                    (goesRight ? px <= centerX : px >= centerX) && (goesDown ? py <= centerY : py >= centerY)
                guard inQuadrant else { continue }
                let distance = ((px - centerX) * (px - centerX) + (py - centerY) * (py - centerY)).squareRoot()
                let coverage = min(1, max(0, t / 2 + 0.5 - abs(distance - radius)))
                if coverage > 0 { canvas.plot(x: x, y: y, value: UInt8(coverage * 255)) }
            }
        }
        let stroke = light
        let verticalX = (canvas.width - stroke) / 2
        let horizontalY = (canvas.height - stroke) / 2
        let straightY = goesDown ? Int(centerY.rounded(.down)) : 0
        let straightHeight = goesDown ? canvas.height - straightY : Int(centerY.rounded(.up))
        canvas.fill(x: verticalX, y: straightY, width: stroke, height: straightHeight)
        let straightX = goesRight ? Int(centerX.rounded(.down)) : 0
        let straightWidth = goesRight ? canvas.width - straightX : Int(centerX.rounded(.up))
        canvas.fill(x: straightX, y: horizontalY, width: straightWidth, height: stroke)
    }

    static func drawDiagonals(_ scalar: UInt32, into canvas: inout Canvas, light: Int) {
        let width = Double(canvas.width)
        let height = Double(canvas.height)
        let t = Double(light)
        func line(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, into canvas: inout Canvas) {
            let dx = x1 - x0
            let dy = y1 - y0
            let length = (dx * dx + dy * dy).squareRoot()
            for y in 0 ..< canvas.height {
                for x in 0 ..< canvas.width {
                    let distance = abs((Double(x) + 0.5 - x0) * dy - (Double(y) + 0.5 - y0) * dx) / length
                    let coverage = min(1, max(0, t / 2 + 0.5 - distance))
                    if coverage > 0 { canvas.plot(x: x, y: y, value: UInt8(coverage * 255)) }
                }
            }
        }
        if scalar != 0x2572 { line(width, 0, 0, height, into: &canvas) }
        if scalar != 0x2571 { line(0, 0, width, height, into: &canvas) }
    }
}
