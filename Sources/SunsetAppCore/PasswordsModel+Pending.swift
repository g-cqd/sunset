package import SunsetCredentials

extension PasswordsModel {
    /// Notes `entry` as edited and not kept yet: it is kept before the vault locks, whatever the reason, and when Sunset
    /// loses focus (`keepPending`), besides what the page keeps itself a moment after each change (n138).
    package func noteEdit(_ entry: VaultEntry) {
        pending[entry.id] = entry
    }

    /// Keeps every edit noted (each one that fails stays noted).
    package func keepPending() {
        for entry in pending.values { try? save(entry) }
    }
}
