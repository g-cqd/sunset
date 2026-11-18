package import SwiftUI

/// A button with words that says what its click did (the owner's note n11): for a moment its title becomes what was done
/// ("Copied", with a check) or why not (with a cross), with the trackpad's tap and VoiceOver's announcement (`Feedback`).
package struct FeedbackButton: View {
    let title: String
    let perform: () -> ActionFeedback
    @State private var cue: ActionFeedback?

    package init(_ title: String, perform: @escaping () -> ActionFeedback) {
        self.title = title
        self.perform = perform
    }

    package var body: some View {
        Button {
            let outcome = perform()
            Feedback.give(outcome)
            cue = outcome
            Task {
                try? await Task.sleep(for: ActionFeedback.shown)
                if cue == outcome { cue = nil }
            }
        } label: {
            if let cue {
                Label(cue.announcement, systemImage: cue.symbol)
            } else {
                Text(title)
            }
        }
        .animation(.snappy, value: cue)
        .accessibilityLabel(title)
    }
}
