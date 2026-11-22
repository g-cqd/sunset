package import SunsetRuntime
package import SwiftUI

extension EnvironmentValues {
    /// Where a view's tasks are spawned and the clock it waits on; `.live` unless a test or a preview sets another.
    @Entry package var runtime = Runtime.live
}
