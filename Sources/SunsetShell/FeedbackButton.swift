package import SunsetRuntime
package import SwiftUI

/// A button with words that says what its click did: for a moment its title becomes what was done ("Copied", with a
/// check) or why not (with a cross), with the trackpad's tap and VoiceOver's announcement (`Feedback`).
package struct FeedbackButton: View {
    @Environment(\.runtime) var runtime

    let title: String
    let perform: () -> ActionFeedback
    @State private var feedback = FeedbackCue()

    package init(_ title: String, perform: @escaping () -> ActionFeedback) {
        self.title = title
        self.perform = perform
    }

    package var body: some View {
        Button {
            let outcome = perform()
            feedback.show(outcome)
            runtime.task {
                await runtime.sleep(for: ActionFeedback.shown)
                feedback.clear(outcome)
            }
        } label: {
            if let cue = feedback.cue {
                Label(cue.announcement, systemImage: cue.symbol)
            } else {
                Text(title)
            }
        }
        .animation(.snappy, value: feedback.cue)
        .accessibilityLabel(title)
    }
}
