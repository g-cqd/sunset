import SunsetShellModel

extension WebContent {
    /// How many calls share this page now (ADR-0082): `SharedPanes`, as for every kind.
    package var sharedInto: Int {
        SharedPanes.shared.count(self)
    }
}
