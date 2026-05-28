// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
import Testing

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

        #expect(cc.keyboardMap == nil)
        #expect(cc.pitchSpeller == nil)
        #expect(cc.pitchStandard != nil)
        #expect(cc.tuningSystem != nil)
    }

    @Test
    func `default`() {
        let cc = Work.ConvertContext.default

        #expect(cc.keyboardMap != nil)
        #expect(cc.pitchSpeller != nil)
        #expect(cc.pitchStandard != nil)
        #expect(cc.tuningSystem != nil)
    }

    @Test
    func `init`() {
        let cc = Work.ConvertContext()

        #expect(cc.keyboardMap == nil)
        #expect(cc.pitchSpeller == nil)
        #expect(cc.pitchStandard == nil)
        #expect(cc.tuningSystem == nil)
    }

    @Test
    func keyboardMap() throws {
        let expectedKeyboardMap = try #require(Work.ConvertContext.default.keyboardMap)

        let cc = Work.ConvertContext().keyboardMap(expectedKeyboardMap)

        #expect(cc.keyboardMap != nil)
        #expect(cc.pitchSpeller == nil)
        #expect(cc.pitchStandard == nil)
        #expect(cc.tuningSystem == nil)
    }

    @Test
    func pitchSpeller() {
        let expectedPitchSpeller = MeredithPitchSpeller()

        let cc = Work.ConvertContext().pitchSpeller(expectedPitchSpeller)

        #expect(cc.keyboardMap == nil)
        #expect(cc.pitchSpeller != nil)
        #expect(cc.pitchStandard == nil)
        #expect(cc.tuningSystem == nil)
    }

    @Test
    func pitchStandard() {
        let expectedPitchStandard: PitchStandard = .a440

        let cc = Work.ConvertContext().pitchStandard(expectedPitchStandard)

        #expect(cc.keyboardMap == nil)
        #expect(cc.pitchSpeller == nil)
        #expect(cc.pitchStandard != nil)
        #expect(cc.tuningSystem == nil)
    }

    @Test
    func tuningSystem() {
        let expectedTuningSystem = EqualTemperament.edo12

        let cc = Work.ConvertContext().tuningSystem(expectedTuningSystem)

        #expect(cc.keyboardMap == nil)
        #expect(cc.pitchSpeller == nil)
        #expect(cc.pitchStandard == nil)
        #expect(cc.tuningSystem != nil)
    }
}
