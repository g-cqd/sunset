import SunsetConfig
import SwiftUI

extension Configuration.Side {
    /// The SwiftUI edge and alignment of the window edge.
    var edge: Edge.Set { self == .left ? .leading : .trailing }
    var alignment: Alignment { self == .left ? .leading : .trailing }
    var moveEdge: Edge { self == .left ? .leading : .trailing }
}
