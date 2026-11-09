// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateGenerationOptionsConstraintsTests {
}

// MARK: -

extension TemplateGenerationOptionsConstraintsTests {
    @Test
    func allows_allowedPitches() {
        let constraints = StandardBeatOptions.Constraints(allowedPitches: [.c4, .e4])

        #expect(constraints.allows(NoteEvent(pitches: [.c4, .e4], duration: beats(1))))
        #expect(!constraints.allows(NoteEvent(pitches: [.c4, .d4], duration: beats(1))))
    }

    @Test
    func allows_emptyConstraints_allowsEverything() {
        let constraints = StandardBeatOptions.Constraints()

        #expect(constraints.allows(NoteEvent(pitches: [.c0], duration: beats(100))))
        #expect(constraints.allows(NoteEvent(tiedPitches: [], duration: beats(100))))
    }

    @Test
    func allows_maximumDuration_appliesToNotesAndRests() {
        let constraints = StandardBeatOptions.Constraints(maximumDuration: beats(2))

        #expect(constraints.allows(NoteEvent(pitches: [.c4], duration: beats(2))))
        #expect(!constraints.allows(NoteEvent(pitches: [.c4], duration: beats(3))))
        #expect(!constraints.allows(NoteEvent(tiedPitches: [], duration: beats(3))))
    }

    @Test
    func allows_pitchRange() {
        let constraints = StandardBeatOptions.Constraints(pitchRange: Pitch.c4...Pitch.g4)

        #expect(constraints.allows(NoteEvent(pitches: [.c4, .g4], duration: beats(1))))
        #expect(!constraints.allows(NoteEvent(pitches: [.c4, .a4], duration: beats(1))))
    }

    @Test
    func allows_restsDisallowed() {
        let constraints = StandardBeatOptions.Constraints(allowsRests: false)

        #expect(!constraints.allows(NoteEvent(tiedPitches: [], duration: beats(1))))
        #expect(constraints.allows(NoteEvent(pitches: [.c4], duration: beats(1))))
    }

    @Test
    func allowsDuration_maximumRestDuration_onlyAppliesToRests() {
        let constraints = StandardBeatOptions.Constraints(maximumRestDuration: beats(1))

        #expect(constraints.allowsDuration(beats(1), isRest: true))
        #expect(!constraints.allowsDuration(beats(2), isRest: true))
        #expect(constraints.allowsDuration(beats(2), isRest: false))
    }

    @Test
    func allowsPitches_emptyPitches_isAllowed() {
        let constraints = StandardBeatOptions.Constraints(pitchRange: Pitch.c4...Pitch.g4,
                                                          allowedPitches: [.c4])

        #expect(constraints.allowsPitches([]))
    }

    @Test
    func codable() throws {
        let original = StandardBeatOptions.Constraints(pitchRange: Pitch.c4...Pitch.c5,
                                                       allowedPitches: [.c4, .g4],
                                                       maximumDuration: beats(4),
                                                       allowsRests: false,
                                                       maximumRestDuration: beats(1))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StandardBeatOptions.Constraints.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func hashable() {
        let constraints: Set = [StandardBeatOptions.Constraints(),
                                StandardBeatOptions.Constraints(),
                                StandardBeatOptions.Constraints(allowsRests: false)]

        #expect(constraints.count == 2)
    }

    @Test
    func isEmpty_default() {
        #expect(StandardBeatOptions.Constraints().isEmpty)
    }

    @Test
    func isEmpty_eachConstraint_makesNonEmpty() {
        #expect(!StandardBeatOptions.Constraints(pitchRange: Pitch.c4...Pitch.c5).isEmpty)
        #expect(!StandardBeatOptions.Constraints(allowedPitches: []).isEmpty)
        #expect(!StandardBeatOptions.Constraints(maximumDuration: beats(1)).isEmpty)
        #expect(!StandardBeatOptions.Constraints(allowsRests: false).isEmpty)
        #expect(!StandardBeatOptions.Constraints(maximumRestDuration: beats(1)).isEmpty)
    }
}
