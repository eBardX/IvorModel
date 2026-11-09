// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct BeatDurationTemplateDurationTests {
}

// MARK: -

extension BeatDurationTemplateDurationTests {
    @Test
    func templateRatio_dividesDurations() {
        #expect(beats(3).templateRatio(to: beats(2)) == Number(numerator: 3, denominator: 2))
    }

    @Test
    func templateRatio_equalDurations_isOne() {
        #expect(beats(2).templateRatio(to: beats(2)) == 1)
    }

    @Test
    func templateRatio_zeroOther_isNil() {
        #expect(beats(2).templateRatio(to: .zero) == nil)
    }

    @Test
    func templateRatio_zeroSelf_isZero() {
        #expect(BeatDuration.zero.templateRatio(to: beats(2)) == 0)
    }
}
