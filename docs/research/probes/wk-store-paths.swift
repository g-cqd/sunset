// Lists the store paths _WKWebsiteDataStoreConfiguration lets an app set (t51, 2026-11-19).
import WebKit

MainActor.assumeIsolated {
    guard let cls = NSClassFromString("_WKWebsiteDataStoreConfiguration") as? NSObject.Type else {
        print("no class")
        exit(0)
    }
    var count: UInt32 = 0
    let props = class_copyPropertyList(cls, &count)
    var names: [String] = []
    for i in 0 ..< Int(count) { if let p = props?[i] { names.append(String(cString: property_getName(p))) } }
    print(
        names.filter { $0.range(of: "Directory|Path|File|URL|Storage", options: .regularExpression) != nil }.sorted()
            .joined(separator: " ")
    )
    let custom = NSSelectorFromString("initWithIdentifier:")
    print(
        "initWithIdentifier:",
        cls.instancesRespond(to: custom),
        "| WKWebsiteDataStore _initWithConfiguration:",
        WKWebsiteDataStore.instancesRespond(to: NSSelectorFromString("_initWithConfiguration:"))
    )
}
