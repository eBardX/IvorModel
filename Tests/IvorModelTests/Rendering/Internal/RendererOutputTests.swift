// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererOutputTests {
}

// MARK: -

extension RendererOutputTests {
    @Test
    func init_storesEveryField() {
        let note = Renderer<BeatTime, Pitch>.Note(end: 1, endPitch: .c4, extras: nil, start: 0, startPitch: .c4)
        let output = Renderer<BeatTime, Pitch>.Output(fermataMarks: [[(time: 0, mark: quarterFermataMark(4))], []],
                                                      leadIn: frac(1, 64),
                                                      notes: [[note], []])

        #expect(output.fermataMarks.map(\.count) == [1, 0])
        #expect(output.fermataMarks[0].first?.mark == quarterFermataMark(4))
        #expect(output.leadIn == frac(1, 64))
        #expect(output.notes.map(\.count) == [1, 0])
    }
}
