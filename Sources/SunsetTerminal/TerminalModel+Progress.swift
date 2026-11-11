package import SunsetCore

extension TerminalModel {
    /// A progress state as a fraction, nil when there is none (indeterminate shows as nil too: a bar has nothing to fill).
    package static func fraction(of state: ProgressState) -> Double? {
        switch state {
            case .hidden, .indeterminate: nil
            case .normal(let percent), .error(let percent), .paused(let percent):
                Double(min(max(percent, 0), 100)) / 100
        }
    }
}
