import Foundation
import SunsetUpdate
import Testing

/// What may replace the running app (ADR-0122): the requirement, checked on a system app and on an ad hoc one.
struct SignatureCheckTests {
    static let calculator = URL(filePath: "/System/Applications/Calculator.app")

    @Test func acceptsWhatMeetsTheRequirement() throws {
        try SignatureCheck.check(
            bundle: Self.calculator,
            requirement: "anchor apple and identifier \"com.apple.calculator\""
        )
    }

    @Test func refusesAnotherIdentifierOrTeam() {
        #expect(throws: SignatureCheck.Failure.self) {
            try SignatureCheck.check(
                bundle: Self.calculator,
                requirement: "anchor apple and identifier \"studio.aemi.sunset\""
            )
        }
        #expect(throws: SignatureCheck.Failure.self) {
            try SignatureCheck.check(
                bundle: Self.calculator,
                requirement: SignatureCheck.requirement(team: "ABCDE12345", identifier: "com.apple.calculator")
            )
        }
    }

    @Test func refusesAnUnsignedBundle() throws {
        try UpdatePackageTests.inFolder { folder in
            let app = folder.appending(path: "Plain.app")
            try UpdatePackageTests.bundle(at: app, executable: [1, 2, 3], resource: "x", extra: false)
            #expect(throws: SignatureCheck.Failure.self) {
                try SignatureCheck.check(bundle: app, requirement: "anchor apple generic")
            }
        }
    }

    @Test func requiresTheTeamTheIdentifierAndNotarization() {
        let requirement = SignatureCheck.requirement(team: "ABCDE12345", identifier: "studio.aemi.sunset")
        #expect(requirement.contains("certificate leaf[subject.OU] = \"ABCDE12345\""))
        #expect(requirement.contains("identifier \"studio.aemi.sunset\""))
        #expect(requirement.hasSuffix("and notarized"))
    }

    @Test func requiresALaterBuild() throws {
        try UpdatePackageTests.inFolder { folder in
            let app = folder.appending(path: "Later.app")
            try FileManager.default.createDirectory(
                at: app.appending(path: "Contents"),
                withIntermediateDirectories: true
            )
            let info = ["CFBundleVersion": "786"] as NSDictionary
            try info.write(to: app.appending(path: "Contents/Info.plist"))
            try SignatureCheck.checkLater(bundle: app, than: 781)
            #expect(throws: SignatureCheck.Failure.notLater(running: 786, staged: 786)) {
                try SignatureCheck.checkLater(bundle: app, than: 786)
            }
        }
    }
}
