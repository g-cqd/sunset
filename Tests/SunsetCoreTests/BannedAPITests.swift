import Testing

@Suite("Banned APIs") struct BannedAPITests {
    @Test func `a use of a banned API is reported with its line`() {
        let rule = BannedAPIs.Rule(name: "Thing", needles: ["OldThing"], reason: "use NewThing")
        let found = BannedAPIs.problems(in: [("A.swift", "let a = 1\nlet b = OldThing()\n")], rules: [rule])
        #expect(found == ["A.swift:2: OldThing (Thing: use NewThing)"])
        #expect(BannedAPIs.problems(in: [("B.swift", "let c = NewThing()\n")], rules: [rule]).isEmpty)
    }

    @Test func `no Swift file in Sources, Tests or Benchmarks uses a banned API`() {
        let files = RepositoryFiles.swiftFiles(in: ["Sources", "Tests", "Benchmarks/Benchmarks"])
            .filter { $0.name != "BannedAPIs.swift" && $0.name != "BannedAPITests.swift" }
        #expect(files.count > 50, "the scan must see the repository: \(files.count) files")
        let problems = BannedAPIs.problems(in: files)
        #expect(problems.isEmpty, "\(problems.joined(separator: "\n"))")
    }
}
