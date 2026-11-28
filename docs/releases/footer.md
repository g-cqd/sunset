**Two variants.** Sunset (`Sunset-TAG-…`) shows pages with the system's WebKit. Sunset with its own WebKit
(`Sunset-WebKit-TAG-…`) uses WebKit `BASE` with PATCHES patches of ours. Switch in Settings › General › Updates › Web engine.

**Install.** Unzip, move the app to Applications, open it. Signed with a Developer ID and notarised; macOS 26 or later,
Apple silicon.

**Check the download.** `shasum -a 256 -c NAME.zip.sha256` in the folder holding both files.

Earlier releases' notes: https://github.com/g-cqd/sunset/releases. Report what breaks in the repository's issues.
