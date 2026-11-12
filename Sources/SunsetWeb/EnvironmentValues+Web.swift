package import SwiftUI

extension EnvironmentValues {
    /// Each page shows a row with its address at its top (`web.address` = pane).
    @Entry package var webAddressRow = false
    /// What is being typed in the window's address fields, for their list.
    @Entry package var addressTyping: AddressTyping?
}
