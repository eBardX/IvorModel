// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererNoteTests {
}

// MARK: -

extension RendererNoteTests {
    @Test
    func init_storesEveryField() {
        let note = Renderer<BeatTime, Pitch>.Note(end: frac(1, 2),
                                                  endPitch: .e4,
                                                  extras: sampleExtras("x"),
                                                  start: -frac(1, 64),
                                                  startPitch: .c4)

        #expect(note.end == frac(1, 2))
        #expect(note.endPitch == .e4)
        #expect(note.extras == sampleExtras("x"))
        #expect(note.start == -frac(1, 64))
        #expect(note.startPitch == .c4)
    }
}
