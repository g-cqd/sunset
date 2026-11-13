import SunsetConfig

/// Where the window's traffic lights are and whether they show: `x` points from the window's `side` edge to the near edge of the close button, `y` from the top.
struct LightsPlacement: Equatable {
    var x: Double
    var y: Double
    var visible: Bool
    var side = Configuration.Side.left
    /// `y` is where the buttons' middle goes, not their top.
    var centred = false
}
