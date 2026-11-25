package import Observation

/// Common find-bar contract satisfied by both `PageFind` (web pages) and `TerminalFind` (terminal scrollback, T-3),
/// allowing `FindBarView` to render both without duplicating SwiftUI glue.
@MainActor
package protocol FindBarModel: AnyObject, Observable {
    var findPrompt: String { get }
    var text: String { get set }
    var status: String { get }
    var isFindError: Bool { get }
    var focusRequest: Int { get }
    var findIconSymbol: String { get }
    var matchCase: Bool { get set }
    var secondaryOptionTitle: String { get }
    var secondaryOption: Bool { get set }
    func findTextChanged()
    func findOptionsChanged()
    func findStep(backwards: Bool)
    func findClose()
}
