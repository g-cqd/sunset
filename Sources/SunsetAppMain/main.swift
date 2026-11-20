import SunsetApp
import SwiftUI

// The app itself is the library target SunsetApp: this starts it, as the `sunset-app` executable of the package (tests, benchmarks,
// axdrive) and as Sunset.app (built by Xcode from project.yml, which compiles this same file).
SunsetApp.pointAtBundledWebKit()
SunsetApp.main()
