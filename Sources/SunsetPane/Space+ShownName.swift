import Foundation

extension Space {
    /// What names it where it is shown (the Spaces menu, the question before deleting it): the unnamed Space of before
    /// there were Spaces is Home.
    public var shownName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Home" : trimmed
    }
}
