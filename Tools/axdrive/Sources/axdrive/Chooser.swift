import Foundation
import FoundationModels

/// When the ranking cannot tell two elements apart, the on-device model (Apple's, nothing leaves the Mac) is asked which one a goal means.
enum Chooser {
    static func choose(goal: String, among matches: [Match]) async -> Int? {
        guard case .available = SystemLanguageModel.default.availability else {
            FileHandle.standardError.write(Data("axdrive: the on-device model is not available here\n".utf8))
            return nil
        }
        let list = matches.prefix(12).enumerated()
            .map { index, match in
                "\(index): \(match.node.summary) path \(match.node.path.split(separator: "/").suffix(4).joined(separator: "/"))"
            }
            .joined(separator: "\n")
        let session = LanguageModelSession(
            instructions:
                "You pick the user-interface element of a macOS app that best fits a goal. Answer with its number only."
        )
        let prompt = "Goal: \(goal)\nElements:\n\(list)\nNumber:"
        guard let answer = try? await session.respond(to: prompt).content else { return nil }
        let digits = answer.drop { !$0.isNumber }.prefix { $0.isNumber }
        guard let index = Int(digits), index < min(matches.count, 12) else { return nil }
        return index
    }
}
