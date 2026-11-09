// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct WallDurationTemplateDurationTests {
}

// MARK: -

extension WallDurationTemplateDurationTests {
    @Test
    func templateRatio_equalDurations_isOne() {
        #expect(wallDuration(500).templateRatio(to: wallDuration(500)) == 1)
    }

    @Test
    func templateRatio_groupsNearbyRatios() {
        let ratio1 = wallDuration(1_000).templateRatio(to: wallDuration(500))
        let ratio2 = wallDuration(1_004).templateRatio(to: wallDuration(500))

        #expect(ratio1 != nil)
        #expect(ratio1 == ratio2)
    }

    @Test
    func templateRatio_isWholeStepOfOnePercent() throws {
        let ratio = try #require(wallDuration(1_000).templateRatio(to: wallDuration(500)))
        let steps = log(ratio.doubleValue) / log(1.01)

        #expect(abs(steps - 70) < 1e-6)
        #expect(abs(ratio.doubleValue - 2) < 0.01)
    }

    @Test
    func templateRatio_shorterThanOther_isBelowOne() throws {
        let ratio = try #require(wallDuration(500).templateRatio(to: wallDuration(1_000)))

        #expect(ratio < 1)
    }

    @Test
    func templateRatio_zeroOther_isNil() {
        #expect(wallDuration(500).templateRatio(to: .zero) == nil)
    }

    @Test
    func templateRatio_zeroSelf_isNil() {
        #expect(WallDuration.zero.templateRatio(to: wallDuration(500)) == nil)
    }
}
