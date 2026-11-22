package import SunsetShellModel
package import SwiftUI

extension View {
    /// The alert while `isPresented`, in Sunset's look, over this view on a veil: what `.alert` and `.confirmationDialog`
    /// showed. `answer` gets the index of the button pressed; Escape and Return press what the alert says.
    package func sunsetAlert(
        isPresented: Binding<Bool>,
        _ alert: @autoclosure @escaping () -> SunsetAlert,
        answer: @escaping (Int) -> Void
    ) -> some View {
        overlay {
            if isPresented.wrappedValue {
                ZStack {
                    Color.black.opacity(Design.Fill.veil).ignoresSafeArea().contentShape(.rect).onTapGesture {}
                    SunsetAlertView(alert: alert()) { index in
                        SunsetAlertPress.press(index, isPresented: isPresented, answer: answer)
                    }
                }
                .transition(.opacity)
            }
        }
    }

    /// The alert while `item` is set, as `.alert(item:)`: `item` is cleared when a button is pressed, after `answer` has
    /// had it.
    package func sunsetAlert<Item>(
        item: Binding<Item?>,
        _ alert: @escaping (Item) -> SunsetAlert,
        answer: @escaping (Item, Int) -> Void
    ) -> some View {
        let presented = Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } })
        return overlay {
            if let shown = item.wrappedValue {
                ZStack {
                    Color.black.opacity(Design.Fill.veil).ignoresSafeArea().contentShape(.rect).onTapGesture {}
                    SunsetAlertView(alert: alert(shown)) { index in
                        answer(shown, index)
                        presented.wrappedValue = false
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
