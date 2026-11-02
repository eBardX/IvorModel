// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
import Testing
import XestiNumbers

struct WorkConvertContextTests {
}

// MARK: -

extension WorkConvertContextTests {
    @Test
    func builderChaining() {
        let expectedPitchStandard: PitchStandard = .a440
        let expectedTuningSystem = EqualTemperament.edo12

        let cc = Work.ConvertContext()
            .pitchStandard(expectedPitchStandard)
            .tuningSystem(expectedTuningSystem)

        #expect(cc.keyboardLayout == nil)
        #expect(cc.pitchSpeller == nil)
        #expect(cc.pitchStandard != nil)
        #expect(cc.tuningSystem != nil)
    }

    @Test
    func `default`() {
        let cc = Work.ConvertContext.default

        #expect(cc.keyboardLayout == .piano)
        #expect(cc.keyMatching == .nearest)
        #expect(cc.pitchSpeller != nil)
        #expect(cc.pitchStandard != nil)
        #expect(cc.tuningSystem != nil)
    }

    @Test
    func `init`() {
        let cc = Work.ConvertContext()

        #expect(cc.keyboardLayout == nil)
        #expect(cc.keyMatching == .nearest)
        #expect(cc.pitchSpeller == nil)
        #expect(cc.pitchStandard == nil)
        #expect(cc.tuningSystem == nil)
    }

    @Test
    func keyboardLayout() {
        let cc = Work.ConvertContext().keyboardLayout(.bohlenPierce)

        #expect(cc.keyboardLayout == .bohlenPierce)
        #expect(cc.keyMatching == .nearest)
        #expect(cc.pitchSpeller == nil)
        #expect(cc.pitchStandard == nil)
        #expect(cc.tuningSystem == nil)
    }

    @Test
    func keyMatching() {
        let cc = Work.ConvertContext()
            .keyboardLayout(.piano)
            .keyMatching(.within(Ratio(cents: 5)))

        #expect(cc.keyboardLayout == .piano)
        #expect(cc.keyMatching == .within(Ratio(cents: 5)))
        #expect(cc.pitchSpeller == nil)
        #expect(cc.pitchStandard == nil)
        #expect(cc.tuningSystem == nil)
    }

    @Test
    func pitchSpeller() {
        let expectedPitchSpeller = MeredithPitchSpeller()

        let cc = Work.ConvertContext().pitchSpeller(expectedPitchSpeller)

        #expect(cc.keyboardLayout == nil)
        #expect(cc.pitchSpeller != nil)
        #expect(cc.pitchStandard == nil)
        #expect(cc.tuningSystem == nil)
    }

    @Test
    func pitchStandard() {
        let expectedPitchStandard: PitchStandard = .a440

        let cc = Work.ConvertContext().pitchStandard(expectedPitchStandard)

        #expect(cc.keyboardLayout == nil)
        #expect(cc.pitchSpeller == nil)
        #expect(cc.pitchStandard != nil)
        #expect(cc.tuningSystem == nil)
    }

    @Test
    func tuningSystem() {
        let expectedTuningSystem = EqualTemperament.edo12

        let cc = Work.ConvertContext().tuningSystem(expectedTuningSystem)

        #expect(cc.keyboardLayout == nil)
        #expect(cc.pitchSpeller == nil)
        #expect(cc.pitchStandard == nil)
        #expect(cc.tuningSystem != nil)
    }
}
