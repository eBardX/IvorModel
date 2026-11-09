// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TemplateStateBuilderTests {
}

// MARK: -

extension TemplateStateBuilderTests {
    @Test
    func state_absolute_recordsPitchesAndDuration() {
        var builder = Template.StateBuilder<BeatTime, Pitch>(recipe: .exact)

        let state = builder.state(for: NoteEvent(tiedPitches: [.init(pitch: .c4, startsTie: true), .init(pitch: .e4)],
                                                 duration: beats(2)))

        #expect(state == StandardBeatState(isRest: false,
                                           duration: .absolute(beats(2)),
                                           pitches: .absolute([Template.Tone(value: .c4, startsTie: true, endsTie: false),
                                                               Template.Tone(value: .e4, startsTie: false, endsTie: false)])))
    }

    @Test
    func state_duration_omitted() {
        var builder = Template.StateBuilder<BeatTime, Pitch>(recipe: .init(duration: .omitted))

        #expect(builder.state(for: NoteEvent(pitches: [.c4], duration: beats(2))).duration == nil)
    }

    @Test
    func state_duration_relative_measuresFromPreviousEvent() {
        var builder = Template.StateBuilder<BeatTime, Pitch>(recipe: .init(duration: .relative))

        let state1 = builder.state(for: NoteEvent(pitches: [.c4], duration: beats(2)))
        let state2 = builder.state(for: NoteEvent(tiedPitches: [], duration: beats(1)))
        let state3 = builder.state(for: NoteEvent(pitches: [.d4], duration: beats(3)))

        #expect(state1.duration == .relative(1))
        #expect(state2.duration == .relative(Number(numerator: 1, denominator: 2)))
        #expect(state3.duration == .relative(3))
    }

    @Test
    func state_interval_firstBassIsUnison() {
        var builder = Template.StateBuilder<BeatTime, Pitch>(recipe: .init(pitch: .interval))

        let state = builder.state(for: NoteEvent(pitches: [.e4, .c4], duration: beats(1)))

        #expect(state.pitches == .interval(bass: DirectedInterval(interval: .perfect1, direction: .same),
                                           shape: [Template.Tone(value: DirectedInterval(interval: .perfect1, direction: .same),
                                                                 startsTie: false,
                                                                 endsTie: false),
                                                   Template.Tone(value: DirectedInterval(interval: .major3, direction: .ascending),
                                                                 startsTie: false,
                                                                 endsTie: false)].sorted()))
    }

    @Test
    func state_interval_restKeepsPreviousBass() {
        var builder = Template.StateBuilder<BeatTime, Pitch>(recipe: .init(pitch: .interval))

        _ = builder.state(for: NoteEvent(pitches: [.c4], duration: beats(1)))
        _ = builder.state(for: NoteEvent(tiedPitches: [], duration: beats(1)))

        let state = builder.state(for: NoteEvent(pitches: [.e4], duration: beats(1)))

        guard case let .interval(bass, _) = state.pitches
        else { Issue.record("Expected an interval"); return }

        #expect(bass == DirectedInterval(interval: .major3, direction: .ascending))
    }

    @Test
    func state_pitch_omitted() {
        var builder = Template.StateBuilder<BeatTime, Pitch>(recipe: .init(pitch: .omitted))

        let state = builder.state(for: NoteEvent(pitches: [.c4], duration: beats(1)))

        #expect(!state.isRest)
        #expect(state.pitches == nil)
    }

    @Test
    func state_pitchClass_lowestFirstEachClassOnce() {
        var builder = Template.StateBuilder<BeatTime, Pitch>(recipe: .init(pitch: .pitchClass))

        let state = builder.state(for: NoteEvent(tiedPitches: [.init(pitch: .c5), .init(pitch: .e4), .init(pitch: .c4, endsTie: true)],
                                                 duration: beats(1)))

        #expect(state.pitches == .pitchClass([Template.Tone(value: .c, startsTie: false, endsTie: true),
                                              Template.Tone(value: .e, startsTie: false, endsTie: false)]))
    }

    @Test
    func state_rest_hasNoPitches() {
        var builder = Template.StateBuilder<BeatTime, Pitch>(recipe: .exact)

        let state = builder.state(for: NoteEvent(tiedPitches: [], duration: beats(2)))

        #expect(state == StandardBeatState(isRest: true, duration: .absolute(beats(2)), pitches: nil))
    }
}
