// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TemplatePitchTests {
}

// MARK: -

extension TemplatePitchTests {
    @Test
    func nearest_keepsPitchClassForEveryConformer() throws {
        #expect(try #require(Pitch.c4.nearest(.g)).pitchClass == .g)
        #expect(try #require(NoteNumber(60).nearest(7)).pitchClass == 7)
        #expect(try #require(Frequency(440).nearest(3)).pitchClass == 3)
    }

    @Test
    func shifted_zeroOctaves_isSamePitchForEveryConformer() {
        #expect(Pitch.c4.shifted(octaves: 0) == .c4)
        #expect(NoteNumber(60).shifted(octaves: 0) == NoteNumber(60))
        #expect(Frequency(440).shifted(octaves: 0) == Frequency(440))
    }

    @Test
    func templateInterval_default_isInterval() {
        #expect(Pitch.c4.templateInterval(to: .g4) == Pitch.c4.interval(to: .g4))
        #expect(Pitch.g4.templateInterval(to: .c4) == Pitch.g4.interval(to: .c4))
        #expect(NoteNumber(60).templateInterval(to: NoteNumber(67)) == NoteNumber(60).interval(to: NoteNumber(67)))
        #expect(NoteNumber(67).templateInterval(to: NoteNumber(60)) == NoteNumber(67).interval(to: NoteNumber(60)))
    }
}
