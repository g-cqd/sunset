extension Configuration.Appearance {
    /// The app's icon (roadmap 0084 F): one of the four skies built into the asset catalog, `App/<assetName>.icon`.
    public enum Icon: String, Sendable, Equatable, CaseIterable {
        case sunset, twilight, dawn, dusk

        /// The icon's name in the asset catalog (the bundle's own for `sunset`, an alternate for the others).
        public var assetName: String {
            rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }
    }
}
