// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct TemplateDurationTests {
}

// MARK: -

extension TemplateDurationTests {
    @Test
    func templateRatio_beatDuration_isExactRatio() {
        #expect(beats(1).templateRatio(to: beats(4)) == Number(numerator: 1, denominator: 4))
    }

    @Test
    func templateRatio_equalDurations_isOneForEveryConformer() {
        #expect(beats(3).templateRatio(to: beats(3)) == 1)
        #expect(wallDuration(250).templateRatio(to: wallDuration(250)) == 1)
    }

    @Test
    func templateRatio_inverseRatiosDiffer() {
        #expect(beats(2).templateRatio(to: beats(1)) != beats(1).templateRatio(to: beats(2)))
        #expect(wallDuration(1_000).templateRatio(to: wallDuration(500)) != wallDuration(500).templateRatio(to: wallDuration(1_000)))
    }

    @Test
    func templateRatio_zeroOther_isNilForEveryConformer() {
        #expect(beats(1).templateRatio(to: .zero) == nil)
        #expect(wallDuration(250).templateRatio(to: .zero) == nil)
    }
}
