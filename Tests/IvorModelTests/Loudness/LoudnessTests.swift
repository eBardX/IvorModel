@testable import IvorModel
import Testing
import XestiNumbers

struct LoudnessTests {
}

// MARK: -

extension LoudnessTests {
    @Test
    func comparable() {
        #expect(Loudness.pppp < Loudness.ppp)
        #expect(Loudness.ppp < Loudness.pp)
        #expect(Loudness.pp < Loudness.p)
        #expect(Loudness.p < Loudness.mp)
        #expect(Loudness.mp < Loudness.mf)
        #expect(Loudness.mf < Loudness.f)
        #expect(Loudness.f < Loudness.ff)
        #expect(Loudness.ff < Loudness.fff)
        #expect(Loudness.fff < Loudness.ffff)
    }

    @Test
    func init_invalid() {
        #expect(Loudness(numberValue: -1) == nil)
        #expect(Loudness(numberValue: 2) == nil)
    }

    @Test
    func init_valid() {
        #expect(Loudness(numberValue: 0) != nil)
        #expect(Loudness(numberValue: 1) != nil)
    }

    @Test
    func isValid() {
        #expect(Loudness.isValid(0))
        #expect(Loudness.isValid(1))
        #expect(!Loudness.isValid(-1))
        #expect(!Loudness.isValid(2))
    }

    @Test
    func standardLevels() {
        #expect(Loudness.ffff.numberValue == 1)
        #expect(Loudness.pppp.numberValue > 0)
        #expect(Loudness.pppp.numberValue < Loudness.ppp.numberValue)
    }
}
