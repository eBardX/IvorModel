// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkConvertPitchesTests {
}

// MARK: -

extension WorkConvertPitchesTests {
    @Test
    func convertPitches_anUnconvertibleGracePitchDropsOnlyItsFigure() throws {
        var table = BeatNotes()

        try table.insert(attack: 0,
                         duration: 1,
                         pitch: .c4,
                         ornamentation: .init(graceBefore: graceFigure([.d5]), fermata: Fermata()))

        let converted = try #require(Work.convertPitches(in: table,
                                                         using: { $0.map { $0 == .d5 ? nil : $0 } },
                                                         dropsUnconvertibleNotes: true))
        let note = try #require(converted.first)

        #expect(note.startPitch == .c4)
        #expect(note.ornamentation?.graceBefore == nil)
        #expect(note.ornamentation?.fermata == Fermata())
    }

    @Test
    func convertPitches_anUnconvertibleGracePitchFailsWithoutDropping() throws {
        var table = BeatNotes()

        try table.insert(attack: 0,
                         duration: 1,
                         pitch: .c4,
                         ornamentation: .init(graceBefore: graceFigure([.d5])))

        #expect(Work.convertPitches(in: table,
                                    using: { $0.map { $0 == .d5 ? nil : $0 } },
                                    dropsUnconvertibleNotes: false) == nil)
    }

    @Test
    func convertPitches_anUnconvertibleMainPitchDropsTheNote() throws {
        var table = BeatNotes()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        let converted = try #require(Work.convertPitches(in: table,
                                                         using: { $0.map { $0 == .c4 ? nil : $0 } },
                                                         dropsUnconvertibleNotes: true))

        #expect(converted.map(\.startPitch) == [.e4])
    }

    @Test
    func convertPitches_anUnconvertibleMainPitchFailsWithoutDropping() {
        var table = BeatNotes()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        #expect(Work.convertPitches(in: table,
                                    using: { $0.map { _ -> Pitch? in nil } },
                                    dropsUnconvertibleNotes: false) == nil)
    }

    @Test
    func convertPitches_aPartnerOnTheWrongSideAfterConversionIsDropped() throws {
        var table = BeatNotes()

        try table.insert(attack: 0, duration: 1, pitch: .c4, ornamentation: trillOrnamentation(written: .d4))

        //
        // The main note moves to E4, above its written partner D4.
        //
        let converted = try #require(Work.convertPitches(in: table,
                                                         using: { $0.map { $0 == .c4 ? .e4 : $0 } },
                                                         dropsUnconvertibleNotes: false))

        #expect(converted.first?.ornamentation?.ornament?.partner == .step(.above, written: nil))
    }

    @Test
    func convertPitches_convertsEverySlotAndKeepsTheRest() throws {
        var table = BeatNotes()

        try table.insert(attack: 0,
                         duration: 1,
                         pitch: .c4,
                         extras: sampleExtras("x"),
                         ornamentation: .init(graceBefore: graceFigure([.g4]),
                                              graceAfter: graceFigure([.c4]),
                                              ornament: ornament(.tremolo(.unmeasured), .pitches([.g4])),
                                              arpeggio: BeatNotes.Arpeggio(group: 1)))

        let converted = try #require(Work.convertPitches(in: table,
                                                         using: { $0.map(swapCAndG) },
                                                         dropsUnconvertibleNotes: false))
        let note = try #require(converted.first)

        #expect(note.startPitch == .g4)
        #expect(note.extras == sampleExtras("x"))
        #expect(note.ornamentation?.graceBefore?.pitches == [.c4])
        #expect(note.ornamentation?.graceAfter?.pitches == [.g4])
        #expect(note.ornamentation?.ornament?.partner == .pitches([.c4]))
        #expect(note.ornamentation?.arpeggio == BeatNotes.Arpeggio(group: 1))
    }

    @Test
    func convertPitches_emptyTable() throws {
        let converted = try #require(Work.convertPitches(in: BeatNotes(),
                                                         using: { $0 },
                                                         dropsUnconvertibleNotes: false))

        #expect(converted.isEmpty)
    }

    @Test
    func convertPitches_passesPitchesInPerformanceOrder() throws {
        var table = BeatNotes()
        var passed: [Pitch] = []

        table.insert(attack: 1, duration: 1, startPitch: .e4, endPitch: .f4)
        try table.insert(attack: 0,
                         duration: 1,
                         pitch: .g4,
                         ornamentation: .init(graceBefore: graceFigure([.d5]),
                                              graceAfter: graceFigure([.a4]),
                                              ornament: ornament(.trill, .step(.above, written: .b4))))
        table.insert(attack: 0, duration: 1, pitch: .c4)

        _ = Work.convertPitches(in: table,
                                using: { pitches in passed = pitches; return pitches },
                                dropsUnconvertibleNotes: false)

        #expect(passed == [.c4, .d5, .g4, .b4, .a4, .e4, .f4])
    }
}
