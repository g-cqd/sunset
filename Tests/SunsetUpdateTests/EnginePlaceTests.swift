import Foundation
import SunsetUpdate
import Testing

/// The engine's folder beside the app, changed as Sunset quits (roadmap 0113 D, the owner: switch between the system's and
/// the component, delete it, update it): what each change leaves, and what goes to the Trash.
struct EnginePlaceTests {
    static func place(_ folder: URL) -> EnginePlace {
        EnginePlace(beside: folder.appending(path: "Sunset.app"))
    }

    @Test func `installed in place of none, or of the one before, which is returned to be trashed`() throws {
        try UpdatePackageTests.inFolder { folder in
            let place = Self.place(folder)
            try EngineInstallTests.engine(at: place.staging, build: 810, base: "a", code: "a")
            #expect(try place.apply(.install) == nil)
            #expect(EngineManifest.read(from: place.engine)?.build == 810 && place.state == .on)
            try EngineInstallTests.engine(at: place.staging, build: 820, base: "b", code: "b")
            let former = try #require(try place.apply(.install))
            #expect(EngineManifest.read(from: place.engine)?.build == 820)
            #expect(EngineManifest.read(from: former)?.build == 810)
        }
    }

    @Test func `switched off and on by its name, deleted on or off`() throws {
        try UpdatePackageTests.inFolder { folder in
            let place = Self.place(folder)
            #expect(place.state == .none)
            try EngineInstallTests.engine(at: place.engine, build: 810, base: "a", code: "a")
            _ = try place.apply(.off)
            #expect(place.state == .off && EngineManifest.read(from: place.offFolder)?.build == 810)
            _ = try place.apply(.on)
            #expect(place.state == .on)
            _ = try place.apply(.off)
            let removed = try #require(try place.apply(.remove))
            #expect(place.state == .none && EngineManifest.read(from: removed)?.build == 810)
        }
    }

    @Test func `an update staged while it is off is put in place off`() throws {
        try UpdatePackageTests.inFolder { folder in
            let place = Self.place(folder)
            try EngineInstallTests.engine(at: place.offFolder, build: 810, base: "a", code: "a")
            try EngineInstallTests.engine(at: place.staging, build: 820, base: "b", code: "b")
            _ = try place.apply(.install)
            #expect(place.state == .off && EngineManifest.read(from: place.offFolder)?.build == 820)
        }
    }
}
