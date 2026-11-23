/// Whether a field's value fits a kind it is to be given (t334): as it is, or not (and why), in which case the change is
/// asked about first and the value can be kept elsewhere.
public enum FieldFit: Equatable, Sendable {
    case fits
    /// It does not fit: what the person is told ("it is not a date").
    case loses(String)
}
