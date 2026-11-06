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

    @Test func `while blinking the next look is one interval away, when solid it is a slow look`() {
        let schedule = BlinkSchedule(interval: .milliseconds(500), stopAfter: .seconds(10))
        #expect(schedule.wait(afterIdle: .seconds(1)) == .milliseconds(500))
        #expect(schedule.wait(afterIdle: .seconds(11)) == .seconds(2))
    }
}
