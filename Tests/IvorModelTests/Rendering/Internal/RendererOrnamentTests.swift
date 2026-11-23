// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererOrnamentTests {
}

// MARK: -

extension RendererOrnamentTests {
    @Test
    func pieces_aMordentSoundsItsPartnerOnce() throws {
        let mordent = try ornament(.mordent, .step(.above, written: nil), BeatNotes.OrnamentExecution(rate: .noteValue(positiveBeats(1, 32))))
        let renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 4), .c4, BeatNotes.Ornamentation(ornament: mordent))])])
        let pieces = renderer.pieces(of: 0, from: 0, to: frac(1, 4))

        #expect(pieces.map(\.partner) == [nil, [.d4], nil])
        #expect(pieces.map(\.start) == [0, frac(1, 32), frac(1, 16)])
        #expect(pieces.last?.end == frac(1, 4))
    }

    @Test
    func pieces_aTrillFillsTheSpanWithAnOddCount() throws {
        let ornamentation = try BeatNotes.Ornamentation(ornament: ornament(.trill, .step(.above, written: nil)))
        let renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(5, 16), .c4, ornamentation)])])
        let pieces = renderer.pieces(of: 0, from: 0, to: frac(5, 16))

        //
        // 1.25 seconds at 12 per second is 15 notes, starting and ending on C.
        //
        #expect(pieces.count == 15)
        #expect(pieces.first?.partner == nil)
        #expect(pieces.last?.partner == nil)
        #expect(pieces[1].partner == [.d4])
    }

    @Test
    func pieces_aWrittenPartnerIsUsed() throws {
        let trill = try ornament(.trill, .step(.above, written: "D♭4"), BeatNotes.OrnamentExecution(rate: .noteValue(positiveBeats(1, 12))))
        let renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 4), .c4, BeatNotes.Ornamentation(ornament: trill))])])

        #expect(renderer.pieces(of: 0, from: 0, to: frac(1, 4)).map(\.partner) == [nil, ["D♭4"], nil])
    }

    @Test
    func pieces_theStepFollowsTheKey() throws {
        let trill = try ornament(.trill, .step(.above, written: nil), BeatNotes.OrnamentExecution(rate: .noteValue(positiveBeats(1, 12))))
        let renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 4), .e4, BeatNotes.Ornamentation(ornament: trill))])],
                                        keyTable: makeKeyTable([(0, -1)]))

        #expect(renderer.pieces(of: 0, from: 0, to: frac(1, 4)).map(\.partner) == [nil, [.f4], nil])
    }

    @Test
    func pieces_withoutAnOrnamentIsOnePiece() throws {
        let renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4)])])
        let pieces = renderer.pieces(of: 0, from: frac(1, 8), to: frac(1, 2))

        #expect(pieces.map(\.start) == [frac(1, 8)])
        #expect(pieces.map(\.end) == [frac(1, 2)])
        #expect(pieces.map(\.partner) == [nil])
    }
}
