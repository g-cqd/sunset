import LocalAuthentication
import SunsetAppCore
import SunsetCredentials
import SunsetShell
import SwiftUI

/// Setting up the vault (ADR-0116): Touch ID first when this Mac has it, a master password typed twice as its fallback,
/// then the recovery code, shown this once.
struct PasswordsSetupSheet: View {
    let model: PasswordsModel
    /// Ends the sheet.
    let dismiss: () -> Void
    @State private var password = ""
    @State private var again = ""
    @State private var touchID = PasswordsSetupSheet.hasTouchID
    @State private var code: RecoveryCode?
    @State private var problem: String?

    static var hasTouchID: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.m) {
            if let code { shown(code) } else { form }
        }
        .padding(Design.Space.l)
        .frame(width: 420)
    }

    private var form: some View {
        Group {
            Text("Set Up Passwords").font(Design.Text.title)
            if Self.hasTouchID {
                Toggle("Unlock with Touch ID", isOn: $touchID).settingSwitch()
            }
            Text(touchID ? "A master password unlocks it when Touch ID cannot." : "A master password unlocks it.")
                .foregroundStyle(.secondary)
            SecureField("Master Password", text: $password).textFieldStyle(.roundedBorder)
            SecureField("Again", text: $again).textFieldStyle(.roundedBorder)
            if let problem { Text(problem).font(Design.Text.detail).foregroundStyle(.red) }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Set Up") { create() }.keyboardShortcut(.defaultAction).disabled(password.isEmpty)
            }
        }
    }

    private func shown(_ code: RecoveryCode) -> some View {
        UnkeptRecoveryCode(code: code, done: "Done", leading: 0) {
            model.codeKept()
            dismiss()
        }
    }

    private func create() {
        do {
            code = try model.create(
                password: password,
                again: again,
                touchID: touchID ? { vault throws(TouchIDFactor.Refused) in try TouchIDFactor.make(vault: vault) } : nil
            )
            password = ""
            again = ""
        } catch is PasswordsModel.Mismatch {
            problem = "The two passwords are not the same."
        } catch is PasswordsModel.TooShort {
            problem = "Use at least \(PasswordsModel.minimumLength) characters: a few words make a strong password."
        } catch {
            problem = "The vault could not be made."
        }
    }
}
