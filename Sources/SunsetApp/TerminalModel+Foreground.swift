import SunsetHost

extension TerminalModel {
    /// Looks at which program is in front soon after the screen changed (a program starts or ends with output, but the terminal's foreground group changes a
    /// moment after the output that announced it): one look per burst of changes, not one per frame.
    func checkForeground() {
        guard foregroundCheck == nil, let session else { return }
        foregroundCheck = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            let name = session.foregroundCommand()
            guard let self else { return }
            foregroundCheck = nil
            if name != foregroundCommand { foregroundCommand = name }
        }
    }
}
