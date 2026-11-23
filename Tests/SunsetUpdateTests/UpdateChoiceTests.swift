import Foundation
import SunsetUpdate
import Testing

/// The newest release for this build and channel, and the notes between the two (roadmap 0122 B).
struct UpdateChoiceTests {
    static func releases() throws -> [PublishedRelease] {
        try ReleaseFeed.decode(
            ReleaseFeedTests.feed([
                ReleaseFeedTests.release(12, build: 790, pre: false, webKit: false),
                ReleaseFeedTests.release(11, build: 786),
                ReleaseFeedTests.release(10, build: 781),
                ReleaseFeedTests.release(9, build: 759)
            ])
        )
    }

    @Test func offersTheNewestLaterBuildWithTheNotesBetweenNewestFirst() throws {
        let offer = try #require(
            UpdateChoice.offer(
                in: try Self.releases(),
                flavour: .native,
                architecture: "arm64",
                running: 759,
                prereleases: true
            )
        )
        #expect(offer.release.build == 790)
        #expect(offer.archive.name.hasPrefix("Sunset-v0.1.0-alpha.12-build790"))
        #expect(offer.between.map(\.build) == [790, 786, 781])
    }

    @Test func skipsReleasesWithoutTheFlavourButKeepsTheirNotes() throws {
        let offer = try #require(
            UpdateChoice.offer(
                in: try Self.releases(),
                flavour: .webKit,
                architecture: "arm64",
                running: 759,
                prereleases: true
            )
        )
        #expect(offer.release.build == 786)
        #expect(offer.between.map(\.build) == [786, 781])
    }

    @Test func offersNothingWhenRunningTheNewestOrLater() throws {
        let releases = try Self.releases()
        #expect(
            UpdateChoice.offer(in: releases, flavour: .native, architecture: "arm64", running: 790, prereleases: true)
                == nil
        )
        #expect(
            UpdateChoice.offer(in: releases, flavour: .native, architecture: "arm64", running: 800, prereleases: true)
                == nil
        )
    }

    @Test func leavesOutPrereleasesWhenAskedTo() throws {
        let releases = try Self.releases()
        let offer = UpdateChoice.offer(
            in: releases,
            flavour: .native,
            architecture: "arm64",
            running: 759,
            prereleases: false
        )
        #expect(offer?.release.build == 790)
        #expect(offer?.between.map(\.build) == [790])
        #expect(
            UpdateChoice.offer(in: releases, flavour: .webKit, architecture: "arm64", running: 759, prereleases: false)
                == nil
        )
    }
}
