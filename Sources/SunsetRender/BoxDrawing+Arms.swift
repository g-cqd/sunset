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
        let across = Axis.horizontal(geometry, arms)
        let along = Axis.vertical(geometry, arms)
        arm(arms.left, far: false, opposite: arms.right, across, &canvas)
        arm(arms.right, far: true, opposite: arms.left, across, &canvas)
        arm(arms.up, far: false, opposite: arms.down, along, &canvas)
        arm(arms.down, far: true, opposite: arms.up, along, &canvas)
    }

    /// One direction the arms are drawn in, its measures named along it and across it: the horizontal arms' are the cell's,
    /// the vertical arms' the same transposed (the two were one algorithm written twice).
    struct Axis {
        /// The cell along the arm, and across it.
        var length: Int
        var breadth: Int
        var light: Int
        /// How thick the strokes that cross this one are, and whether they are doubled.
        var crossMax: Int
        var crossDoubled: Bool
        /// Where a doubled arm's two lines are, across it; where a doubled crossing stroke's two lines are, along it.
        var firstAcross: Int
        var secondAcross: Int
        var firstAlong: Int
        var secondAlong: Int
        /// The crossing arms on the first and the second line's side.
        var firstPerpendicular: Int
        var secondPerpendicular: Int
        var transposed: Bool

        static func horizontal(_ g: Geometry, _ arms: Arms) -> Axis {
            Axis(
                length: g.width,
                breadth: g.height,
                light: g.light,
                crossMax: g.verticalMax,
                crossDoubled: g.verticalDoubled,
                firstAcross: g.firstY,
                secondAcross: g.secondY,
                firstAlong: g.firstX,
                secondAlong: g.secondX,
                firstPerpendicular: arms.up,
                secondPerpendicular: arms.down,
                transposed: false
            )
        }

        static func vertical(_ g: Geometry, _ arms: Arms) -> Axis {
            Axis(
                length: g.height,
                breadth: g.width,
                light: g.light,
                crossMax: g.horizontalMax,
                crossDoubled: g.horizontalDoubled,
                firstAcross: g.firstX,
                secondAcross: g.secondX,
                firstAlong: g.firstY,
                secondAlong: g.secondY,
                firstPerpendicular: arms.left,
                secondPerpendicular: arms.right,
                transposed: true
            )
        }

        /// Fills a rectangle given along and across the arm.
        func fill(_ canvas: inout Canvas, along: Int, across: Int, length: Int, breadth: Int) {
            if transposed {
                canvas.fill(x: across, y: along, width: breadth, height: length)
            } else {
                canvas.fill(x: along, y: across, width: length, height: breadth)
            }
        }
    }

    /// One arm: from the cell's near edge to the centre, or (`far`) from the centre to the far edge.
    static func arm(_ weight: Int, far: Bool, opposite: Int, _ a: Axis, _ canvas: inout Canvas) {
        guard weight != none else { return }
        if weight != double {
            let t = thickness(weight, a.light)
            let across = (a.breadth - t) / 2
            let reach = (a.length - a.crossMax) / 2
            if far {
                a.fill(&canvas, along: reach, across: across, length: a.length - reach, breadth: t)
            } else {
                a.fill(&canvas, along: 0, across: across, length: (a.length + a.crossMax) / 2, breadth: t)
            }
            return
        }
        for first in [true, false] {
            let perpendicular = first ? a.firstPerpendicular : a.secondPerpendicular
            let edge: Int  // where this line stops at the centre
            if !a.crossDoubled {
                edge =
                    a.crossMax == 0
                    ? (far ? a.length / 2 - 1 : a.length / 2 + 1)
                    : (far ? (a.length - a.crossMax) / 2 : (a.length + a.crossMax) / 2)
            } else if perpendicular == double {
                edge = far ? a.secondAlong : a.firstAlong + a.light
            } else if opposite != none {
                edge = far ? a.length / 2 - 1 : a.length / 2 + 1
            } else {
                edge = far ? a.firstAlong : a.secondAlong + a.light
            }
            let across = first ? a.firstAcross : a.secondAcross
            if far {
                a.fill(&canvas, along: edge, across: across, length: a.length - edge, breadth: a.light)
            } else {
                a.fill(&canvas, along: 0, across: across, length: edge, breadth: a.light)
            }
        }
    }
}
