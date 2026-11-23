// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
import Testing

struct NoteNumberRenderablePitchTests {
}

// MARK: -

extension NoteNumberRenderablePitchTests {
    @Test
    func partner_belowTheLowestNoteIsNil() throws {
        #expect(try #require(NoteNumber(uintValue: 0)).partner(on: .below, rule: .halfStep, key: nil) == nil)
    }

    @Test
    func partner_diatonicIsAWholeToneEvenInAKey() throws {
        let middleC = try #require(NoteNumber(uintValue: 60))

        #expect(middleC.partner(on: .above, rule: .diatonic, key: key(-1)) == NoteNumber(uintValue: 62))
        #expect(middleC.partner(on: .below, rule: .diatonic, key: nil) == NoteNumber(uintValue: 58))
    }

    @Test
    func partner_halfStep() throws {
        let middleC = try #require(NoteNumber(uintValue: 60))

        #expect(middleC.partner(on: .above, rule: .halfStep, key: nil) == NoteNumber(uintValue: 61))
        #expect(middleC.partner(on: .below, rule: .halfStep, key: nil) == NoteNumber(uintValue: 59))
    }

    @Test
    func partner_wholeStep() throws {
        let middleC = try #require(NoteNumber(uintValue: 60))

        #expect(middleC.partner(on: .above, rule: .wholeStep, key: nil) == NoteNumber(uintValue: 62))
        #expect(middleC.partner(on: .below, rule: .wholeStep, key: nil) == NoteNumber(uintValue: 58))
    }
}
