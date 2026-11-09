// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateGenerationOptionsCadenceTests {
}

// MARK: -

extension TemplateGenerationOptionsCadenceTests {
    @Test
    func codable() throws {
        let original = StandardBeatOptions.Cadence(pitches: [.c4, .e4],
                                                   duration: beats(2),
                                                   minimumLength: .noteCount(8))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StandardBeatOptions.Cadence.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func hashable() {
        let cadences: Set = [StandardBeatOptions.Cadence(pitches: [.c4], minimumLength: .noteCount(4)),
                             StandardBeatOptions.Cadence(pitches: [.c4], minimumLength: .noteCount(4)),
                             StandardBeatOptions.Cadence(pitches: [.d4], minimumLength: .noteCount(4))]

        #expect(cadences.count == 2)
    }

    @Test
    func init_defaultDurationIsNil() {
        let cadence = StandardBeatOptions.Cadence(pitches: [.c4], minimumLength: .noteCount(4))

        #expect(cadence.duration == nil)
        #expect(cadence.minimumLength == .noteCount(4))
        #expect(cadence.pitches == [.c4])
    }

    @Test
    func matches_chord_requiresExactPitchSet() {
        let cadence = StandardBeatOptions.Cadence(pitches: [.c4, .e4], minimumLength: .noteCount(4))

        #expect(cadence.matches(NoteEvent(pitches: [.e4, .c4], duration: beats(1))))
        #expect(!cadence.matches(NoteEvent(pitches: [.c4], duration: beats(1))))
        #expect(!cadence.matches(NoteEvent(pitches: [.c4, .e4, .g4], duration: beats(1))))
    }

    @Test
    func matches_duration_mustMatchWhenGiven() {
        let cadence = StandardBeatOptions.Cadence(pitches: [.c4],
                                                  duration: beats(2),
                                                  minimumLength: .noteCount(4))

        #expect(cadence.matches(NoteEvent(pitches: [.c4], duration: beats(2))))
        #expect(!cadence.matches(NoteEvent(pitches: [.c4], duration: beats(1))))
    }

    @Test
    func matches_withoutDuration_ignoresDuration() {
        let cadence = StandardBeatOptions.Cadence(pitches: [.c4], minimumLength: .noteCount(4))

        #expect(cadence.matches(NoteEvent(pitches: [.c4], duration: beats(1))))
        #expect(cadence.matches(NoteEvent(pitches: [.c4], duration: beats(3))))
        #expect(!cadence.matches(NoteEvent(pitches: [.d4], duration: beats(1))))
    }
}
