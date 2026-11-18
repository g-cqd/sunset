import Darwin
import SunsetWeb

/// Whether macOS says memory is short: its pressure level (`kern.memorystatus_vm_pressure_level`: 1 normal, 2 warning, 4
/// critical; short at critical, ADR-0076), read when asked; no dispatch source (ADR-0033).
enum MemoryPressure {
    static var isShort: Bool {
        var level: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 else { return false }
        return PageSleep.memoryIsShort(level: level)
    }
}
