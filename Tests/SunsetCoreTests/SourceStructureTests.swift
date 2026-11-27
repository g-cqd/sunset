import Foundation
import SunsetTestSupport
import Testing

/// The structure rules, broken on purpose below, and then applied to this repository.
@Suite("Source structure") struct SourceStructureTests {
    private func file(_ name: String, _ text: String) -> [(name: String, text: String)] {
        [(name, text)]
    }

    @Test func `a file with one type, named for it, is sound`() {
        #expect(SourceStructure.problems(in: file("Box.swift", "struct Box {\n    struct Inner {}\n}\n")).isEmpty)
        #expect(SourceStructure.problems(in: file("Box+Sendable.swift", "extension Box: Sendable {}\n")).isEmpty)
        #expect(
            SourceStructure.problems(in: file("Box+More.swift", "extension Box {}\nextension Box: Equatable {}\n"))
                .isEmpty
        )
        #expect(SourceStructure.problems(in: file("Fixture.swift", "public final class Fixture {}\n")).isEmpty)
        #expect(SourceStructure.problems(in: file("Outer+Inner.swift", "extension Outer.Inner {}\n")).isEmpty)
        #expect(
            SourceStructure.problems(in: file("Checks.swift", "@Suite(\"Checks (all of them)\") struct Checks {}\n"))
                .isEmpty
        )
    }

    @Test func `two top-level types in one file are reported, attributes and suites included`() {
        let pair = SourceStructure.problems(in: file("Pair.swift", "struct Pair {}\nenum Mode {}\n"))
        #expect(pair.count == 1 && pair.first?.contains("2 top-level types") == true)
        let suites = "@Suite(\"One\") struct OneTests {}\n@Suite(\"Two\") struct TwoTests {}\n"
        #expect(SourceStructure.problems(in: file("Tests.swift", suites)).count == 1)
    }

    @Test func `a file named for another type is reported`() {
        #expect(SourceStructure.problems(in: file("Wrong.swift", "struct Right {}\n")).count == 1)
        #expect(SourceStructure.problems(in: file("Wrong+More.swift", "extension Right {}\n")).count == 1)
        #expect(SourceStructure.problems(in: file("Mixed+More.swift", "extension A {}\nextension B {}\n")).count == 1)
    }

    @Test
    func
        `a file over the line cap is reported unless exempted with a justified directive; unjustified directives fail`()
    {
        let at = "struct Long {}\n" + String(repeating: "// x\n", count: SourceStructure.maximumLines - 1)
        #expect(SourceStructure.problems(in: file("Long.swift", at)).isEmpty)
        #expect(SourceStructure.problems(in: file("Long.swift", at + "// x\n")).count == 1)

        // Justified file_length exemption passes, while an unjustified one fails both directive & length checks.
        let disable = "swiftlint:" + "disable"
        let justified = "// \(disable) file_length - cohesive state machine\n" + at + "// x\n"
        #expect(SourceStructure.problems(in: file("Long.swift", justified)).isEmpty)
        let unjustified = "// \(disable) file_length\n" + at
        #expect(SourceStructure.problems(in: file("Long.swift", unjustified)).count == 2)
        let bareDisable = "struct Quiet {\n    // \(disable):next force_cast\n}\n"
        #expect(SourceStructure.problems(in: file("Quiet.swift", bareDisable)).count == 1)
        let justifiedDisable = "struct Quiet {\n    // \(disable):next force_cast - bridged ObjC type\n}\n"
        #expect(SourceStructure.problems(in: file("Quiet.swift", justifiedDisable)).isEmpty)
    }

    @Test func `a generated file is exempt, and a type named in a comment is not a declaration`() {
        let big = "enum GeneratedTables {}\n" + String(repeating: "// x\n", count: 400)
        #expect(SourceStructure.problems(in: file("GeneratedTables.swift", big)).isEmpty)
        #expect(SourceStructure.problems(in: file("Quiet.swift", "struct Quiet {}\n// struct Another {}\n")).isEmpty)
    }

    @Test func `every Swift file in Sources and Tests is within the structure rules`() {
        let files = RepositoryFiles.swiftFiles(in: ["Sources", "Tests"])
        #expect(files.count > 50, "the scan must see the repository: \(files.count) files")
        let problems = SourceStructure.problems(in: files.sorted { $0.name < $1.name })
        #expect(problems.isEmpty, "\(problems.joined(separator: "\n"))")
    }
}
