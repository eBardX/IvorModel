// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableConvertOrnamentationTests {
}

// MARK: -

extension NoteTableConvertOrnamentationTests {
    @Test
    func fittingPartner_nil() {
        #expect(BeatNotes.fittingPartner(nil, startPitch: .c4) == nil)
    }

    @Test
    func fittingPartner_partnerOnTheRightSideIsKept() throws {
        let ornamentation = try trillOrnamentation(written: .d4)

        #expect(BeatNotes.fittingPartner(ornamentation, startPitch: .c4) == ornamentation)
    }

    @Test
    func fittingPartner_partnerOnTheWrongSideIsDropped() throws {
        let ornamentation = try BeatNotes.Ornamentation(graceBefore: graceFigure([.g4]),
                                                        ornament: ornament(.trill, .step(.above, written: .d4)),
                                                        fermata: Fermata())
        let fitted = try #require(BeatNotes.fittingPartner(ornamentation, startPitch: .e4))

        #expect(fitted.ornament?.partner == .step(.above, written: nil))
        #expect(fitted.graceBefore == ornamentation.graceBefore)
        #expect(fitted.fermata == ornamentation.fermata)
    }

    @Test
    func fittingPartner_withoutAnOrnamentIsUnchanged() throws {
        let ornamentation = try BeatNotes.Ornamentation(graceBefore: graceFigure([.g4]))

        #expect(BeatNotes.fittingPartner(ornamentation, startPitch: .c4) == ornamentation)
    }

    @Test
    func measuredTremoloRate_doublesWithEachStroke() throws {
        let tempoMap = TempoMap(defaultTempo: Tempo(60))

        //
        // At ♩ = 60 a sixteenth (two strokes) lasts a quarter of a second.
        //
        #expect(try BeatNotes.measuredTremoloRate(#require(TremoloStrokes(uintValue: 1)), at: 0, using: tempoMap) == notesPerSecond(2))
        #expect(try BeatNotes.measuredTremoloRate(#require(TremoloStrokes(uintValue: 2)), at: 0, using: tempoMap) == notesPerSecond(4))
    }

    @Test
    func measuredTremoloRate_followsTheTempo() throws {
        let strokes = try #require(TremoloStrokes(uintValue: 2))

        #expect(BeatNotes.measuredTremoloRate(strokes, at: 0, using: TempoMap(defaultTempo: Tempo(60))) == notesPerSecond(4))
        #expect(BeatNotes.measuredTremoloRate(strokes, at: 0, using: TempoMap(defaultTempo: Tempo(120))) == notesPerSecond(8))
    }

    @Test
    func retimed_aSlotThatCantConvertIsDropped() throws {
        let ornamentation = try BeatNotes.Ornamentation(graceBefore: graceFigure([.d4], length: positiveBeats(1, 16)),
                                                        graceAfter: graceFigure([.e4]))
        let retimed = try #require(BeatNotes.retimed(ornamentation, at: 0) { _ in beatTime(1) })

        #expect(retimed.graceBefore == nil)
        #expect(retimed.graceAfter?.pitches == [.e4])
    }

    @Test
    func retimed_convertsLengthsAtTheAttack() throws {
        let ornamentation = try BeatNotes.Ornamentation(graceBefore: graceFigure([.d4], length: positiveBeats(1)),
                                                        fermata: Fermata(execution: FermataExecution(hold: .added(positiveBeats(1)))))

        //
        // Squaring times: a whole note from 1 ends at 2, spanning 4 − 1 = 3.
        //
        let retimed = try #require(BeatNotes.retimed(ornamentation, at: 1) { beatTime($0.numberValue * $0.numberValue) })

        #expect(retimed.graceBefore?.events.first?.length == positiveBeats(3))
        #expect(retimed.fermata?.execution?.hold == .added(positiveBeats(3)))
    }

    @Test
    func retimed_eachSlotTakesItsOwnPitchMapping() throws {
        let ornamentation = try BeatNotes.Ornamentation(graceBefore: graceFigure([.c4]),
                                                        graceAfter: graceFigure([.c4]),
                                                        ornament: ornament(.trill, .step(.above, written: .c4)))
        let retimed = try #require(BeatNotes.retimed(ornamentation,
                                                     at: 0,
                                                     times: { $0 },
                                                     pitchBefore: { _ in .d4 },
                                                     pitch: { _ in .e4 },
                                                     pitchAfter: { _ in .f4 }))

        #expect(retimed.graceBefore?.pitches == [.d4])
        #expect(retimed.ornament?.partner == .step(.above, written: .e4))
        #expect(retimed.graceAfter?.pitches == [.f4])
    }

    @Test
    func retimed_nil() {
        #expect(BeatNotes.retimed(nil, at: 0) { $0 } == nil)
    }

    @Test
    func retimed_tremoloRateAddsARateToAMeasuredTremolo() throws {
        let strokes = try #require(TremoloStrokes(uintValue: 2))
        let ornamentation = try BeatNotes.Ornamentation(ornament: ornament(.tremolo(.measured(strokes)), .repeat))
        let retimed = try #require(BeatNotes.retimed(ornamentation,
                                                     at: 0,
                                                     times: { $0 },
                                                     tremoloRate: { _ in notesPerSecond(6) }))

        #expect(retimed.ornament?.execution?.rate == .perSecond(notesPerSecond(6)))
        #expect(retimed.ornament?.sign == .tremolo(.measured(strokes)))
    }

    @Test
    func retimed_tremoloRateKeepsAnExistingRate() throws {
        let strokes = try #require(TremoloStrokes(uintValue: 2))
        let ornamentation = try BeatNotes.Ornamentation(ornament: ornament(.tremolo(.measured(strokes)),
                                                                           .repeat,
                                                                           BeatNotes.OrnamentExecution(rate: .perSecond(notesPerSecond(10)))))
        let retimed = try #require(BeatNotes.retimed(ornamentation,
                                                     at: 0,
                                                     times: { $0 },
                                                     tremoloRate: { _ in notesPerSecond(6) }))

        #expect(retimed.ornament?.execution?.rate == .perSecond(notesPerSecond(10)))
    }

    @Test
    func retimed_tremoloRateLeavesOtherOrnamentsAlone() throws {
        let ornamentation = try trillOrnamentation(written: .d4)
        let retimed = try #require(BeatNotes.retimed(ornamentation,
                                                     at: 0,
                                                     times: { $0 },
                                                     tremoloRate: { _ in notesPerSecond(6) }))

        #expect(retimed.ornament == ornamentation.ornament)
    }
}
