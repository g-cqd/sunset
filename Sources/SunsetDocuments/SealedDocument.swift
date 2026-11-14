import Foundation
import SunsetStorage

/// A document's sealed file (R12 step ST-4): one line that says what it is (its kind, when it was made), then its text. Sealed
/// whole under the document's identifier, so that one document's file cannot stand for another's.
struct SealedDocument {
    private struct Head: Codable {
        var version = 1
        var kind: DocumentKind
        var created: Double
    }

    var kind: DocumentKind
    var created: Date
    var text: String

    func sealed(_ seal: Seal, id: UUID) throws(SealFailure) -> Data {
        let head = (try? JSONEncoder().encode(Head(kind: kind, created: created.timeIntervalSince1970))) ?? Data()
        return try seal.seal(head + [10] + Data(text.utf8), identity: id.uuidString)
    }

    init(kind: DocumentKind, created: Date, text: String) {
        self.kind = kind
        self.created = created
        self.text = text
    }

    /// Opens a sealed file; `SealFailure.damaged` too for what opens and is not a document.
    init(_ sealed: Data, seal: Seal, id: UUID) throws(SealFailure) {
        let plain = try seal.open(sealed, identity: id.uuidString)
        guard let line = plain.firstIndex(of: 10),
            let head = try? JSONDecoder().decode(Head.self, from: plain[..<line]), head.version == 1
        else { throw .damaged }
        kind = head.kind
        created = Date(timeIntervalSince1970: head.created)
        text = String(decoding: plain[(line + 1)...], as: UTF8.self)
    }
}
