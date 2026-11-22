package import SwiftUI

/// A kind of tab content that makes its view: apart from `PaneContent`, which the window's model holds and which knows
/// no UI framework.
@MainActor
package protocol PaneViewMaking {
    func makeView(_ context: PaneViewContext) -> AnyView
}
