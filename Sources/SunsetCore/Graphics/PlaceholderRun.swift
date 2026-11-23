/// Placeholder cells side by side on a line that draw one row of an image (roadmap 0010 E): `count` cells from screen column
/// `column`, showing the image's virtual columns from `imageColumn`, in its virtual row `imageRow`.
struct PlaceholderRun: Equatable {
    let image: UInt32
    let placement: UInt32
    let imageRow: Int
    let imageColumn: Int
    let column: Int
    var count: Int

    /// Whether `next` continues the run below it: the same image, columns and cells, one virtual row further.
    func isAbove(_ next: PlaceholderRun) -> Bool {
        next.image == image && next.placement == placement && next.column == column && next.count == count
            && next.imageColumn == imageColumn && next.imageRow == imageRow + 1
    }
}
