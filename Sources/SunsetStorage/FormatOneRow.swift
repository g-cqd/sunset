import Foundation

/// A record as format 1 kept it.
struct FormatOneRow {
    let kind: String
    let key: Data
    let sealed: Data
    let sort: Double
    let count: Int
}
