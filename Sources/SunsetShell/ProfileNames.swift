/// The app's side: the name of the profile a saved page was loaded as (its state's `as`), for its mark while it is not
/// loaded (the owner, 2026-11-19).
@MainActor
package enum ProfileNames {
    package static var mark: (_ saved: String) -> String? = { _ in nil }
}
