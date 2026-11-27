// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererSourceTests {
}

// MARK: -

extension RendererSourceTests {
    @Test
    func duration_isReleaseMinusAttack() {
        let source = Renderer<BeatTime, Pitch>.Source(attack: frac(1, 4),
                                                      endPitch: .c4,
                                                      extras: nil,
                                                      ornamentation: nil,
                                                      part: 0,
                                                      release: frac(3, 4),
                                                      startPitch: .c4,
                                                      strand: 0)

        #expect(source.duration == frac(1, 2))
    }

    @Test
    func init_storesEveryField() throws {
        let ornamentation = try trillOrnamentation(written: .d4)
        let source = Renderer<BeatTime, Pitch>.Source(attack: 1,
                                                      endPitch: .e4,
                                                      extras: sampleExtras("x"),
                                                      ornamentation: ornamentation,
                                                      part: 2,
                                                      release: 2,
                                                      startPitch: .c4,
                                                      strand: 1)

        #expect(source.attack == 1)
        #expect(source.endPitch == .e4)
        #expect(source.extras == sampleExtras("x"))
        #expect(source.ornamentation == ornamentation)
        #expect(source.part == 2)
        #expect(source.release == 2)
        #expect(source.startPitch == .c4)
        #expect(source.strand == 1)
    }
}
