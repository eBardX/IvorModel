// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TemplatePhraseLearnerTests {
}

// MARK: -

extension TemplatePhraseLearnerTests {
    @Test
    func learn_member_mapsToRepresentative() {
        let nearlyOne = beats(Number(numerator: 21, denominator: 20))
        let learner = Template.PhraseLearner<BeatTime, Pitch>(analysisOptions: .init(maximumOrder: 1),
                                                              vocabulary: .init(durations: [beats(1): 2],
                                                                                durationMembers: [beats(1): [beats(1): 1, nearlyOne: 1]]),
                                                              grouping: { _ in [:] },
                                                              rounding: { $0 })

        let (noteEvents, _) = learner.learn([NoteEvent(pitches: [.c4], duration: nearlyOne)])

        #expect(noteEvents == [NoteEvent(pitches: [.c4], duration: beats(1))])
    }

    @Test
    func learn_noTolerance_keepsNoteEvents() {
        let phrase = [NoteEvent<BeatTime, Pitch>(pitches: [.c4], duration: beats(1)),
                      NoteEvent(tiedPitches: [], duration: beats(2))]
        let learner = Template.PhraseLearner<BeatTime, Pitch>(analysisOptions: .init(maximumOrder: 1),
                                                              vocabulary: .init(),
                                                              grouping: { _ in [:] },
                                                              rounding: { $0 })

        let (noteEvents, states) = learner.learn(phrase)

        #expect(noteEvents == phrase)
        #expect(states == makeExactStates(phrase))
    }

    @Test
    func learn_proportional_nearestRepresentativeWithinBand() throws {
        let nearlyOne = beats(Number(numerator: 21, denominator: 20))
        let learner = try Template.PhraseLearner<BeatTime, Pitch>(analysisOptions: .init(maximumOrder: 1,
                                                                                         durations: .proportional(0.1)),
                                                                  vocabulary: .init(durations: [beats(1): 3, beats(2): 1]),
                                                                  grouping: Template.beatGrouping(.proportional(0.1))) { $0 }

        let (noteEvents, _) = learner.learn([NoteEvent(pitches: [.c4], duration: nearlyOne)])

        #expect(noteEvents.map(\.duration) == [beats(1)])
    }

    @Test
    func learn_proportional_outsideBand_keepsDuration() throws {
        let learner = try Template.PhraseLearner<BeatTime, Pitch>(analysisOptions: .init(maximumOrder: 1,
                                                                                         durations: .proportional(0.1)),
                                                                  vocabulary: .init(durations: [beats(1): 3, beats(2): 1]),
                                                                  grouping: Template.beatGrouping(.proportional(0.1))) { $0 }

        let threeHalves = beats(Number(numerator: 3, denominator: 2))
        let (noteEvents, _) = learner.learn([NoteEvent(pitches: [.c4], duration: threeHalves)])

        #expect(noteEvents.map(\.duration) == [threeHalves])
    }

    @Test
    func learn_roundsPitches() {
        let learner = Template.PhraseLearner<BeatTime, Pitch>(analysisOptions: .init(maximumOrder: 1),
                                                              vocabulary: .init(),
                                                              grouping: { _ in [:] },
                                                              rounding: { _ in .c4 })

        let (noteEvents, _) = learner.learn([NoteEvent(pitches: [.d4, .e4], duration: beats(1))])

        #expect(noteEvents == [NoteEvent(pitches: [.c4], duration: beats(1))])
    }

    @Test
    func learn_statesFollowRecipe() {
        let learner = Template.PhraseLearner<BeatTime, Pitch>(analysisOptions: .init(maximumOrder: 1,
                                                                                     states: .init(pitch: .omitted,
                                                                                                   duration: .relative)),
                                                              vocabulary: .init(),
                                                              grouping: { _ in [:] },
                                                              rounding: { $0 })

        let (_, states) = learner.learn([NoteEvent(pitches: [.c4], duration: beats(1)),
                                         NoteEvent(pitches: [.d4], duration: beats(2))])

        #expect(states == [StandardBeatState(isRest: false, duration: .relative(1), pitches: nil),
                           StandardBeatState(isRest: false, duration: .relative(2), pitches: nil)])
    }
}
