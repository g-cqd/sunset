import SunsetRuntime

extension TabsModel {
    /// Stores what a view reports of its geometry while it is laid out (`onGeometryChange`): after the layout pass, and only
    /// when it changed. Written during the pass, an observed property re-entered AppKit's observation tracking of the
    /// layout that read it, and the app crashed (the owner, 2026-11-28: widening the sidebar over Settings; the sidebar's
    /// width and frame are written at every step of the drag).
    package func afterLayout(_ write: sending @escaping @MainActor (TabsModel) -> Void) {
        Runtime.live.task { @MainActor [weak self] in
            guard let self else { return }
            write(self)
        }
    }

    /// A frame or size a view reports, stored after the pass when it changed.
    package func laidOut<Value: Equatable & Sendable>(
        _ path: sending ReferenceWritableKeyPath<TabsModel, Value>,
        _ value: Value
    ) {
        afterLayout { if $0[keyPath: path] != value { $0[keyPath: path] = value } }
    }

    /// The sidebar's width and the time its rows take to move, for a slide between Spaces (`SpaceSlide`).
    package func sidebarLaidOut(width: Double, duration: Double?) {
        afterLayout { tabs in
            if tabs.slide.width != width { tabs.slide.width = width }
            if tabs.slide.duration != duration { tabs.slide.duration = duration }
        }
    }
}
