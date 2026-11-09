// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct PitchTemplatePitchTests {
}

// MARK: -

extension PitchTemplatePitchTests {
    @Test
    func nearest_below() {
        #expect(Pitch.c4.nearest(.b) == .b3)
        #expect(Pitch.c4.nearest(.g) == .g3)
    }

    @Test
    func nearest_enharmonic_isSameSound() {
        #expect(Pitch.c4.nearest(.bSharp) == Pitch(pitchClass: .bSharp, octave: 3))
    }

    @Test
    func nearest_lowestOctave_staysInRange() {
        #expect(Pitch(pitchClass: .c, octave: -1).nearest(.b) == Pitch(pitchClass: .b, octave: -1))
    }

    @Test
    func nearest_samePitchClass() {
        #expect(Pitch.e4.nearest(.e) == .e4)
    }

    @Test
    func shifted_down() {
        #expect(Pitch.c4.shifted(octaves: -1) == .c3)
    }

    @Test
    func shifted_outOfRange_isNil() {
        #expect(Pitch.c4.shifted(octaves: 10) == nil)
    }

    @Test
    func shifted_up() {
        #expect(Pitch.c4.shifted(octaves: 1) == .c5)
    }

    @Test
    func templateInterval_matchesInterval() {
        #expect(Pitch.c4.templateInterval(to: .g4) == Pitch.c4.interval(to: .g4))
    }
}
