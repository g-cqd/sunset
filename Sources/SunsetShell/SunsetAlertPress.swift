package import SwiftUI

/// A button of a Sunset alert pressed: what the alert was about is answered, then the alert goes. In that order: an
/// answer reads the state that shows the alert (which Space is being deleted), as SwiftUI's own alerts let it. An answer
/// that asks again through the same state must do so later (a flag cannot tell the second question from the first).
package enum SunsetAlertPress {
    package static func press(_ index: Int, isPresented: Binding<Bool>, answer: (Int) -> Void) {
        answer(index)
        isPresented.wrappedValue = false
    }
}
