// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererArpeggioTests {
}

// MARK: -

extension RendererArpeggioTests {
    @Test
    func rollArpeggios_downFirstOnBeat() throws {
        var renderer = try makeRenderer([renderingPart([.c4, .e4, .g4].map { WrittenNote(0, frac(1, 4), $0, rollOrnamentation(direction: .down)) })])

        renderer.rollArpeggios()

        let starts = Dictionary(uniqueKeysWithValues: zip(renderer.sources.map(\.startPitch), renderer.starts))

        #expect(starts == [.c4: frac(1, 16), .e4: frac(1, 32), .g4: 0])
        #expect(renderer.ends == [frac(1, 4), frac(1, 4), frac(1, 4)])
    }

    @Test
    func rollArpeggios_lastOnBeatEndsTheNoteBeforeWhereTheRollBegins() throws {
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c3)] +
                [.c4, .e4, .g4].map { WrittenNote(frac(1, 2), frac(1, 4), $0, rollOrnamentation(anchor: .lastOnBeat)) })])

        renderer.rollArpeggios()

        let starts = Dictionary(uniqueKeysWithValues: zip(renderer.sources.map(\.startPitch), renderer.starts))
        let ends = Dictionary(uniqueKeysWithValues: zip(renderer.sources.map(\.startPitch), renderer.ends))

        #expect(ends[.c3] == frac(7, 16))
        #expect(starts == [.c3: 0, .c4: frac(7, 16), .e4: frac(15, 32), .g4: frac(1, 2)])
    }

    @Test
    func rollArpeggios_doesNotRollAcrossParts() throws {
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 4), .c4, rollOrnamentation())]),
                                         renderingPart([WrittenNote(0, frac(1, 4), .e4, rollOrnamentation())])])

        renderer.rollArpeggios()

        #expect(renderer.starts == [0, 0])
    }

    @Test
    func rollArpeggios_rollsAcrossStrands() throws {
        var renderer = try makeRenderer([renderingStrandedPart([[WrittenNote(0, frac(1, 4), .c4, rollOrnamentation())],
                                                                [WrittenNote(0, frac(1, 4), .e4, rollOrnamentation())]])])

        renderer.rollArpeggios()

        #expect(renderer.starts == [0, frac(1, 32)])
    }

    @Test
    func rollArpeggios_withoutArpeggiosChangesNothing() throws {
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 4), .c4),
                                                        WrittenNote(0, frac(1, 4), .e4)])])

        renderer.rollArpeggios()

        #expect(renderer.starts == [0, 0])
    }
}
