// t109 (n58): what other well-known lists give through Sunset's own converter: rules kept, lines left out, WebKit's
// 150,000-rule limit, whether WebKit compiles the result, and the time each step takes (release, one run) (2026-11-19).
import Foundation
import WebKit

let folder = URL(fileURLWithPath: CommandLine.arguments[1])
let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
func ms(_ start: UInt64) -> Int { Int(Double(DispatchTime.now().uptimeNanoseconds - start) / 1e6) }

Task { @MainActor in
    let storeURL = folder.appending(path: "store")
    try? FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: true)
    guard let store = WKContentRuleListStore(url: storeURL) else { exit(1) }
    for file in files.filter({ $0.pathExtension == "txt" }).sorted(by: { $0.path < $1.path }) {
        guard let text = try? String(contentsOf: file, encoding: .utf8) else {
            print(file.lastPathComponent, "not UTF-8")
            continue
        }
        var t = DispatchTime.now().uptimeNanoseconds
        let converted = BlockingRules.convert(text)
        let convert = ms(t)
        let hiding = converted.rules
            .filter { "\($0)".contains("cssDisplayNone") || "\($0)".contains("css-display-none") }.count
        var outcome = ""
        t = DispatchTime.now().uptimeNanoseconds
        do {
            let parts = converted.parts()
            for (index, part) in parts.enumerated() {
                let json = String(decoding: try BlockingRules.json(part), as: UTF8.self)
                _ = try await store.compileContentRuleList(
                    forIdentifier: file.deletingPathExtension().lastPathComponent + "-\(index)",
                    encodedContentRuleList: json
                )
            }
            outcome = "compiled in \(parts.count) part(s), \(ms(t)) ms"
        } catch {
            outcome = "not compiled: \(error.localizedDescription.prefix(90))"
        }
        let name = file.deletingPathExtension().lastPathComponent.padding(toLength: 16, withPad: " ", startingAt: 0)
        print(
            "\(name) kept \(converted.rules.count) (hiding \(hiding)), left out \(converted.skipped), convert \(convert) ms, \(outcome)"
        )
    }
    exit(0)
}
RunLoop.main.run()
