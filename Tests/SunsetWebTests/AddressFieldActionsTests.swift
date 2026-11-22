import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// While the field is typed in, Copy and Reload do not show, so the text and the caret reach its end.
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
