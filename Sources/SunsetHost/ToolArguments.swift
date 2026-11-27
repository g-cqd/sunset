/// The arguments of one of Sunset's command-line tools (`sunset-run`, `sunset-render`): options, each with its value, then
/// a command, after `--` or from the first argument no option takes.
public struct ToolArguments {
    private var rest: [String]
    /// The command to run, once reached.
    public private(set) var command: [String] = []

    public init(_ arguments: [String]) {
        rest = arguments
    }

    /// The next option; nil once the options are done (after `--`, the rest is the command).
    public mutating func next() -> String? {
        guard !rest.isEmpty else { return nil }
        let first = rest.removeFirst()
        guard first != "--" else {
            command = rest
            rest = []
            return nil
        }
        return first
    }

    /// `argument` is no option: the command starts with it.
    public mutating func commandStarts(with argument: String) {
        command = [argument] + rest
        rest = []
    }

    /// The option's value: the next argument ("" when there is none).
    public mutating func value() -> String {
        rest.isEmpty ? "" : rest.removeFirst()
    }

    /// The option's value as a whole number, else `fallback`.
    public mutating func int(or fallback: Int) -> Int {
        Int(value()) ?? fallback
    }
}
