// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
import Testing

struct PitchRenderablePitchTests {
}

// MARK: -

extension PitchRenderablePitchTests {
    @Test
    func partner_diatonicAcrossTheOctave() {
        #expect(Pitch.b4.partner(on: .above, rule: .diatonic, key: key(0)) == .c5)
        #expect(Pitch.c4.partner(on: .below, rule: .diatonic, key: key(0)) == .b3)
    }

    @Test
    func partner_diatonicInAKeyWithFlats() {
        #expect(Pitch.a4.partner(on: .above, rule: .diatonic, key: key(-1)) == "B♭4")
        #expect(Pitch.c5.partner(on: .below, rule: .diatonic, key: key(-1)) == "B♭4")
    }

    @Test
    func partner_diatonicInAKeyWithSharps() {
        #expect(Pitch.e4.partner(on: .above, rule: .diatonic, key: key(2)) == "F♯4")
    }

    @Test
    func partner_diatonicInCMajor() {
        #expect(Pitch.e4.partner(on: .above, rule: .diatonic, key: key(0)) == .f4)
        #expect(Pitch.e4.partner(on: .below, rule: .diatonic, key: key(0)) == .d4)
    }

    @Test
    func partner_diatonicThatWouldLandBelowFallsBackToAWholeTone() {
        //
        // In C♭ major the letter above B♯4 is C♭5, which sounds lower than B♯4 itself.
        //
        let main: Pitch = "B♯4"

        #expect(main.partner(on: .above, rule: .diatonic, key: key(-7))
            == main.transposed(by: DirectedInterval(interval: .major2, direction: .ascending)))
        #expect(main.partner(on: .above, rule: .diatonic, key: key(-1))
            == main.transposed(by: DirectedInterval(interval: .major2, direction: .ascending)))
    }

    @Test
    func partner_diatonicWithAnAtonalKeyIsAWholeTone() {
        #expect(Pitch.e4.partner(on: .above, rule: .diatonic, key: .atonal) == "F♯4")
    }

    @Test
    func partner_diatonicWithNoKeyIsAWholeTone() {
        #expect(Pitch.e4.partner(on: .above, rule: .diatonic, key: nil) == "F♯4")
        #expect(Pitch.c4.partner(on: .below, rule: .diatonic, key: nil) == "B♭3")
    }

    @Test
    func partner_halfStep() {
        #expect(Pitch.e4.partner(on: .above, rule: .halfStep, key: key(2)) == .f4)
        #expect(Pitch.c4.partner(on: .below, rule: .halfStep, key: nil) == .b3)
    }

    @Test
    func partner_wholeStep() {
        #expect(Pitch.e4.partner(on: .above, rule: .wholeStep, key: key(-1)) == "F♯4")
        #expect(Pitch.c4.partner(on: .below, rule: .wholeStep, key: nil) == "B♭3")
    }
}
