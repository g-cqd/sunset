package import SwiftUI

extension EnvironmentValues {
    /// The corner of the fields and buttons inside a container that sets it (a capsule bar group: half their height, so that they
    /// are capsules concentric with it); nil for the leaf radius.
    @Entry package var controlRadius: Double?
}
