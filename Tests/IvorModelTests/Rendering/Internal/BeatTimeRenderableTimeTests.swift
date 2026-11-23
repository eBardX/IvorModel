// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct BeatTimeRenderableTimeTests {
}

// MARK: -

extension BeatTimeRenderableTimeTests {
    @Test
    func durationFromNumber() {
        #expect(BeatTime.duration(fromNumber: frac(3, 4)) == BeatDuration(numberValue: frac(3, 4)))
    }

    @Test
    func durationFromNumber_negativeIsNil() {
        #expect(BeatTime.duration(fromNumber: -1) == nil)
    }

    @Test
    func initNumber() {
        #expect(BeatTime(number: frac(5, 2)) == BeatTime(numberValue: frac(5, 2)))
    }

    @Test
    func initNumber_negativeIsNil() {
        #expect(BeatTime(number: -1) == nil)
    }

    @Test
    func number() throws {
        #expect(try #require(BeatTime(numberValue: frac(7, 4))).number == frac(7, 4))
    }

    @Test
    func numberOf() throws {
        #expect(try BeatTime.number(of: #require(BeatDuration(numberValue: frac(1, 8)))) == frac(1, 8))
    }
}
