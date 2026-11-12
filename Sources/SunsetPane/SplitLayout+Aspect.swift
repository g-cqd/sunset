public import CoreGraphics

extension SplitLayout {
    /// The shape of the whole area the layout fills (height over width), from the sizes some of its panes were drawn at: a pane that took a fraction
    /// of the width drew that fraction of the area (owner note n58: a tab's preview in the proportions of its window). The panes' answers are averaged;
    /// nil without any.
    public func aspect(drawn sizes: [PaneID: CGSize]) -> Double? {
        let unit = frames(in: CGRect(x: 0, y: 0, width: 1, height: 1))
        var widths: [Double] = []
        var heights: [Double] = []
        for (pane, size) in sizes {
            guard let share = unit[pane], share.width > 0, share.height > 0, size.width > 0, size.height > 0 else {
                continue
            }
            widths.append(Double(size.width / share.width))
            heights.append(Double(size.height / share.height))
        }
        guard !widths.isEmpty else { return nil }
        return (heights.reduce(0, +) / Double(heights.count)) / (widths.reduce(0, +) / Double(widths.count))
    }
}
