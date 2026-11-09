// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateVocabularyTests {
}

// MARK: -

extension TemplateVocabularyTests {
    @Test
    func adding_firstFallsBackToOther() {
        let event = NoteEvent<BeatTime, Pitch>(pitches: [.c4], duration: beats(1))
        let empty = Template.Vocabulary<BeatTime, Pitch>()
        let other = Template.Vocabulary<BeatTime, Pitch>(first: event)

        #expect(empty.adding(other).first == event)
    }

    @Test
    func adding_keepsOwnFirst() {
        let event1 = NoteEvent<BeatTime, Pitch>(pitches: [.c4], duration: beats(1))
        let event2 = NoteEvent<BeatTime, Pitch>(pitches: [.d4], duration: beats(1))
        let vocabulary1 = Template.Vocabulary<BeatTime, Pitch>(first: event1)
        let vocabulary2 = Template.Vocabulary<BeatTime, Pitch>(first: event2)

        #expect(vocabulary1.adding(vocabulary2).first == event1)
    }

    @Test
    func adding_sumsCountsAndMembers() {
        let vocabulary1 = Template.Vocabulary<BeatTime, Pitch>(durations: [beats(1): 2],
                                                               pitches: [.c4: 1],
                                                               durationMembers: [beats(1): [beats(1): 2]],
                                                               pitchMembers: [.c4: [.c4: 1]])
        let vocabulary2 = Template.Vocabulary<BeatTime, Pitch>(durations: [beats(1): 1, beats(2): 4],
                                                               pitches: [.c4: 3],
                                                               durationMembers: [beats(1): [beats(1): 1]],
                                                               pitchMembers: [.c4: [.b3: 3]])

        let result = vocabulary1.adding(vocabulary2)

        #expect(result.durations == [beats(1): 3, beats(2): 4])
        #expect(result.pitches == [.c4: 4])
        #expect(result.durationMembers == [beats(1): [beats(1): 3]])
        #expect(result.pitchMembers == [.c4: [.c4: 1, .b3: 3]])
    }

    @Test
    func codable() throws {
        let original = Template.Vocabulary<BeatTime, Pitch>(durations: [beats(1): 2, beats(2): 1],
                                                            pitches: [.c4: 2, .e4: 1],
                                                            first: NoteEvent(pitches: [.c4], duration: beats(1)),
                                                            durationMembers: [beats(1): [beats(1): 2]],
                                                            pitchMembers: [.c4: [.c4: 1, .b3: 1]])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Template.Vocabulary<BeatTime, Pitch>.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func commonestDuration_mostCommon() {
        let vocabulary = Template.Vocabulary<BeatTime, Pitch>(durations: [beats(1): 2, beats(2): 5])

        #expect(vocabulary.commonestDuration == beats(2))
    }

    @Test
    func commonestDuration_tie_isShortest() {
        let vocabulary = Template.Vocabulary<BeatTime, Pitch>(durations: [beats(1): 3, beats(2): 3])

        #expect(vocabulary.commonestDuration == beats(1))
    }

    @Test
    func commonestPitch_empty_isNil() {
        #expect(Template.Vocabulary<BeatTime, Pitch>().commonestPitch == nil)
    }

    @Test
    func commonestPitch_tie_isLowest() {
        let vocabulary = Template.Vocabulary<BeatTime, Pitch>(pitches: [.e4: 2, .c4: 2, .d4: 1])

        #expect(vocabulary.commonestPitch == .c4)
    }

    @Test
    func hashable() {
        let vocabularies: Set = [Template.Vocabulary<BeatTime, Pitch>(),
                                 Template.Vocabulary<BeatTime, Pitch>(),
                                 Template.Vocabulary<BeatTime, Pitch>(pitches: [.c4: 1])]

        #expect(vocabularies.count == 2)
    }

    @Test
    func init_defaultsAreEmpty() {
        let vocabulary = Template.Vocabulary<BeatTime, Pitch>()

        #expect(vocabulary.durationMembers.isEmpty)
        #expect(vocabulary.durations.isEmpty)
        #expect(vocabulary.first == nil)
        #expect(vocabulary.pitches.isEmpty)
        #expect(vocabulary.pitchMembers.isEmpty)
    }

    @Test
    func pitchRange_empty_isNil() {
        #expect(Template.Vocabulary<BeatTime, Pitch>().pitchRange == nil)
    }

    @Test
    func pitchRange_spansLowestToHighest() {
        let vocabulary = Template.Vocabulary<BeatTime, Pitch>(pitches: [.e4: 1, .c4: 3, .g4: 1])

        #expect(vocabulary.pitchRange == Pitch.c4...Pitch.g4)
    }
}
