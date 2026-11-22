import Foundation
import SunsetStorage

/// What only a test does to a vault: puts another record's sealed bytes in a slot, to check they do not open there.
extension VaultFile {
    /// The sealed bytes of `record` in `source` (this vault or another), written into this vault's slot `target`.
    func plant(_ record: UUID, of source: VaultFile, as target: UUID) throws(Failure) {
        guard
            let sealed = source.sql.column("SELECT sealed FROM records WHERE id = ?", [.text(record.uuidString)]).first,
            sql.run("INSERT OR REPLACE INTO records VALUES (?, ?)", [.text(target.uuidString), .blob(sealed)])
        else { throw .cannotOpen }
    }
}
