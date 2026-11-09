// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateStateTests {
}

// MARK: -

extension TemplateStateTests {
    @Test
    func codable() throws {
        let original = StandardBeatState(isRest: false,
                                         duration: .absolute(beats(1)),
                                         pitches: .absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)]))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StandardBeatState.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func comparable_byDurationThenPitches() {
        let shortC = StandardBeatState(isRest: false,
                                       duration: .absolute(beats(1)),
                                       pitches: .absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)]))
        let shortD = StandardBeatState(isRest: false,
                                       duration: .absolute(beats(1)),
                                       pitches: .absolute([Template.Tone(value: .d4, startsTie: false, endsTie: false)]))
        let longC = StandardBeatState(isRest: false,
                                      duration: .absolute(beats(2)),
                                      pitches: .absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)]))

        #expect(shortC < shortD)
        #expect(shortD < longC)
    }

    @Test
    func comparable_missingValuesFirst() {
        let noDuration = StandardBeatState(isRest: false, duration: nil, pitches: nil)
        let withDuration = StandardBeatState(isRest: false, duration: .absolute(beats(1)), pitches: nil)
        let withPitches = StandardBeatState(isRest: false, duration: nil, pitches: .absolute([]))

        #expect(noDuration < withDuration)
        #expect(noDuration < withPitches)
        #expect(!(withDuration < noDuration))
    }

    @Test
    func comparable_soundingBeforeRest() {
        let sounding = StandardBeatState(isRest: false, duration: .absolute(beats(8)), pitches: nil)
        let rest = StandardBeatState(isRest: true, duration: .absolute(beats(1)), pitches: nil)

        #expect(sounding < rest)
        #expect(!(rest < sounding))
    }

    @Test
    func durationHalf_dropsPitches() {
        let state = StandardBeatState(isRest: false,
                                      duration: .absolute(beats(1)),
                                      pitches: .absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)]))

        #expect(state.durationHalf == StandardBeatState(isRest: false, duration: .absolute(beats(1)), pitches: nil))
    }

    @Test
    func hashable() {
        let states: Set = [StandardBeatState(isRest: true, duration: .absolute(beats(1)), pitches: nil),
                           StandardBeatState(isRest: true, duration: .absolute(beats(1)), pitches: nil),
                           StandardBeatState(isRest: false, duration: .absolute(beats(1)), pitches: nil)]

        #expect(states.count == 2)
    }

    @Test
    func init_storesValues() {
        let pitches = StandardBeatState.PitchValue.absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)])
        let state = StandardBeatState(isRest: false, duration: .relative(2), pitches: pitches)

        #expect(state.duration == .relative(2))
        #expect(!state.isRest)
        #expect(state.pitches == pitches)
    }

    @Test
    func initHalves_rest_ignoresPitchHalf() {
        let durationHalf = StandardBeatState(isRest: true, duration: .absolute(beats(1)), pitches: nil)
        let pitchHalf = StandardBeatState(isRest: false, duration: nil, pitches: .absolute([]))

        let state = StandardBeatState(durationHalf: durationHalf, pitchHalf: pitchHalf)

        #expect(state == durationHalf)
    }

    @Test
    func initHalves_sounding_joinsHalves() {
        let pitches = StandardBeatState.PitchValue.absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)])
        let durationHalf = StandardBeatState(isRest: false, duration: .absolute(beats(1)), pitches: nil)
        let pitchHalf = StandardBeatState(isRest: false, duration: nil, pitches: pitches)

        let state = StandardBeatState(durationHalf: durationHalf, pitchHalf: pitchHalf)

        #expect(state == StandardBeatState(isRest: false, duration: .absolute(beats(1)), pitches: pitches))
    }

    @Test
    func initHalves_withoutPitchHalf_hasNoPitches() {
        let durationHalf = StandardBeatState(isRest: false, duration: .absolute(beats(1)), pitches: nil)

        #expect(StandardBeatState(durationHalf: durationHalf, pitchHalf: nil).pitches == nil)
    }

    @Test
    func pitchHalf_dropsDurationAndRest() {
        let pitches = StandardBeatState.PitchValue.absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)])
        let state = StandardBeatState(isRest: false, duration: .absolute(beats(1)), pitches: pitches)

        #expect(state.pitchHalf == StandardBeatState(isRest: false, duration: nil, pitches: pitches))
    }
}
