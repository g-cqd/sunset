/// A sidebar row's end (the owner, 2026-11-19): the close button, then the controls one after another, each the close button's
/// size with a gap: the cup, the sound, the microphone, the camera. Slot 0 is the close button's own place while it hides, and
/// the next one while it shows; the edited mark goes just before them, and the title stops before it all.
package struct RowEnd: Equatable {
    /// A button's side, and the gap between two.
    package let size: Double
    package let gap: Double
    package let closeShown: Bool
    /// How many controls there are besides the close button.
    package let controls: Int
    package let edited: Bool
    package let markWidth: Double
    /// The row's paddings: the title's start, and the button's end.
    package let leading: Double
    package let trailing: Double

    package init(
        size: Double,
        gap: Double,
        closeShown: Bool,
        controls: Int,
        edited: Bool,
        markWidth: Double,
        leading: Double,
        trailing: Double
    ) {
        self.size = size
        self.gap = gap
        self.closeShown = closeShown
        self.controls = controls
        self.edited = edited
        self.markWidth = markWidth
        self.leading = leading
        self.trailing = trailing
    }

    private var step: Double {
        size + gap
    }
    private var controlsRoom: Double {
        Double(controls) * step
    }
    private var markRoom: Double {
        markWidth + 2 * gap
    }

    /// How far control `index`'s centre is from the row's end, `middle` being half the row's height.
    package func inset(of index: Int, middle: Double) -> Double {
        middle + (closeShown ? step : 0) + Double(index) * step
    }

    /// How far the edited mark's centre is from the row's end.
    package func markInset(middle: Double) -> Double {
        if closeShown { return middle + size / 2 + markRoom / 2 + controlsRoom }
        if controls > 0 { return middle + size / 2 + markRoom / 2 + Double(controls - 1) * step }
        return leading + markWidth / 2
    }

    /// What the title leaves free at the row's end.
    package var titleEnd: Double {
        let mark = edited ? markRoom : 0
        if closeShown { return step + mark + controlsRoom }
        if controls > 0 { return max(0, leading - trailing) + step + Double(controls - 1) * step + mark }
        guard edited else { return 0 }
        return max(0, leading - trailing) + markWidth + gap
    }
}
