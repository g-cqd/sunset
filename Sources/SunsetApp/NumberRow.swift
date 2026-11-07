import SwiftUI

/// A numeric setting: a field to type any value in, and a stepper to nudge it by `step`. A value outside `range` is brought inside it when it is committed; text
/// that is not a number is refused by the field and the old value comes back.
struct NumberRow: View {
    let name: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    var unit = ""
    /// Digits after the decimal point that the field shows at most.
    var fractionDigits = 2

    var body: some View {
        LabeledContent(name) {
            HStack(spacing: 6) {
                TextField(name, value: clamped, format: .number.precision(.fractionLength(0 ... fractionDigits)))
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 80)
                Stepper(name, value: clamped, in: range, step: step).labelsHidden()
                if !unit.isEmpty { Text(unit).foregroundStyle(.secondary).frame(minWidth: 22, alignment: .leading) }
            }
        }
    }

    private var clamped: Binding<Double> {
        Binding(
            get: { value.wrappedValue },
            set: { new in
                guard new.isFinite else { return }
                value.wrappedValue = min(max(new, range.lowerBound), range.upperBound)
            }
        )
    }
}
