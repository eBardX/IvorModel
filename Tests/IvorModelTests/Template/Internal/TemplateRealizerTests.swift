// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TemplateRealizerTests {
}

// MARK: -

extension TemplateRealizerTests {
    @Test
    func advance_absolute_realizesEvent() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(),
                                                          isRelative: false,
                                                          memberSeed: 0)

        let event = realizer.advance(with: StandardBeatState(isRest: false,
                                                             duration: .absolute(beats(1)),
                                                             pitches: .absolute([Template.Tone(value: .c4,
                                                                                               startsTie: true,
                                                                                               endsTie: false)])))

        #expect(event == NoteEvent(tiedPitches: [.init(pitch: .c4, startsTie: true)], duration: beats(1)))
    }

    @Test
    func advance_interval_followsPreviousBass() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(startPitch: .c4),
                                                          isRelative: false,
                                                          memberSeed: 0)
        let state = StandardBeatState(isRest: false,
                                      duration: .absolute(beats(1)),
                                      pitches: .interval(bass: DirectedInterval(interval: .major3, direction: .ascending),
                                                         shape: [Template.Tone(value: DirectedInterval(interval: .perfect1,
                                                                                                       direction: .same),
                                                                               startsTie: false,
                                                                               endsTie: false)]))

        let event1 = realizer.advance(with: state)
        let event2 = realizer.advance(with: state)

        #expect(event1?.tiedPitches.map(\.pitch) == [.e4])
        #expect(event2?.tiedPitches.map(\.pitch) == [Pitch(pitchClass: .gSharp, octave: 4)])
    }

    @Test
    func advance_interval_outOfRange_reflects() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(constraints: .init(pitchRange: Pitch.c4...Pitch.a4),
                                                                         startPitch: .g4),
                                                          isRelative: true,
                                                          memberSeed: 0)
        let state = StandardBeatState(isRest: false,
                                      duration: .absolute(beats(1)),
                                      pitches: .interval(bass: DirectedInterval(interval: .major3, direction: .ascending),
                                                         shape: [Template.Tone(value: DirectedInterval(interval: .perfect1,
                                                                                                       direction: .same),
                                                                               startsTie: false,
                                                                               endsTie: false)]))

        #expect(!realizer.allows(state, as: .joint, checkingRange: true))
        #expect(realizer.advance(with: state)?.tiedPitches.map(\.pitch) == [Pitch(pitchClass: .eFlat, octave: 4)])
    }

    @Test
    func advance_noDuration_usesStartDuration() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(startDuration: beats(2)),
                                                          isRelative: false,
                                                          memberSeed: 0)

        let event = realizer.advance(with: StandardBeatState(isRest: true, duration: nil, pitches: nil))

        #expect(event == NoteEvent(tiedPitches: [], duration: beats(2)))
    }

    @Test
    func advance_noDurationOrDefault_isNil() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(),
                                                          isRelative: false,
                                                          memberSeed: 0)

        #expect(realizer.advance(with: StandardBeatState(isRest: true, duration: nil, pitches: nil)) == nil)
    }

    @Test
    func advance_noPitches_usesStartPitch() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(startPitch: .d4),
                                                          isRelative: false,
                                                          memberSeed: 0)

        let event = realizer.advance(with: StandardBeatState(isRest: false, duration: .absolute(beats(1)), pitches: nil))

        #expect(event == NoteEvent(pitches: [.d4], duration: beats(1)))
    }

    @Test
    func advance_phrase_anchorsStartFromItsEnd() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(startPitch: .c4, startDuration: beats(1)),
                                                          isRelative: false,
                                                          phrase: [NoteEvent(pitches: [.e4], duration: beats(3))],
                                                          memberSeed: 0)
        let state = StandardBeatState(isRest: false,
                                      duration: .relative(1),
                                      pitches: .interval(bass: DirectedInterval(interval: .major2, direction: .ascending),
                                                         shape: [Template.Tone(value: DirectedInterval(interval: .perfect1,
                                                                                                       direction: .same),
                                                                               startsTie: false,
                                                                               endsTie: false)]))

        let event = realizer.advance(with: state)

        #expect(event == NoteEvent(pitches: [Pitch(pitchClass: .fSharp, octave: 4)], duration: beats(3)))
    }

    @Test
    func advance_pitchClass_closePositionNearPrevious() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(startPitch: .c4),
                                                          isRelative: false,
                                                          memberSeed: 0)
        let state = StandardBeatState(isRest: false,
                                      duration: .absolute(beats(1)),
                                      pitches: .pitchClass([Template.Tone(value: .c, startsTie: false, endsTie: false),
                                                            Template.Tone(value: .e, startsTie: false, endsTie: false),
                                                            Template.Tone(value: .g, startsTie: false, endsTie: false)]))

        #expect(realizer.advance(with: state)?.tiedPitches.map(\.pitch) == [.c4, .e4, .g4])
    }

    @Test
    func advance_relativeDuration_followsPreviousDuration() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(startDuration: beats(1)),
                                                          isRelative: false,
                                                          memberSeed: 0)
        let state = StandardBeatState(isRest: true, duration: .relative(2), pitches: nil)

        #expect(realizer.advance(with: state)?.duration == beats(2))
        #expect(realizer.advance(with: state)?.duration == beats(4))
    }

    @Test
    func advance_samplesMembers_drawsMember() {
        let nearlyOne = beats(Number(numerator: 21, denominator: 20))
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(durationMembers: [beats(1): [nearlyOne: 1]],
                                                                            pitchMembers: [.c4: [.b3: 1]]),
                                                          options: .init(samplesMembers: true),
                                                          isRelative: false,
                                                          memberSeed: 7)
        let state = StandardBeatState(isRest: false,
                                      duration: .absolute(beats(1)),
                                      pitches: .absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)]))

        #expect(realizer.advance(with: state) == NoteEvent(pitches: [.b3], duration: nearlyOne))
    }

    @Test
    func advance_withoutSamplingMembers_keepsRepresentative() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(pitchMembers: [.c4: [.b3: 1]]),
                                                          options: .init(),
                                                          isRelative: false,
                                                          memberSeed: 7)
        let state = StandardBeatState(isRest: false,
                                      duration: .absolute(beats(1)),
                                      pitches: .absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)]))

        #expect(realizer.advance(with: state) == NoteEvent(pitches: [.c4], duration: beats(1)))
    }

    @Test
    func allows_duration_checksDurationConstraints() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(constraints: .init(maximumDuration: beats(1))),
                                                          isRelative: false,
                                                          memberSeed: 0)

        #expect(realizer.allows(StandardBeatState(isRest: false, duration: .absolute(beats(1)), pitches: nil),
                                as: .duration,
                                checkingRange: true))
        #expect(!realizer.allows(StandardBeatState(isRest: false, duration: .absolute(beats(2)), pitches: nil),
                                 as: .duration,
                                 checkingRange: true))
    }

    @Test
    func allows_joint_checksPitchConstraints() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(constraints: .init(allowedPitches: [.c4])),
                                                          isRelative: false,
                                                          memberSeed: 0)

        #expect(realizer.allows(StandardBeatState(isRest: false,
                                                  duration: .absolute(beats(1)),
                                                  pitches: .absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)])),
                                as: .joint,
                                checkingRange: true))
        #expect(!realizer.allows(StandardBeatState(isRest: false,
                                                   duration: .absolute(beats(1)),
                                                   pitches: .absolute([Template.Tone(value: .d4, startsTie: false, endsTie: false)])),
                                 as: .joint,
                                 checkingRange: true))
    }

    @Test
    func allows_pitch_checksOnlyPitches() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(),
                                                          options: .init(constraints: .init(pitchRange: Pitch.c4...Pitch.g4,
                                                                                            maximumDuration: beats(1))),
                                                          isRelative: false,
                                                          memberSeed: 0)

        #expect(realizer.allows(StandardBeatState(isRest: false,
                                                  duration: nil,
                                                  pitches: .absolute([Template.Tone(value: .e4, startsTie: false, endsTie: false)])),
                                as: .pitch,
                                checkingRange: true))
        #expect(!realizer.allows(StandardBeatState(isRest: false,
                                                   duration: nil,
                                                   pitches: .absolute([Template.Tone(value: .a4, startsTie: false, endsTie: false)])),
                                 as: .pitch,
                                 checkingRange: true))
    }

    @Test
    func range_notRelative_isNil() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(pitches: [.c4: 1]),
                                                          options: .init(constraints: .init(pitchRange: Pitch.c4...Pitch.c5)),
                                                          isRelative: false,
                                                          memberSeed: 0)

        #expect(realizer.range == nil)
    }

    @Test
    func range_relative_sourceRangeMovedToStartPitch() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(pitches: [.c4: 1, .g4: 1],
                                                                            first: NoteEvent(pitches: [.c4], duration: beats(1))),
                                                          options: .init(startPitch: .d4),
                                                          isRelative: true,
                                                          memberSeed: 0)

        #expect(realizer.range == Pitch.d4...Pitch.a4)
    }

    @Test
    func range_relative_usesConstraintsRange() {
        let realizer = Template.Realizer<BeatTime, Pitch>(vocabulary: .init(pitches: [.c4: 1]),
                                                          options: .init(constraints: .init(pitchRange: Pitch.c4...Pitch.c5)),
                                                          isRelative: true,
                                                          memberSeed: 0)

        #expect(realizer.range == Pitch.c4...Pitch.c5)
    }
}
