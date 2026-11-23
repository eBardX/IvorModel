// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct WorkTimeTests {
}

// MARK: -

extension WorkTimeTests {
    @Test
    func equality() {
        #expect(WorkTime.beat(beatTime(1)) == WorkTime.beat(beatTime(1))) // swiftlint:disable:this identical_operands
        #expect(WorkTime.wall(wallTime(500)) == WorkTime.wall(wallTime(500))) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let times: Set = [WorkTime.beat(beatTime(1)),
                          WorkTime.beat(beatTime(1)),
                          WorkTime.wall(wallTime(1_000))]

        #expect(times.count == 2)
    }

    @Test
    func inequality_differentKindsWithTheSameNumber() {
        #expect(WorkTime.beat(beatTime(1)) != WorkTime.wall(wallTime(1_000)))
    }

    @Test
    func inequality_differentTimes() {
        #expect(WorkTime.beat(beatTime(1)) != WorkTime.beat(beatTime(2)))
    }
}
