import SunsetCredentials
import SunsetShell
import SwiftUI

/// A One-Time Code field read (roadmap 0093 E): the code now in two halves, monospaced, and a ring that empties as its
/// period runs out; under ten seconds left, the next code beside it. Redrawn each second by the system's timeline; its
/// value (the secret) is never shown. A value that is not a code says so.
struct OneTimeCodeValue: View {
    let field: OneTimeCodeField?

    var body: some View {
        if let field {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let left = field.secondsLeft(at: context.date)
                HStack(spacing: Design.Space.s) {
                    if let left, left <= Self.soon {
                        Text(OneTimeCodeField.spaced(field.next(at: context.date)))
                            .foregroundStyle(.tertiary)
                            .accessibilityLabel("Next code")
                    }
                    Text(OneTimeCodeField.spaced(field.code(at: context.date)))
                        .contentTransition(.numericText())
                        .animation(.smooth, value: field.code(at: context.date))
                    if let left, let period = field.period {
                        Circle()
                            .trim(from: 0, to: Double(left) / Double(period))
                            .stroke(left <= Self.soon ? Color.orange : Color.secondary, lineWidth: Self.ring)
                            .rotationEffect(.degrees(-90))
                            .frame(width: Design.Symbol.row, height: Design.Symbol.row)
                            .animation(.linear(duration: 1), value: left)
                            .accessibilityLabel("\(left) seconds left")
                    }
                }
                .font(Design.Text.body.monospacedDigit())
            }
        } else {
            Text("Not a one-time code").foregroundStyle(.secondary)
        }
    }

    /// Seconds before the change from which the next code shows and the ring turns.
    private static let soon = 10
    private static let ring = 2.0
}
