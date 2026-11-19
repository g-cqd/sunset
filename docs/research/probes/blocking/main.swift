// t109 (n58): what Sunset's blocking costs, release, five runs: converting each kept list (Sunset's own `BlockingRules`),
// encoding its JSON, compiling it with WebKit, and looking a compiled list up again (what a cache would cost instead) (2026-11-19).
// Build: Scripts in docs/research/probes/blocking/run.sh.
import CryptoKit
import Foundation
import WebKit

func ms(_ start: UInt64) -> Double { Double(DispatchTime.now().uptimeNanoseconds - start) / 1e6 }
func p50(_ xs: [Double]) -> String {
    let s = xs.sorted()
    return String(format: "p50 %.0f ms (min %.0f, max %.0f)", s[s.count / 2], s.first ?? 0, s.last ?? 0)
}

let folder = URL(fileURLWithPath: CommandLine.arguments[1])
let lists = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension == "txt" }.sorted { $0.path < $1.path }
let storeURL = folder.appending(path: "store")
try? FileManager.default.removeItem(at: storeURL)
try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: true)

Task { @MainActor in
    guard let store = WKContentRuleListStore(url: storeURL) else { exit(1) }
    for list in lists {
        let text = try String(contentsOf: list, encoding: .utf8)
        var convert: [Double] = []
        var encode: [Double] = []
        var compile: [Double] = []
        var lookUp: [Double] = []
        var cached: [Double] = []
        for _ in 0 ..< 5 {
            // What a launch does on the main actor once the list is compiled: read the file, digest it (the key).
            let t = DispatchTime.now().uptimeNanoseconds
            let read = try String(contentsOf: list, encoding: .utf8)
            _ = SHA256.hash(data: Data(("2\n" + read).utf8))
            cached.append(ms(t))
        }
        var rules = 0
        var hiding = 0
        var jsonBytes = 0
        for run in 0 ..< 5 {
            var t = DispatchTime.now().uptimeNanoseconds
            let converted = BlockingRules.convert(text)
            convert.append(ms(t))
            t = DispatchTime.now().uptimeNanoseconds
            let json = String(decoding: try BlockingRules.json(converted.rules), as: UTF8.self)
            encode.append(ms(t))
            rules = converted.rules.count
            jsonBytes = json.utf8.count
            hiding = json.components(separatedBy: "css-display-none").count - 1
            t = DispatchTime.now().uptimeNanoseconds
            _ = try await store.compileContentRuleList(forIdentifier: "probe-\(run)", encodedContentRuleList: json)
            compile.append(ms(t))
            t = DispatchTime.now().uptimeNanoseconds
            _ = try await store.contentRuleList(forIdentifier: "probe-\(run)")
            lookUp.append(ms(t))
        }
        print(list.lastPathComponent, "| rules", rules, "| hiding rules", hiding, "| JSON", jsonBytes / 1024, "KiB")
        print("  convert (main actor today):", p50(convert))
        print("  JSON encode (main actor today):", p50(encode))
        print("  WebKit compile:", p50(compile))
        print("  look up an already compiled list:", p50(lookUp))
        print("  read and digest (a launch's main-actor work once compiled):", p50(cached))
    }
    exit(0)
}
RunLoop.main.run()
