// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct FrequencyTemplatePitchTests {
}

// MARK: -

extension FrequencyTemplatePitchTests {
    @Test
    func nearest_sameOctave() {
        #expect(Frequency(450).nearest(0) == Frequency(440))
    }

    @Test
    func nearest_wrapsToNextOctave() {
        #expect(Frequency(860).nearest(0) == Frequency(880))
    }

    @Test
    func pitchClass_a4_isZero() {
        #expect(Frequency(440).pitchClass == 0)
    }

    @Test
    func pitchClass_belowA_wrapsAround() {
        #expect(Frequency(Number(415.304698)).pitchClass == 1_100)
    }

    @Test
    func pitchClass_octaveAbove_isSame() {
        #expect(Frequency(880).pitchClass == 0)
    }

    @Test
    func shifted_octaveDown() {
        #expect(Frequency(440).shifted(octaves: -1) == Frequency(220))
    }

    @Test
    func shifted_octaveUp() {
        #expect(Frequency(440).shifted(octaves: 1) == Frequency(880))
    }

    @Test
    func templateInterval_ascendingOctave() throws {
        let interval = try #require(Frequency(440).templateInterval(to: Frequency(880)))

        #expect(interval.direction == .ascending)
        #expect(interval.interval == .octave)
    }

    @Test
    func templateInterval_descendingOctave() throws {
        let interval = try #require(Frequency(880).templateInterval(to: Frequency(440)))

        #expect(interval.direction == .descending)
        #expect(interval.interval == .octave)
    }

    @Test
    func templateInterval_roundsToWholeCents() throws {
        let interval = try #require(Frequency(440).templateInterval(to: Frequency(Number(440.1))))

        #expect(interval.direction == .same)
        #expect(interval.interval == .unison)
    }
}
