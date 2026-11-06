extension BoxDrawing {
    // MARK: Straight arms

    struct Arms {
        var left: Int
        var right: Int
        var up: Int
        var down: Int
    }

    /// The sizes the arms are drawn with: the canvas, the light stroke, how thick the cross strokes are where arms meet (so each arm reaches the far
    /// side of the stroke it joins), and the double geometry (two strokes of `light` with a `light` gap, centred).
    struct Geometry {
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

    static func drawArms(_ arms: Arms, into canvas: inout Canvas, light: Int) {
        let geometry = Geometry(arms: arms, width: canvas.width, height: canvas.height, light: light)
        horizontal(arms.left, rightSide: false, opposite: arms.right, arms: arms, geometry, &canvas)
        horizontal(arms.right, rightSide: true, opposite: arms.left, arms: arms, geometry, &canvas)
        vertical(arms.up, downSide: false, opposite: arms.down, arms: arms, geometry, &canvas)
        vertical(arms.down, downSide: true, opposite: arms.up, arms: arms, geometry, &canvas)
    }

    static func horizontal(
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

    static func vertical(
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
}
