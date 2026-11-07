import Testing

@testable import SunsetRender

@Suite("Blink schedule") struct BlinkScheduleTests {
    @Test func `the cursor blinks while there is input or output, and is solid after the timeout`() {
        let schedule = BlinkSchedule()
        #expect(schedule.blinks(afterIdle: .zero))
        #expect(schedule.blinks(afterIdle: .seconds(14)))
        #expect(!schedule.blinks(afterIdle: .seconds(15)))
        #expect(!schedule.blinks(afterIdle: .seconds(3600)))
    }

    @Test func `no timeout means it always blinks`() {
        let schedule = BlinkSchedule(stopAfter: nil)
        #expect(schedule.blinks(afterIdle: .seconds(100_000)))
    }

    @Test func `while blinking the next look is one interval away, when solid there is nothing to wait for`() {
        let schedule = BlinkSchedule(interval: .milliseconds(500), stopAfter: .seconds(10))
        #expect(schedule.wait(afterIdle: .seconds(1)) == .milliseconds(500))
        #expect(schedule.wait(afterIdle: .seconds(11)) == nil, "no timer: activity or focus wakes it")
    }

    @Test func `a terminal that does not have the focus does not blink, however recent its activity`() {
        let schedule = BlinkSchedule()
        #expect(schedule.blinks(afterIdle: .zero, focused: true))
        #expect(!schedule.blinks(afterIdle: .zero, focused: false))
        #expect(schedule.wait(afterIdle: .zero, focused: false) == nil)
        #expect(schedule.wait(afterIdle: .zero, focused: true) == schedule.interval)
    }

    @Test func `with no timeout it still stops when unfocused`() {
        let schedule = BlinkSchedule(stopAfter: nil)
        #expect(schedule.blinks(afterIdle: .seconds(100_000), focused: true))
        #expect(!schedule.blinks(afterIdle: .seconds(100_000), focused: false))
    }
}
