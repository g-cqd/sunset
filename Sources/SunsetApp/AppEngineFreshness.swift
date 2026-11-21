import AppKit
import SunsetAppCore
import SunsetRuntime
import SunsetShellModel

/// Sunset WebKit says when its engine is likely behind WebKit's security fixes (threat model D10): once for each engine,
/// at launch, with the way to the newer release; and in About. The native build has nothing to say: macOS updates its
/// WebKit.
@MainActor
enum AppEngineFreshness {
    private static let toldKey = "engineToldFor"
    static let releases = URL(string: "https://github.com/g-cqd/sunset/releases")

    /// The engine's base and its age in weeks; nil for the native build.
    static var engine: (base: String, weeks: Int?, date: Date?)? {
        let info = Bundle.main.infoDictionary ?? [:]
        guard let base = info[BundledWebKit.marker] as? String else { return nil }
        let date = (info[EngineFreshness.dateKey] as? String).flatMap { try? Date($0, strategy: .iso8601) }
        return (base, EngineFreshness.weeks(base: date, now: Runtime.live.now()), date)
    }

    /// At launch: tells once for this engine when it is behind.
    static func tellIfBehind() {
        guard let engine,
            EngineFreshness.tells(
                weeks: engine.weeks,
                base: engine.base,
                toldFor: UserDefaults.standard.string(forKey: toldKey)
            )
        else { return }
        UserDefaults.standard.set(engine.base, forKey: toldKey)
        let alert = SunsetAlert(
            title: "Sunset WebKit\u{2019}s engine is \(engine.weeks ?? 0) weeks old",
            message: "WebKit fixes security problems every few weeks, and macOS updates do not reach the WebKit inside "
                + "Sunset WebKit. A newer release likely has fixes this one lacks.",
            buttons: [.cancel("Later"), .plain("Open Releases")],
            defaultButton: 1
        )
        SunsetAlerts.show(alert) { answer in
            if answer == 1, let releases { NSWorkspace.shared.open(releases) }
        }
    }

    /// What About says of the engine: its base and date (nil for the native build).
    static var aboutLine: String? {
        guard let engine else { return nil }
        let date = engine.date.map { $0.formatted(date: .long, time: .omitted) } ?? "an unknown date"
        return "WebKit \(engine.base.prefix(10)) of \(date), with Sunset\u{2019}s patches."
    }
}
