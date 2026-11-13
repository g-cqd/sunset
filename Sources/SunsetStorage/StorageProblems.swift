public import Observation

/// What did not read in this run, kept to be said to the person (R12). One entry per file.
@MainActor @Observable
public final class StorageProblems {
    public static let shared = StorageProblems()
    public private(set) var items: [StorageProblem] = []

    public init() {}

    public func report(_ problem: StorageProblem) {
        if !items.contains(problem) { items.append(problem) }
    }

    public func dismiss(_ problem: StorageProblem) { items.removeAll { $0 == problem } }
}
