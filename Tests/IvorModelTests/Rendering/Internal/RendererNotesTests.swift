// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererNotesTests {
}

// MARK: -

extension RendererNotesTests {
    @Test
    func renderedNotes_aFigureTiedIntoTheMainNoteLendsItsSpan() throws {
        let ornamentation = try BeatNotes.Ornamentation(graceBefore: graceFigure([.d4, .c4], isTiedToMainNote: true))
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4, ornamentation)])])

        renderer.planGraceFiguresBefore()
        renderer.applyChordDelays()

        #expect(plainNotes(renderer.renderedNotes(of: 0)) == [RenderedNote(0, frac(1, 64), .d4),
                                                              RenderedNote(frac(1, 64), frac(31, 64), .c4)])
    }

    @Test
    func renderedNotes_aMainNoteWithNoSpanSoundsOnlyItsGraceNotes() throws {
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4, BeatNotes.Ornamentation(graceBefore: graceFigure([.d4])))])])

        renderer.planGraceFiguresBefore()
        renderer.starts[0] = renderer.ends[0]

        #expect(plainNotes(renderer.renderedNotes(of: 0)) == [RenderedNote(0, frac(1, 4), .d4)])
    }

    @Test
    func renderedNotes_graceNotesFollowTheirPlan() throws {
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4, BeatNotes.Ornamentation(graceBefore: graceFigure([.d4])))])])

        renderer.planGraceFiguresBefore()
        renderer.applyChordDelays()

        #expect(plainNotes(renderer.renderedNotes(of: 0)) == [RenderedNote(0, frac(1, 4), .d4),
                                                              RenderedNote(frac(1, 4), frac(1, 4), .c4)])
    }

    @Test
    func renderedNotes_onePieceKeepsEveryExtra() throws {
        let extras = Extras(elements: [Extra.slurStart, Extra.slurEnd])
        let renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 4), .c4, extras: extras)])])

        #expect(renderer.renderedNotes(of: 0).map(\.extras) == [extras])
    }

    @Test
    func renderedNotes_piecesShareTheExtras() throws {
        let extras = Extras(elements: [Extra.slurStart, Extra.slurEnd, Extra.staccato, Extra(name: Extra.attackVelocity.name, values: [.int(90)])])
        let mordent = try ornament(.mordent, .step(.above, written: nil), BeatNotes.OrnamentExecution(rate: .noteValue(positiveBeats(1, 32))))
        let renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 4), .c4, extras: extras, .init(ornament: mordent))])])
        let names = renderer.renderedNotes(of: 0).map { Set($0.extras?.elements.map(\.name.stringValue) ?? []) }

        #expect(names == [["slurStart", "staccato", "attackVelocity"],
                          ["attackVelocity", "ornamentNote"],
                          ["slurEnd", "attackVelocity", "ornamentNote"]])
    }

    @Test
    func renderedNotes_theLastMainPieceGlides() throws {
        let trill = try ornament(.trill, .step(.above, written: nil), BeatNotes.OrnamentExecution(rate: .noteValue(positiveBeats(1, 12))))
        let renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 4), .c4, endPitch: .e4, BeatNotes.Ornamentation(ornament: trill))])])

        #expect(plainNotes(renderer.renderedNotes(of: 0)) == [RenderedNote(0, frac(1, 12), .c4),
                                                              RenderedNote(frac(1, 12), frac(1, 12), .d4),
                                                              RenderedNote(frac(1, 6), frac(1, 12), .c4, .e4)])
    }
}
