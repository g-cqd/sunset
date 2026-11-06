import SwiftUI

/// The Settings window: the font, its size, ligatures and OpenType features, and what Option does.
struct SettingsView: View {
    @AppStorage(SettingsKeys.fontName) private var fontName = "Menlo"
    @AppStorage(SettingsKeys.fontSize) private var fontSize = 14.0
    @AppStorage(SettingsKeys.ligatures) private var ligatures = false
    @AppStorage(SettingsKeys.features) private var features = ""
    @AppStorage(SettingsKeys.optionAsMeta) private var optionAsMeta = false

    var body: some View {
        Form {
            Section("Font") {
                TextField("Font", text: $fontName, prompt: Text("Menlo, SF Mono, Maple Mono…"))
                Stepper(value: $fontSize, in: 8 ... 48, step: 1) { Text("Size: \(Int(fontSize)) pt") }
                Toggle("Ligatures", isOn: $ligatures)
                TextField("Features", text: $features, prompt: Text("zero, ss01, cv02=3"))
            }
            Section("Keyboard") {
                Toggle("Option sends Escape (Meta)", isOn: $optionAsMeta)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .padding()
    }
}
