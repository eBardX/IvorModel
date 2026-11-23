// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
import Testing

struct RenderablePitchTests {
}

// MARK: -

extension RenderablePitchTests {
    @Test
    func partner_everyConformerFindsAPartnerOnEachSideByEachRule() throws {
        let pitches: [any RenderablePitch] = try [Pitch.e4, #require(NoteNumber(uintValue: 64)), Frequency(330)]

        for pitch in pitches {
            for side in [PartnerSide.above, .below] {
                for rule in [PartnerRule.diatonic, .halfStep, .wholeStep] {
                    #expect(pitch.partner(on: side, rule: rule, key: key(0)) != nil)
                }
            }
        }
    }
}
