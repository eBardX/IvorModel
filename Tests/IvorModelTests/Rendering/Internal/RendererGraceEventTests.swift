// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererGraceEventTests {
}

// MARK: -

extension RendererGraceEventTests {
    @Test
    func init_storesEveryField() {
        let event = Renderer<BeatTime, Pitch>.GraceEvent(end: frac(1, 64),
                                                         pitches: [.d4, .f4],
                                                         start: 0)

        #expect(event.end == frac(1, 64))
        #expect(event.pitches == [.d4, .f4])
        #expect(event.start == 0)
    }

    @Test
    func pitches_areMutable() {
        var event = Renderer<BeatTime, Pitch>.GraceEvent(end: frac(1, 64),
                                                         pitches: [.c4, .d4],
                                                         start: 0)

        event.pitches.removeFirst()

        #expect(event.pitches == [.d4])
    }
}
