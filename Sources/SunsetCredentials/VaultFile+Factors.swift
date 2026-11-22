public import Foundation
import SunsetStorage

/// A vault's factors, kept in its file: for each, the vault's key wrapped by that factor's key (sealed, bound to the vault
/// and the factor), and what that key is derived again from (a password's salt and cost, the Secure Enclave key's blob).
/// None of it opens anything alone; a slot changed refuses to unwrap.
extension VaultFile {
    /// One factor's slot.
    public struct FactorSlot: Equatable, Sendable, Codable {
        public var factor: Vault.Factor
        public var wrapped: WrappedKey
        public var salt: Data?
        public var cost: MasterPassword.Cost?
        public var touchID: Data?

        public init(
            factor: Vault.Factor,
            wrapped: WrappedKey,
            salt: Data? = nil,
            cost: MasterPassword.Cost? = nil,
            touchID: Data? = nil
        ) {
            self.factor = factor
            self.wrapped = wrapped
            self.salt = salt
            self.cost = cost
            self.touchID = touchID
        }
    }

    /// The factors, in the order they were added; none for a vault made before any.
    public func factorSlots() throws(Failure) -> [FactorSlot] {
        guard let data = sql.column("SELECT value FROM vault WHERE name = 'factors'").first else { return [] }
        guard let slots = try? JSONDecoder().decode([FactorSlot].self, from: data) else { throw .damaged }
        return slots
    }

    public func setFactorSlots(_ slots: [FactorSlot]) throws(Failure) {
        guard let data = try? JSONEncoder().encode(slots),
            sql.run("INSERT OR REPLACE INTO vault VALUES ('factors', ?)", [.blob(data)])
        else { throw .cannotOpen }
    }
}
