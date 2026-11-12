public import SunsetMetrics

extension LayoutMetrics {
    /// One numeric metric (a key path to a plain `Double`, which is why `@unchecked Sendable` is sound): its key, a title for Settings, the range it accepts and the step of its stepper.
    public struct Field: @unchecked Sendable {
        public let key: String
        public let title: String
        public let keywords: [String]
        public let range: ClosedRange<Double>
        public let step: Double
        public let unit: String
        public let path: WritableKeyPath<LayoutMetrics, Double>
    }
}
