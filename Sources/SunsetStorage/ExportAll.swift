public import Foundation

/// Export All (R12, roadmap 0030 step ST-6): a dated folder in the folder the person chose, each part written in it, and one
/// sentence that says what was exported and what could not be. The app gives the parts: this target does not know documents
/// from a history.
public enum ExportAll {
    /// One part of an export: what is said of it when it was written, and what is said when something of it was not.
    public struct Step: Sendable, Equatable {
        public var said: String?
        public var problem: String?

        public init(said: String? = nil, problem: String? = nil) {
            self.said = said
            self.problem = problem
        }
    }

    public struct Outcome: Sendable, Equatable {
        /// Where the export is; nil when its folder could not be made.
        public var folder: URL?
        public var sentence: String
    }

    /// A part that is one file: written whole in `folder`, readable by the person's other programs (it is theirs now).
    public static func file(_ data: Data, named name: String, in folder: URL, said: String) -> Step {
        do {
            try StoredFile.write(data, to: folder.appending(path: name).path, durability: .ordered, permissions: 0o644)
            return Step(said: said)
        } catch {
            return Step(problem: "\(name) could not be written.")
        }
    }

    /// Makes the export's folder in `parent` and runs `steps` on it; a step that is nil had nothing to export.
    public static func run(
        into parent: URL,
        now: Date = Date(),
        calendar: Calendar = .current,
        steps: (URL) -> [Step?]
    ) -> Outcome {
        guard let folder = try? ExportFolder.make(in: parent, now: now, calendar: calendar) else {
            return Outcome(folder: nil, sentence: "The export's folder could not be made in \(parent.path).")
        }
        let done = steps(folder).compactMap(\.self)
        let said = done.compactMap(\.said)
        let what = said.isEmpty ? "There was nothing to export." : "Exported \(joined(said)), as plain files."
        return Outcome(folder: folder, sentence: ([what] + done.compactMap(\.problem)).joined(separator: " "))
    }

    /// "a", "a and b", "a, b and c".
    private static func joined(_ parts: [String]) -> String {
        guard parts.count > 1, let last = parts.last else { return parts.first ?? "" }
        return parts.dropLast().joined(separator: ", ") + " and " + last
    }
}
