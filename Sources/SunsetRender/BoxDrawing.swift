/// U+2500...U+257F. Each glyph is up to four arms (left, right, up, down) of a weight: light, heavy or double; a few are dashed, rounded or diagonal.
enum BoxDrawing {
    /// Arm weights.
    static let none = 0
    static let light = 1
    static let heavy = 2
    static let double = 3

    /// "lrud" weights per scalar, as digits (the standard's charts in order); scalars not listed are special (dashes, arcs, diagonals).
    static let arms: [UInt32: [Int]] = {
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

    static func thickness(_ weight: Int, _ light: Int) -> Int { weight == heavy ? 2 * light : light }
}
