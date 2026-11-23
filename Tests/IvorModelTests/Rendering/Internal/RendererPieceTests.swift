// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererPieceTests {
}

// MARK: -

extension RendererPieceTests {
    @Test
    func bounds_areMutable() {
        var piece = Renderer<BeatTime, Pitch>.Piece(end: frac(1, 2),
                                                    partner: nil,
                                                    start: frac(1, 4))

        piece.start = 0
        piece.end = 1

        #expect(piece.end == 1)
        #expect(piece.start == 0)
    }

    @Test
    func init_mainNotePiece() {
        let piece = Renderer<BeatTime, Pitch>.Piece(end: frac(1, 2),
                                                    partner: nil,
                                                    start: 0)

        #expect(piece.end == frac(1, 2))
        #expect(piece.partner == nil)
        #expect(piece.start == 0)
    }

    @Test
    func init_partnerPiece() {
        let piece = Renderer<BeatTime, Pitch>.Piece(end: frac(1, 16),
                                                    partner: [.d4],
                                                    start: frac(1, 32))

        #expect(piece.partner == [.d4])
    }
}
