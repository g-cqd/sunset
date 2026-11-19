import Testing

/// ADR-0087 (the owner's note n55): "i'd prefer that we span multiple lines so that we have a better readability".
@Suite("Source shape: bodies on lines of their own")
struct SourceShapeTests {
    @Test
    func `a body on its declaration's line is found; a requirement, a stored property and a call's label are not`() {
        #expect(SourceShape.isOneLineBody("    var isEmpty: Bool { items.isEmpty }"))
        #expect(SourceShape.isOneLineBody("    package func stop() { listener.cancel() }  // done"))
        #expect(SourceShape.isOneLineBody("    @MainActor init(x: Int = 0) { self.x = x }"))
        #expect(SourceShape.isOneLineBody("        get { value }"))
        #expect(!SourceShape.isOneLineBody("    var isEmpty: Bool { get }"))
        #expect(!SourceShape.isOneLineBody("    var make: () -> Int = { 0 }"))
        #expect(SourceShape.isOneLineBody("    var scopes = Scopes() { didSet { changed() } }"))
        #expect(!SourceShape.isOneLineBody("            set: { value in config.update { $0.x = value } }"))
        #expect(!SourceShape.isOneLineBody("    var isEmpty: Bool {"))
        #expect(!SourceShape.isOneLineBody("    func a() { b() }; func c() {"))
    }

    @Test func `no Swift file in Sources or Tests has a body on its declaration's line`() {
        let files = RepositoryFiles.swiftFiles(in: ["Sources", "Tests"])
        #expect(files.count > 50, "the scan must see the repository: \(files.count) files")
        let found = SourceShape.oneLineBodies(in: files.sorted { $0.name < $1.name })
        #expect(found.isEmpty, "\(found.count) one-line bodies, the first: \(found.prefix(5).joined(separator: "\n"))")
    }
}
