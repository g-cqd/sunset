import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner's note n9 (2026-11-18): "the address bar clip the text and the cursor does not even appear on the last position,
/// plus if being edited the copy and reload button should not even show".
@Suite("The address field's buttons at its end")
@MainActor
struct AddressFieldActionsTests {
    @Test func `shown under the pointer or while loading, never while typed in`() {
        #expect(AddressField.showsActions(reload: true, hovering: true, loading: false, editing: false))
        #expect(AddressField.showsActions(reload: true, hovering: false, loading: true, editing: false))
        #expect(!AddressField.showsActions(reload: true, hovering: true, loading: true, editing: true))
        #expect(!AddressField.showsActions(reload: false, hovering: true, loading: true, editing: false))
    }
}
