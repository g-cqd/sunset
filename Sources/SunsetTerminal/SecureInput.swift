import Carbon.HIToolbox

/// The process's secure keyboard entry: on while any terminal holds it. `EnableSecureEventInput` counts its calls, so
/// this calls it once when the first holder comes and `DisableSecureEventInput` once when the last goes.
@MainActor
package enum SecureInput {
    private static var holders = Set<ObjectIdentifier>()

    package static var isOn: Bool {
        !holders.isEmpty
    }

    package static func set(_ hold: Bool, for holder: ObjectIdentifier) {
        let was = isOn
        if hold { holders.insert(holder) } else { holders.remove(holder) }
        guard isOn != was else { return }
        if isOn { EnableSecureEventInput() } else { DisableSecureEventInput() }
    }
}
