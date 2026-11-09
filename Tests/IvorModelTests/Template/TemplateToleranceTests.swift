// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TemplateToleranceTests {
}

// MARK: -

extension TemplateToleranceTests {
    @Test
    func beatGrouping_nil_groupsNothing() throws {
        let grouping = try Template.beatGrouping(nil)

        #expect(grouping([beats(1), beats(2)]).isEmpty)
    }

    @Test
    func beatGrouping_proportional_mapsToMostCommon() throws {
        let nearlyOne = beats(Number(numerator: 21, denominator: 20))
        let grouping = try Template.beatGrouping(.proportional(0.1))

        let result = grouping([beats(1), beats(1), nearlyOne, beats(2)])

        #expect(result == [beats(1): beats(1), nearlyOne: beats(1), beats(2): beats(2)])
    }

    @Test
    func beatGrouping_proportional_tie_mapsToShortest() throws {
        let nearlyOne = beats(Number(numerator: 21, denominator: 20))
        let grouping = try Template.beatGrouping(.proportional(0.1))

        #expect(grouping([nearlyOne, beats(1)]) == [beats(1): beats(1), nearlyOne: beats(1)])
    }

    @Test
    func beatGrouping_step_throws() {
        #expect(throws: Template.Error.incompatibleOptions) {
            try Template.beatGrouping(.step(wallDuration(10)))
        }
    }

    @Test
    func exactRounding_cents_throws() {
        #expect(throws: Template.Error.incompatibleOptions) {
            let _: (Pitch) -> Pitch = try Template.exactRounding(.cents(10))
        }
    }

    @Test
    func exactRounding_nil_isIdentity() throws {
        let rounding: (Pitch) -> Pitch = try Template.exactRounding(nil)

        #expect(rounding(.c4) == .c4)
    }

    @Test
    func frequencyRounding_cents_roundsToNearestStepFromA4() {
        let rounding = Template.frequencyRounding(.cents(100))

        #expect(rounding(Frequency(450)) == Frequency(440))
        #expect(rounding(Frequency(870)) == Frequency(880))
    }

    @Test
    func frequencyRounding_nil_isIdentity() {
        #expect(Template.frequencyRounding(nil)(Frequency(450)) == Frequency(450))
    }

    @Test
    func roundedPitches_collapsesSameRoundedPitch_firstKeepsTies() {
        let tiedPitches: [NoteEvent<BeatTime, Frequency>.TiedPitch] = [.init(pitch: Frequency(450), startsTie: true),
                                                                       .init(pitch: Frequency(445), endsTie: true),
                                                                       .init(pitch: Frequency(880))]

        let result = Template.roundedPitches(tiedPitches,
                                             with: Template.frequencyRounding(.cents(100)))

        #expect(result == [.init(pitch: Frequency(440), startsTie: true),
                           .init(pitch: Frequency(880))])
    }

    @Test
    func roundedPitches_identity_keepsDistinctPitches() {
        let tiedPitches: [NoteEvent<BeatTime, Pitch>.TiedPitch] = [.init(pitch: .c4), .init(pitch: .e4, endsTie: true)]

        #expect(Template.roundedPitches(tiedPitches) { $0 } == tiedPitches)
    }

    @Test
    func wallGrouping_nil_groupsNothing() {
        #expect(Template.wallGrouping(nil)([wallDuration(100)]).isEmpty)
    }

    @Test
    func wallGrouping_proportional_mapsToMostCommon() {
        let grouping = Template.wallGrouping(.proportional(0.1))

        let result = grouping([wallDuration(100), wallDuration(100), wallDuration(105), wallDuration(300)])

        #expect(result == [wallDuration(100): wallDuration(100),
                           wallDuration(105): wallDuration(100),
                           wallDuration(300): wallDuration(300)])
    }

    @Test
    func wallGrouping_step_roundsToNearestStepAtLeastOne() {
        let grouping = Template.wallGrouping(.step(wallDuration(100)))

        let result = grouping([wallDuration(20), wallDuration(140), wallDuration(160)])

        #expect(result == [wallDuration(20): wallDuration(100),
                           wallDuration(140): wallDuration(100),
                           wallDuration(160): wallDuration(200)])
    }
}
