import Foundation

/// The order of a column's cells: numerically when both are numbers, else as Finder sorts names.
struct CellOrder: SortComparator {
    let column: Int
    var order = SortOrder.forward

    func compare(_ lhs: TableRow, _ rhs: TableRow) -> ComparisonResult {
        let (left, right) = (lhs.cell(column), rhs.cell(column))
        let result: ComparisonResult =
            if let first = Double(left), let second = Double(right) {
                first < second ? .orderedAscending : first > second ? .orderedDescending : .orderedSame
            } else {
                left.localizedStandardCompare(right)
            }
        return order == .forward ? result : result.reversed
    }
}

extension ComparisonResult {
    fileprivate var reversed: Self {
        switch self {
            case .orderedAscending: .orderedDescending
            case .orderedDescending: .orderedAscending
            case .orderedSame: .orderedSame
        }
    }
}
