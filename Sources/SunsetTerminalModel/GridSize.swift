/// A terminal's size in cells, and a cell's size in device pixels (0 when not known): programs size their images by it.
package struct GridSize: Sendable, Equatable {
    package var columns: Int
    package var rows: Int
    package var cellWidth = 0
    package var cellHeight = 0
}
