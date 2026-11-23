// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTuning
import Testing

struct FrequencyRenderablePitchTests {
}

// MARK: -

extension FrequencyRenderablePitchTests {
    @Test
    func partner_diatonicIsAWholeToneEvenInAKey() throws {
        let above = try #require(Frequency(440).partner(on: .above, rule: .diatonic, key: key(2)))

        #expect(abs(above.doubleValue - 440 * pow(2, 2.0 / 12)) < 0.01)
    }

    @Test
    func partner_halfStepIsAHundredCents() throws {
        let above = try #require(Frequency(440).partner(on: .above, rule: .halfStep, key: nil))
        let below = try #require(Frequency(440).partner(on: .below, rule: .halfStep, key: nil))

        #expect(abs(above.doubleValue - 440 * pow(2, 1.0 / 12)) < 0.01)
        #expect(abs(below.doubleValue - 440 / pow(2, 1.0 / 12)) < 0.01)
    }

    @Test
    func partner_wholeStepIsTwoHundredCents() throws {
        let above = try #require(Frequency(440).partner(on: .above, rule: .wholeStep, key: nil))
        let below = try #require(Frequency(440).partner(on: .below, rule: .wholeStep, key: nil))

        #expect(abs(above.doubleValue - 440 * pow(2, 2.0 / 12)) < 0.01)
        #expect(abs(below.doubleValue - 440 / pow(2, 2.0 / 12)) < 0.01)
    }
}
