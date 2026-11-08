import SunsetPane
import SwiftUI

extension PaneEdge {
    var swiftUI: Edge {
        switch self {
            case .left: .leading
            case .right: .trailing
            case .top: .top
            case .bottom: .bottom
        }
    }

    var alignment: Alignment {
        switch self {
            case .left: .leading
            case .right: .trailing
            case .top: .top
            case .bottom: .bottom
        }
    }
}
