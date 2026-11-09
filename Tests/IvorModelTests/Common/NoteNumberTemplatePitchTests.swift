// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteNumberTemplatePitchTests {
}

// MARK: -

extension NoteNumberTemplatePitchTests {
    @Test
    func nearest_above() {
        #expect(NoteNumber(60).nearest(5) == NoteNumber(65))
    }

    @Test
    func nearest_below() {
        #expect(NoteNumber(60).nearest(11) == NoteNumber(59))
    }

    @Test
    func nearest_nearTop_skipsOutOfRange() {
        #expect(NoteNumber(127).nearest(0) == NoteNumber(120))
        #expect(NoteNumber(126).nearest(1) == NoteNumber(121))
    }

    @Test
    func nearest_nearZero_skipsNegative() {
        #expect(NoteNumber(1).nearest(11) == NoteNumber(11))
    }

    @Test
    func nearest_samePitchClass() {
        #expect(NoteNumber(64).nearest(4) == NoteNumber(64))
    }

    @Test
    func pitchClass() {
        #expect(NoteNumber(60).pitchClass == 0)
        #expect(NoteNumber(61).pitchClass == 1)
        #expect(NoteNumber(71).pitchClass == 11)
    }

    @Test
    func shifted_belowZero_isNil() {
        #expect(NoteNumber(60).shifted(octaves: -6) == nil)
    }

    @Test
    func shifted_down() {
        #expect(NoteNumber(60).shifted(octaves: -1) == NoteNumber(48))
    }

    @Test
    func shifted_outOfRange_isNil() {
        #expect(NoteNumber(60).shifted(octaves: 6) == nil)
    }

    @Test
    func shifted_up() {
        #expect(NoteNumber(60).shifted(octaves: 1) == NoteNumber(72))
    }

    @Test
    func templateInterval_matchesInterval() {
        #expect(NoteNumber(60).templateInterval(to: NoteNumber(67)) == NoteNumber(60).interval(to: NoteNumber(67)))
    }
}
