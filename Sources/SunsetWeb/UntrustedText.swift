/// Text that came from a page or a server, to show as one line (white paper §9): without characters that do not show or that
/// turn the text around (control and format characters, line separators).
enum UntrustedText {
    static func oneLine(_ raw: String) -> String {
        var scalars = String.UnicodeScalarView()
        scalars.append(contentsOf: raw.unicodeScalars.filter(shows))
        return String(scalars)
    }

    private static func shows(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.properties.generalCategory {
            case .control, .format, .lineSeparator, .paragraphSeparator, .surrogate, .privateUse, .unassigned: false
            default: true
        }
    }
}
