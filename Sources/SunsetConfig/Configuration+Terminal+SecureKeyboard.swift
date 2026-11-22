extension Configuration.Terminal {
    /// When keys typed in the terminal are kept from other apps' event taps.
    public enum SecureKeyboard: String, Sendable, Equatable, CaseIterable {
        case off, whenPassword, always

        /// Held only for the pane that has the keyboard in the window in front: by the setting, and whether its program
        /// asks for a password.
        public func holds(asking: Bool, focused: Bool) -> Bool {
            guard focused else { return false }
            switch self {
                case .off: return false
                case .whenPassword: return asking
                case .always: return true
            }
        }
    }
}
