import Foundation

@testable import SunsetWeb

/// How the bench opens and fills the store: the one part that differs before and after ST-3.
@MainActor
enum HistoryBench {
    static func open(_ path: String) -> HistoryStore? {
        (try? TestState.table("history", at: path + "-state.sqlite")).map { HistoryStore(table: $0) }
    }

    static func fill(_ store: HistoryStore, count: Int) {
        for index in 0 ..< count {
            store.visit(
                HistoryBenchTests.address(index),
                title: HistoryBenchTests.title(index),
                at: Date(timeIntervalSince1970: 1_790_000_000 + Double(index))
            )
        }
    }

    static func bytes(_ path: String) -> Int {
        let folder = (path as NSString).deletingLastPathComponent
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []
        return names.reduce(0) { total, name in
            total + ((try? FileManager.default.attributesOfItem(atPath: folder + "/" + name)[.size] as? Int) ?? 0)
        }
    }

    /// The process's memory footprint, as Activity Monitor counts it.
    static func footprint() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            unsafe pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                unsafe task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), rebound, &count)
            }
        }
        return result == KERN_SUCCESS ? Int(info.phys_footprint) : 0
    }
}
