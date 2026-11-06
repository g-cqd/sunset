/// U+2500...U+257F. Each glyph is up to four arms (left, right, up, down) of a weight: light, heavy or double; a few are dashed, rounded or diagonal.
enum BoxDrawing {
    /// Arm weights.
    static let none = 0
    static let light = 1
    static let heavy = 2
    static let double = 3

    /// "lrud" weights per scalar, as digits (the standard's charts in order); scalars not listed are special (dashes, arcs, diagonals).
    private static let arms: [UInt32: [Int]] = {
        let table = """
            2500 1100 2501 2200 2502 0011 2503 0022 250C 0101 250D 0201 250E 0102 250F 0202 2510 1001 2511 2001 2512 1002 2513 2002
            2514 0110 2515 0210 2516 0120 2517 0220 2518 1010 2519 2010 251A 1020 251B 2020
            251C 0111 251D 0211 251E 0121 251F 0112 2520 0122 2521 0221 2522 0212 2523 0222
            2524 1011 2525 2011 2526 1021 2527 1012 2528 1022 2529 2021 252A 2012 252B 2022
            252C 1101 252D 2101 252E 1201 252F 2201 2530 1102 2531 2102 2532 1202 2533 2202
            2534 1110 2535 2110 2536 1210 2537 2210 2538 1120 2539 2120 253A 1220 253B 2220
            253C 1111 253D 2111 253E 1211 253F 2211 2540 1121 2541 1112 2542 1122 2543 2121 2544 1221 2545 2112 2546 1212 2547 2221 2548 2212 2549 2122 254A 1222 254B 2222
            2550 3300 2551 0033 2552 0301 2553 0103 2554 0303 2555 3001 2556 1003 2557 3003 2558 0310 2559 0130 255A 0330 255B 3010 255C 1030 255D 3030
            255E 0311 255F 0133 2560 0333 2561 3011 2562 1033 2563 3033 2564 3301 2565 1103 2566 3303 2567 3310 2568 1130 2569 3330 256A 3311 256B 1133 256C 3333
            2574 1000 2575 0010 2576 0100 2577 0001 2578 2000 2579 0020 257A 0200 257B 0002 257C 1200 257D 0012 257E 2100 257F 0021
            """
        var result: [UInt32: [Int]] = [:]
        let words = table.split(whereSeparator: { $0 == " " || $0 == "\n" })
        var index = 0
        while index + 1 < words.count {
            if let code = UInt32(words[index], radix: 16) {
                result[code] = words[index + 1].compactMap { $0.wholeNumberValue }
            }
            index += 2
        }
        return result
    }()

    /// The arm weights of a glyph in the table (for tests), or zeros.
    static func testingArms(_ scalar: UInt32) -> [Int] { arms[scalar] ?? [0, 0, 0, 0] }

    /// Draws the glyph; false when `scalar` is not one of this block's.
    static func draw(_ scalar: UInt32, into canvas: inout Canvas, metrics: RenderMetrics) -> Bool {
        let light = max(1, (metrics.cellWidth + 4) / 8)
        switch scalar {
            case 0x2504 ... 0x250B, 0x254C ... 0x254F: drawDashes(scalar, into: &canvas, light: light)
            case 0x256D ... 0x2570: drawArc(scalar, into: &canvas, light: light)
            case 0x2571 ... 0x2573: drawDiagonals(scalar, into: &canvas, light: light)
            default:
                guard let weights = arms[scalar] else { return false }
                drawArms(
                    Arms(left: weights[0], right: weights[1], up: weights[2], down: weights[3]),
                    into: &canvas,
                    light: light
                )
        }
        return true
    }

    fileprivate static func thickness(_ weight: Int, _ light: Int) -> Int { weight == heavy ? 2 * light : light }

    // MARK: Straight arms

    private struct Arms {
        var left: Int
        var right: Int
        var up: Int
        var down: Int
    }

    /// The sizes the arms are drawn with: the canvas, the light stroke, how thick the cross strokes are where arms meet (so each arm reaches the far
    /// side of the stroke it joins), and the double geometry (two strokes of `light` with a `light` gap, centred).
    private struct Geometry {
        var width: Int
        var height: Int
        var light: Int
        var verticalMax: Int
        var horizontalMax: Int
        var firstX: Int
        var secondX: Int
        var firstY: Int
        var secondY: Int
        var horizontalDoubled: Bool
        var verticalDoubled: Bool

