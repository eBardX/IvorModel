// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct WallTimeRenderableTimeTests {
}

// MARK: -

extension WallTimeRenderableTimeTests {
    @Test
    func durationFromNumber() {
        #expect(WallTime.duration(fromNumber: frac(3, 4)) == WallDuration(numberValue: frac(3, 4)))
    }

    @Test
    func durationFromNumber_negativeIsNil() {
        #expect(WallTime.duration(fromNumber: -1) == nil)
    }

    @Test
    func initNumber() {
        #expect(WallTime(number: frac(5, 2)) == WallTime(numberValue: frac(5, 2)))
    }

    @Test
    func initNumber_negativeIsNil() {
        #expect(WallTime(number: -1) == nil)
    }

    @Test
    func number() throws {
        #expect(try #require(WallTime(numberValue: frac(7, 4))).number == frac(7, 4))
    }

    @Test
    func numberOf() throws {
        #expect(try WallTime.number(of: #require(WallDuration(numberValue: frac(1, 8)))) == frac(1, 8))
    }
}
