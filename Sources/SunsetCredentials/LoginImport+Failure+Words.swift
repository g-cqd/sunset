extension LoginImport.Failure {
    /// What the person is told when the file cannot be read.
    public var words: (title: String, detail: String) {
        switch self {
            case .noLoginColumns:
                (
                    "This is not a file of logins",
                    "It has no password column. Sunset reads the CSV that Apple Passwords, Chrome, Edge, Brave, Firefox, Bitwarden, "
                        + "1Password and LastPass export, and Bitwarden's JSON."
                )
            case .notAnExport:
                (
                    "This is not a Bitwarden export",
                    "It is not the JSON that Bitwarden writes: it may be damaged, or from another program. "
                        + "Export it again from Bitwarden as .json."
                )
            case .encrypted:
                (
                    "This export is protected with a password",
                    "Sunset reads Bitwarden's plain export. In Bitwarden, export again and choose .json, not .json (Encrypted): "
                        + "the file is then unencrypted, so delete it once it is imported."
                )
        }
    }
}
