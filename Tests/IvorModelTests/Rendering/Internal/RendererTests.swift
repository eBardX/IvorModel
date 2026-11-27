// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererTests {
}

// MARK: -

extension RendererTests {
    private typealias Moment = Renderer<BeatTime, Pitch>.Moment

    @Test
    func init_keysAttacksAndReleasesByPart() throws {
        let renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4),
                                                        WrittenNote(0, frac(1, 2), .e4)]),
                                         renderingPart([WrittenNote(0, 1, .c3)])])

        #expect(renderer.attacks[Moment(part: 0, time: 0)]?.count == 2)
        #expect(renderer.attacks[Moment(part: 1, time: 0)]?.count == 1)
        #expect(renderer.releases[Moment(part: 0, time: frac(1, 2))]?.count == 2)
        #expect(renderer.releases[Moment(part: 1, time: 1)]?.count == 1)
    }

    @Test
    func init_readsEveryNoteOfEveryPart() throws {
        let renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4),
                                                        WrittenNote(frac(1, 2), frac(1, 2), .d4)]),
                                         renderingPart([WrittenNote(0, 1, .c3)])])

        #expect(renderer.partCount == 2)
        #expect(renderer.sources.map(\.part) == [0, 0, 1])
        #expect(renderer.sources.map(\.startPitch) == [.c4, .d4, .c3])
        #expect(renderer.starts == [0, frac(1, 2), 0])
        #expect(renderer.ends == [frac(1, 2), 1, 1])
        #expect(renderer.beforeEvents.allSatisfy { $0.isEmpty })
        #expect(renderer.afterEvents.allSatisfy { $0.isEmpty })
        #expect(renderer.chordDelays.isEmpty)
    }

    @Test
    func init_resolvesEachPartsRules() throws {
        let renderer = try makeRenderer([renderingPart([WrittenNote(0, 1, .c4)],
                                                       rules: InterpretationRules(caesura: positiveSeconds(3))),
                                         renderingPart([WrittenNote(0, 1, .c3)])],
                                        rules: InterpretationRules(arpeggio: ArpeggioRules(direction: .down),
                                                                   caesura: positiveSeconds(1)))

        #expect(renderer.rules.map(\.caesura) == [positiveSeconds(3), positiveSeconds(1)])
        #expect(renderer.rules.map(\.arpeggio?.direction) == [.down, .down])
    }

    @Test
    func render_aFermataBecomesAMarkOverItsWrittenSpan() throws {
        let fermata = Fermata<BeatTime>(shape: .long)
        let output = try makeRenderer([renderingPart([WrittenNote(1, frac(1, 2), .c4, BeatNotes.Ornamentation(fermata: fermata))])]).render()
        let marks = try #require(output.fermataMarks.first)

        #expect(marks.map(\.time) == [1])
        #expect(marks.map(\.mark) == [.fermata(fermata, span: positiveBeats(1, 2))])
    }

    @Test
    func render_anEarlyStartIsTheLeadIn() throws {
        let part = try renderingPart([WrittenNote(0, frac(1, 2), .c4, BeatNotes.Ornamentation(graceBefore: graceFigure([.d4], isSlashed: true)))])
        let output = makeRenderer([part],
                                  rules: InterpretationRules(grace: GraceRules(slashedPlacement: .beforeBeat))).render()

        #expect(output.leadIn == frac(1, 64))
        #expect(plainNotes(output.notes[0][0]) == [RenderedNote(-frac(1, 64), frac(1, 64), .d4),
                                                   RenderedNote(0, frac(1, 2), .c4)])
    }

    @Test
    func render_plainNotesAreUnchanged() throws {
        let output = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4),
                                                      WrittenNote(frac(1, 2), frac(1, 2), .d4, endPitch: .e4)])]).render()

        #expect(output.leadIn == 0)
        #expect(output.fermataMarks.allSatisfy { $0.isEmpty })
        #expect(plainNotes(output.notes[0][0]) == [RenderedNote(0, frac(1, 2), .c4),
                                                   RenderedNote(frac(1, 2), frac(1, 2), .d4, .e4)])
    }
}