        init(arms: Arms, width: Int, height: Int, light: Int) {
            func span(_ weight: Int) -> Int {
                weight == BoxDrawing.double ? 3 * light : BoxDrawing.thickness(weight, light)
            }
            self.width = width
            self.height = height
            self.light = light
            verticalMax =
                (arms.up == BoxDrawing.none && arms.down == BoxDrawing.none) ? 0 : max(span(arms.up), span(arms.down))
            horizontalMax =
                (arms.left == BoxDrawing.none && arms.right == BoxDrawing.none)
                ? 0 : max(span(arms.left), span(arms.right))
            firstX = (width - 3 * light) / 2
            secondX = firstX + 2 * light
            firstY = (height - 3 * light) / 2
            secondY = firstY + 2 * light
            horizontalDoubled = arms.left == BoxDrawing.double || arms.right == BoxDrawing.double
            verticalDoubled = arms.up == BoxDrawing.double || arms.down == BoxDrawing.double
        }
    }

    private static func drawArms(_ arms: Arms, into canvas: inout Canvas, light: Int) {
        let geometry = Geometry(arms: arms, width: canvas.width, height: canvas.height, light: light)
        horizontal(arms.left, rightSide: false, opposite: arms.right, arms: arms, geometry, &canvas)
        horizontal(arms.right, rightSide: true, opposite: arms.left, arms: arms, geometry, &canvas)
        vertical(arms.up, downSide: false, opposite: arms.down, arms: arms, geometry, &canvas)
        vertical(arms.down, downSide: true, opposite: arms.up, arms: arms, geometry, &canvas)
    }

    private static func horizontal(
        _ weight: Int,
        rightSide: Bool,
        opposite: Int,
        arms: Arms,
        _ g: Geometry,
        _ canvas: inout Canvas
    ) {
        guard weight != none else { return }
        if weight != double {
            let t = thickness(weight, g.light)
            let y = (g.height - t) / 2
            let reach = (g.width - g.verticalMax) / 2
            if rightSide {
                canvas.fill(x: reach, y: y, width: g.width - reach, height: t)
            } else {
                canvas.fill(x: 0, y: y, width: (g.width + g.verticalMax) / 2, height: t)
            }
            return
        }
        for upper in [true, false] {
            let perpendicular = upper ? arms.up : arms.down
            let edge: Int  // where this line stops at the centre
            if !g.verticalDoubled {
                edge =
                    g.verticalMax == 0
                    ? (rightSide ? g.width / 2 - 1 : g.width / 2 + 1)
                    : (rightSide ? (g.width - g.verticalMax) / 2 : (g.width + g.verticalMax) / 2)
            } else if perpendicular == double {
                edge = rightSide ? g.secondX : g.firstX + g.light
            } else if opposite != none {
                edge = rightSide ? g.width / 2 - 1 : g.width / 2 + 1
            } else {
                edge = rightSide ? g.firstX : g.secondX + g.light
            }
            let y = upper ? g.firstY : g.secondY
            if rightSide {
                canvas.fill(x: edge, y: y, width: g.width - edge, height: g.light)
            } else {
                canvas.fill(x: 0, y: y, width: edge, height: g.light)
            }
        }
    }

    private static func vertical(
        _ weight: Int,
        downSide: Bool,
        opposite: Int,
        arms: Arms,
        _ g: Geometry,
        _ canvas: inout Canvas
    ) {
        guard weight != none else { return }
        if weight != double {
            let t = thickness(weight, g.light)
            let x = (g.width - t) / 2
            let reach = (g.height - g.horizontalMax) / 2
            if downSide {
                canvas.fill(x: x, y: reach, width: t, height: g.height - reach)
            } else {
                canvas.fill(x: x, y: 0, width: t, height: (g.height + g.horizontalMax) / 2)
            }
            return
        }
        for leftLine in [true, false] {
            let perpendicular = leftLine ? arms.left : arms.right
            let edge: Int
            if !g.horizontalDoubled {
                edge =
                    g.horizontalMax == 0
                    ? (downSide ? g.height / 2 - 1 : g.height / 2 + 1)
                    : (downSide ? (g.height - g.horizontalMax) / 2 : (g.height + g.horizontalMax) / 2)
            } else if perpendicular == double {
                edge = downSide ? g.secondY : g.firstY + g.light
            } else if opposite != none {
                edge = downSide ? g.height / 2 - 1 : g.height / 2 + 1
            } else {
                edge = downSide ? g.firstY : g.secondY + g.light
            }
            let x = leftLine ? g.firstX : g.secondX
            if downSide {
                canvas.fill(x: x, y: edge, width: g.light, height: g.height - edge)
            } else {
                canvas.fill(x: x, y: 0, width: g.light, height: edge)
            }
        }
    }

    // MARK: Dashes

    private static func drawDashes(_ scalar: UInt32, into canvas: inout Canvas, light: Int) {
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

    private static func drawArc(_ scalar: UInt32, into canvas: inout Canvas, light: Int) {
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

    private static func drawDiagonals(_ scalar: UInt32, into canvas: inout Canvas, light: Int) {
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
