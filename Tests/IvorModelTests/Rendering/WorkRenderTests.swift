// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

// swiftlint:disable file_length

// Rendering, worked out by hand at ♩ = 60 (a half note lasts 2 seconds): grace figures,
// trills, mordents and tremolos, rolled chords, fermata holds and caesura pauses, and lead-ins.
// Times are in whole notes.
struct WorkRenderTests {
}

// MARK: -

extension WorkRenderTests {
    private typealias Execution = BeatNotes.GraceExecution
    private typealias Ornamentation = BeatNotes.Ornamentation
    private typealias OrnamentExecution = BeatNotes.OrnamentExecution

    @Test
    func arpeggio_defaultSpreadIsCappedAtSixtyMilliseconds() throws {
        let notes = try render([.c4, .e4, .g4].map { WrittenNote(0, frac(1, 4), $0, Ornamentation(arpeggio: BeatNotes.Arpeggio(group: 1))) })

        //
        // A quarter over three tones would be a twelfth each; 60 ms at ♩ = 60 is 3/200 of a
        // whole note, which is less (through rounded seconds, so compare closely).
        //
        #expect(notes.map(\.pitch) == [.c4, .e4, .g4])
        #expect(abs(notes[1].start.doubleValue - 0.015) < 1e-6)
        #expect(abs(notes[2].start.doubleValue - 0.03) < 1e-6)
        #expect(notes.allSatisfy { $0.start + $0.length == frac(1, 4) })
    }

    @Test
    func arpeggio_disagreeingGroupFollowsItsFirstTone() throws {
        let first = try renderingPart([WrittenNote(0, frac(1, 4), .c4, rollOrnamentation(direction: .down))])
        let second = try renderingPart([WrittenNote(0, frac(1, 4), .e4, rollOrnamentation(direction: .up)),
                                        WrittenNote(0, frac(1, 4), .g4, rollOrnamentation(direction: .up))])
        let parts = try renderedNotes(renderingWork([first, second]).rendered())

        //
        // The first tone (part 1) says down: G4, E4, then C4.
        //
        #expect(parts[0] == [RenderedNote(frac(1, 16), frac(3, 16), .c4)])
        #expect(parts[1] == [RenderedNote(0, frac(1, 4), .g4),
                             RenderedNote(frac(1, 32), frac(7, 32), .e4)])
    }

    @Test
    func arpeggio_downFirstOnBeat() throws {
        let notes = try render([.c4, .e4, .g4].map { WrittenNote(0, frac(1, 4), $0, rollOrnamentation(direction: .down)) })

        #expect(notes == [RenderedNote(0, frac(1, 4), .g4),
                          RenderedNote(frac(1, 32), frac(7, 32), .e4),
                          RenderedNote(frac(1, 16), frac(3, 16), .c4)])
    }

    @Test
    func arpeggio_graceFigureBeforeARolledChord() throws {
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, Ornamentation(graceBefore: graceFigure([.d5], isSlashed: true),
                                                                              arpeggio: rollOrnamentation().arpeggio)),
                                WrittenNote(0, frac(1, 4), .e4, rollOrnamentation())])

        //
        // The whole chord waits a sixty-fourth for the grace note, then rolls.
        //
        #expect(notes == [RenderedNote(0, frac(1, 64), .d5),
                          RenderedNote(frac(1, 64), frac(15, 64), .c4),
                          RenderedNote(frac(3, 64), frac(13, 64), .e4)])
    }

    @Test
    func arpeggio_lastOnBeatEndsTheNoteBeforeWhereTheRollBegins() throws {
        let notes = try render([WrittenNote(0, frac(1, 2), .c3)] +
            [.c4, .e4, .g4].map { WrittenNote(frac(1, 2), frac(1, 4), $0, rollOrnamentation(anchor: .lastOnBeat)) })

        #expect(notes == [RenderedNote(0, frac(7, 16), .c3),
                          RenderedNote(frac(7, 16), frac(5, 16), .c4),
                          RenderedNote(frac(15, 32), frac(9, 32), .e4),
                          RenderedNote(frac(1, 2), frac(1, 4), .g4)])
    }

    @Test
    func arpeggio_rollAcrossTwoParts() throws {
        let upper = try renderingPart([WrittenNote(0, frac(1, 4), .c5, rollOrnamentation())])
        let lower = try renderingPart([WrittenNote(0, frac(1, 4), .c4, rollOrnamentation()), WrittenNote(0, frac(1, 4), .e4, rollOrnamentation())])
        let parts = try renderedNotes(renderingWork([upper, lower]).rendered())

        #expect(parts[0] == [RenderedNote(frac(1, 16), frac(3, 16), .c5)])
        #expect(parts[1] == [RenderedNote(0, frac(1, 4), .c4),
                             RenderedNote(frac(1, 32), frac(7, 32), .e4)])
    }

    @Test
    func arpeggio_rulesSetATotalSpread() throws {
        let rules = InterpretationRules(arpeggio: ArpeggioRules(spread: .total(proportion(1, 2))))
        let notes = try render([.c4, .e4, .g4].map { WrittenNote(0, frac(1, 4), $0, Ornamentation(arpeggio: BeatNotes.Arpeggio(group: 1))) },
                               rules: rules)

        //
        // Half of a quarter, over two gaps: a sixteenth each.
        //
        #expect(notes.map(\.start) == [0, frac(1, 16), frac(1, 8)])
    }

    @Test
    func arpeggio_twoGroupsAtOneAttackRollApart() throws {
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, rollOrnamentation(group: 1)),
                                WrittenNote(0, frac(1, 4), .e4, rollOrnamentation(group: 1)),
                                WrittenNote(0, frac(1, 4), .g4, rollOrnamentation(group: 2)),
                                WrittenNote(0, frac(1, 4), .b4, rollOrnamentation(group: 2))])

        #expect(notes == [RenderedNote(0, frac(1, 4), .c4),
                          RenderedNote(0, frac(1, 4), .g4),
                          RenderedNote(frac(1, 32), frac(7, 32), .e4),
                          RenderedNote(frac(1, 32), frac(7, 32), .b4)])
    }

    @Test
    func caesura_stretchedNotesInsertsTwoSeconds() throws {
        var part = try twoNotePart()

        part.markTable.insert(time: beatTime(frac(1, 2)), mark: .caesura(nil))

        let notes = try #require(renderedNotes(renderingWork([part]).rendered(options: RenderingOptions(fermataMode: .stretchedNotes))).first)

        //
        // Two seconds is a half note: the C4 ends at the caesura; the D4 starts after it.
        //
        #expect(notes == [RenderedNote(0, frac(1, 2), .c4),
                          RenderedNote(1, frac(1, 2), .d4)])
    }

    @Test
    func caesura_tempoChangesDipsFromTheLatestAttack() throws {
        var part = try twoNotePart()

        part.markTable.insert(time: beatTime(frac(1, 2)), mark: .caesura(nil))

        let rendering = try renderingWork([part]).rendered()

        //
        // From the C4's attack to the caesura, 2 seconds become 4.
        //
        #expect(try renderedNotes(rendering).first == [RenderedNote(0, frac(1, 2), .c4), RenderedNote(frac(1, 2), frac(1, 2), .d4)])
        #expect(try renderedWallSeconds(rendering, at: frac(1, 2)) == 4)
        #expect(try renderedWallSeconds(rendering, at: 1) == 6)
    }

    @Test
    func extras_areSharedAmongThePieces() throws {
        let extras = Extras(elements: [Extra.slurStart, Extra.slurEnd, Extra.staccato, Extra(name: Extra.attackVelocity.name, values: [.int(90)])])
        let mordent = try ornament(.mordent, .step(.above, written: nil), OrnamentExecution(rate: .noteValue(positiveBeats(1, 32))))
        let work = try renderingWork([renderingPart([WrittenNote(0, frac(1, 4), .c4, extras: extras, Ornamentation(ornament: mordent))])])

        guard case let .standardBeat(parts, _, _, _) = try work.rendered().work.content.cases
        else { Issue.record("Expected standard beat content"); return }

        let names = try #require(parts.first).noteTable.map { Set($0.extras?.elements.map(\.name.stringValue) ?? []) }

        #expect(names == [["slurStart", "staccato", "attackVelocity"],
                          ["attackVelocity", "ornamentNote"],
                          ["slurEnd", "attackVelocity"]])
    }

    @Test
    func fermata_explicitHoldAndPauseAfter() throws {
        let execution = FermataExecution<BeatTime>(hold: .seconds(positiveSeconds(1)), pauseAfter: .seconds(positiveSeconds(1)))
        let options = RenderingOptions(fermataMode: .stretchedNotes)

        let notes = try #require(renderedNotes(renderingWork([twoNotePart(Fermata(execution: execution))]).rendered(options: options)).first)

        //
        // A second longer (a quarter), then a second of silence (another quarter).
        //
        #expect(notes == [RenderedNote(0, frac(3, 4), .c4),
                          RenderedNote(1, frac(1, 2), .d4)])
    }

    @Test
    func fermata_inAWorkWithALeadIn() throws {
        let ornamentation = try Ornamentation(graceBefore: graceFigure([.e4], isSlashed: true), fermata: Fermata())
        let part = try renderingPart([WrittenNote(0, frac(1, 2), .c4, ornamentation),
                                      WrittenNote(frac(1, 2), frac(1, 2), .d4)])
        let rendering = try renderingWork([part], rules: InterpretationRules(grace: GraceRules(slashedPlacement: .beforeBeat)))
            .rendered(options: RenderingOptions(fermataMode: .stretchedNotes))

        //
        // The hold starts on the C4, a sixty-fourth in, and doubles its half note.
        //
        #expect(rendering.leadIn == .beat(beats(frac(1, 64))))
        #expect(rendering.fermataTimes == [.beat(beatTime(frac(1, 64)))])
        #expect(try renderedNotes(rendering).first == [RenderedNote(0, frac(1, 64), .e4),
                                                       RenderedNote(frac(1, 64), 1, .c4),
                                                       RenderedNote(frac(65, 64), frac(1, 2), .d4)])
    }

    @Test
    func fermata_notPlayedHoldsNothingButIsReported() throws {
        let options = RenderingOptions(fermataMode: .stretchedNotes)

        let rendering = try renderingWork([twoNotePart(Fermata(execution: FermataExecution(isPlayed: false)))]).rendered(options: options)

        #expect(try renderedNotes(rendering).first == [RenderedNote(0, frac(1, 2), .c4), RenderedNote(frac(1, 2), frac(1, 2), .d4)])
        #expect(rendering.fermataTimes == [.beat(0)])
    }

    @Test
    func fermata_notRealizedChangesNoTimes() throws {
        let rendering = try renderingWork([twoNotePart(Fermata())]).rendered(options: RenderingOptions(fermataMode: .notRealized))

        #expect(try renderedNotes(rendering).first == [RenderedNote(0, frac(1, 2), .c4), RenderedNote(frac(1, 2), frac(1, 2), .d4)])
        #expect(try renderedWallSeconds(rendering, at: 1) == 4)
    }

    @Test
    func fermata_notRealizedIsConsumedButReported() throws {
        let fermata = Fermata<BeatTime>(shape: .long)
        let work = try renderingWork([renderingPart([WrittenNote(0,
                                                                 frac(1, 2),
                                                                 .c4,
                                                                 Ornamentation(graceBefore: graceFigure([.d4]), fermata: fermata))])])
        let rendering = try work.rendered(options: RenderingOptions(fermataMode: .notRealized))

        guard case let .standardBeat(parts, _, _, _) = rendering.work.content.cases
        else { Issue.record("Expected standard beat content"); return }

        let part = try #require(parts.first)

        #expect(part.markTable.isEmpty)
        #expect(!part.noteTable.hasOrnamentation)
        #expect(rendering.fermataTimes == [.beat(0)])
        #expect(try renderedNotes(rendering).first == [RenderedNote(0, frac(1, 4), .d4),
                                                       RenderedNote(frac(1, 4), frac(1, 4), .c4)])
    }

    @Test
    func fermata_rulesSetTheHoldForAShape() throws {
        let rules = InterpretationRules(fermata: FermataRules(holds: [.normal: .stretch(FermataStretch(numberValue: 3).unsafelyUnwrapped)]))
        let options = RenderingOptions(fermataMode: .stretchedNotes)

        let notes = try #require(renderedNotes(renderingWork([twoNotePart(Fermata())], rules: rules).rendered(options: options)).first)

        #expect(notes == [RenderedNote(0, frac(3, 2), .c4),
                          RenderedNote(frac(3, 2), frac(1, 2), .d4)])
    }

    @Test
    func fermata_stretchedNotesMovesEverythingLater() throws {
        var part = try twoNotePart(Fermata())

        part.dynamicMap.insert(time: beatTime(frac(1, 2)), dynamic: .ff)

        var meterTable = MeterTable()

        try meterTable.insert(beatTime: 0, meter: #require(Meter(plain: "2/4")))
        try meterTable.insert(beatTime: beatTime(frac(1, 2)), meter: #require(Meter(plain: "3/4")))

        let rendering = try renderingWork([part], meterTable: meterTable).rendered(options: RenderingOptions(fermataMode: .stretchedNotes))

        guard case let .standardBeat(parts, tempoMap, newMeterTable, _) = rendering.work.content.cases
        else { Issue.record("Expected standard beat content"); return }

        //
        // The normal fermata doubles the C4's half note; everything after moves a half later.
        //
        #expect(try renderedNotes(rendering).first == [RenderedNote(0, 1, .c4), RenderedNote(1, frac(1, 2), .d4)])
        #expect(parts.first?.dynamicMap.map(\.time) == [1])
        #expect(newMeterTable.map(\.beatTime) == [0, 1])
        #expect(tempoMap.isEmpty)
        #expect(parts.first?.markTable.isEmpty ?? false)
    }

    @Test
    func fermata_tempoChangesSlowsTheSpan() throws {
        let rendering = try renderingWork([twoNotePart(Fermata())]).rendered()

        guard case let .standardBeat(_, tempoMap, _, _) = rendering.work.content.cases
        else { Issue.record("Expected standard beat content"); return }

        //
        // The notes keep their beats; the half note under the fermata takes 4 seconds.
        //
        #expect(try renderedNotes(rendering).first == [RenderedNote(0, frac(1, 2), .c4), RenderedNote(frac(1, 2), frac(1, 2), .d4)])
        #expect(tempoMap.map(\.tempo) == [Tempo(60), Tempo(30), Tempo(30), Tempo(60)])
        #expect(try renderedWallSeconds(rendering, at: frac(1, 2)) == 4)
        #expect(try renderedWallSeconds(rendering, at: 1) == 6)
    }

    @Test
    func glide_theLastMainPieceGlides() throws {
        let trill = try ornament(.trill, .step(.above, written: nil), OrnamentExecution(rate: .noteValue(positiveBeats(1, 12))))
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, endPitch: .e4, Ornamentation(ornament: trill))])

        #expect(notes == [RenderedNote(0, frac(1, 12), .c4),
                          RenderedNote(frac(1, 12), frac(1, 12), .d4),
                          RenderedNote(frac(1, 6), frac(1, 12), .c4, .e4)])
    }

    @Test
    func graceAfter_defaultTakesTheEndOfTheMainNote() throws {
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceAfter: graceFigure([.d4, .e4])))])

        #expect(notes == [RenderedNote(0, frac(15, 32), .c4),
                          RenderedNote(frac(15, 32), frac(1, 64), .d4),
                          RenderedNote(frac(31, 64), frac(1, 64), .e4)])
    }

    @Test
    func graceAfter_fromPreviousDelaysTheNoteAfter() throws {
        let figure = try graceFigure([.d4], execution: Execution(fromPrevious: .duration(positiveBeats(1, 16))))
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceAfter: figure)),
                                WrittenNote(frac(1, 2), frac(1, 2), .f4)])

        #expect(notes == [RenderedNote(0, frac(1, 2), .c4),
                          RenderedNote(frac(1, 2), frac(1, 16), .d4),
                          RenderedNote(frac(9, 16), frac(7, 16), .f4)])
    }

    @Test
    func graceAfter_tiedFromTheMainNote() throws {
        let figure = try graceFigure([.c4, .d4], isTiedToMainNote: true)
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceAfter: figure))])

        //
        // The main note runs on through the tied C4, then the D4 sounds.
        //
        #expect(notes == [RenderedNote(0, frac(31, 64), .c4),
                          RenderedNote(frac(31, 64), frac(1, 64), .d4)])
    }

    @Test
    func graceBefore_acciaccaturaTakesASixtyFourth() throws {
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: graceFigure([.d4], isSlashed: true)))])

        #expect(notes == [RenderedNote(0, frac(1, 64), .d4),
                          RenderedNote(frac(1, 64), frac(31, 64), .c4)])
    }

    @Test
    func graceBefore_appoggiaturaTakesHalf() throws {
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: graceFigure([.d4])))])

        #expect(notes == [RenderedNote(0, frac(1, 4), .d4),
                          RenderedNote(frac(1, 4), frac(1, 4), .c4)])
    }

    @Test
    func graceBefore_appoggiaturaTakesTwoThirdsInCompoundMeter() throws {
        var meterTable = MeterTable()

        try meterTable.insert(beatTime: 0, meter: #require(Meter(plain: "6/8")))

        let long = try render([WrittenNote(0, frac(3, 8), .c4, Ornamentation(graceBefore: graceFigure([.d4])))],
                              meterTable: meterTable)
        let short = try render([WrittenNote(0, frac(1, 8), .c4, Ornamentation(graceBefore: graceFigure([.d4])))],
                               meterTable: meterTable)

        #expect(long == [RenderedNote(0, frac(1, 4), .d4),
                         RenderedNote(frac(1, 4), frac(1, 8), .c4)])
        //
        // Not longer than an eighth, so half:
        //
        #expect(short == [RenderedNote(0, frac(1, 16), .d4),
                          RenderedNote(frac(1, 16), frac(1, 16), .c4)])
    }

    @Test
    func graceBefore_aShareOfNoPreviousNoteIsAShareOfTheMainNote() throws {
        let figure = try graceFigure([.e4], execution: Execution(fromPrevious: .share(proportion(1, 2))))
        let notes = try render([WrittenNote(frac(1, 2), frac(1, 2), .d4, Ornamentation(graceBefore: figure))])

        #expect(notes == [RenderedNote(frac(1, 4), frac(1, 4), .e4),
                          RenderedNote(frac(1, 2), frac(1, 2), .d4)])
    }

    @Test
    func graceBefore_chordWaitsForAFigureOnOneTone() throws {
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: graceFigure([.d5], isSlashed: true))),
                                WrittenNote(0, frac(1, 2), .e4)])

        #expect(notes == [RenderedNote(0, frac(1, 64), .d5),
                          RenderedNote(frac(1, 64), frac(31, 64), .c4),
                          RenderedNote(frac(1, 64), frac(31, 64), .e4)])
    }

    @Test
    func graceBefore_eventsWithTheirOwnExecutions() throws {
        let figure = try #require(BeatNotes.GraceFigure(events: [graceEvent([.d4], execution: Execution(fromMain: .duration(positiveBeats(1, 16)))),
                                                                 graceEvent([.e4])],
                                                        execution: Execution(fromMain: .duration(positiveBeats(1, 32)))))
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: figure))])

        #expect(notes == [RenderedNote(0, frac(1, 16), .d4),
                          RenderedNote(frac(1, 16), frac(1, 32), .e4),
                          RenderedNote(frac(3, 32), frac(13, 32), .c4)])
    }

    @Test
    func graceBefore_fromMainShare() throws {
        let figure = try graceFigure([.d4], execution: Execution(fromMain: .share(proportion(1, 4))))
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: figure))])

        #expect(notes == [RenderedNote(0, frac(1, 8), .d4),
                          RenderedNote(frac(1, 8), frac(3, 8), .c4)])
    }

    @Test
    func graceBefore_fromPreviousShortensTheNoteBefore() throws {
        let figure = try graceFigure([.e4], execution: Execution(fromPrevious: .duration(positiveBeats(1, 16))))
        let notes = try render([WrittenNote(0, frac(1, 2), .c4),
                                WrittenNote(frac(1, 2), frac(1, 2), .d4, Ornamentation(graceBefore: figure))])

        #expect(notes == [RenderedNote(0, frac(7, 16), .c4),
                          RenderedNote(frac(7, 16), frac(1, 16), .e4),
                          RenderedNote(frac(1, 2), frac(1, 2), .d4)])
    }

    @Test
    func graceBefore_graceChordSoundsTogether() throws {
        let figure = try #require(BeatNotes.GraceFigure(events: [graceEvent([.e4, .g4])]))
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: figure))])

        #expect(notes == [RenderedNote(0, frac(1, 4), .e4),
                          RenderedNote(0, frac(1, 4), .g4),
                          RenderedNote(frac(1, 4), frac(1, 4), .c4)])
    }

    @Test
    func graceBefore_longerFigureTakesASixtyFourthEachCappedAtHalf() throws {
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: graceFigure([.d4, .e4])))])
        let capped = try render([WrittenNote(0, frac(1, 32), .c4, Ornamentation(graceBefore: graceFigure([.d4, .e4])))])

        #expect(notes == [RenderedNote(0, frac(1, 64), .d4),
                          RenderedNote(frac(1, 64), frac(1, 64), .e4),
                          RenderedNote(frac(1, 32), frac(15, 32), .c4)])
        #expect(capped == [RenderedNote(0, frac(1, 128), .d4),
                           RenderedNote(frac(1, 128), frac(1, 128), .e4),
                           RenderedNote(frac(1, 64), frac(1, 64), .c4)])
    }

    @Test
    func graceBefore_partRulesOverWorkRules() throws {
        let work = try renderingWork([renderingPart([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: graceFigure([.d4])))],
                                                    rules: InterpretationRules(grace: GraceRules(maximumShare: proportion(1, 8))))],
                                     rules: InterpretationRules(grace: GraceRules(maximumShare: proportion(1, 4))))
        let notes = try #require(renderedNotes(work.rendered()).first)

        #expect(notes == [RenderedNote(0, frac(1, 16), .d4),
                          RenderedNote(frac(1, 16), frac(7, 16), .c4)])
    }

    @Test
    func graceBefore_rulesSetPlacementTimePerNoteAndShare() throws {
        let beforeBeat = InterpretationRules(grace: GraceRules(slashedPlacement: .beforeBeat))
        let placed = try render([WrittenNote(0, frac(1, 2), .c4),
                                 WrittenNote(frac(1, 2), frac(1, 2), .d4, Ornamentation(graceBefore: graceFigure([.e4], isSlashed: true)))],
                                rules: beforeBeat)
        let perNote = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: graceFigure([.d4], isSlashed: true)))],
                                 rules: InterpretationRules(grace: GraceRules(perNote: positiveSeconds(1, 8))))
        let share = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: graceFigure([.d4])))],
                               rules: InterpretationRules(grace: GraceRules(maximumShare: proportion(1, 8))))

        #expect(placed == [RenderedNote(0, frac(31, 64), .c4),
                           RenderedNote(frac(31, 64), frac(1, 64), .e4),
                           RenderedNote(frac(1, 2), frac(1, 2), .d4)])
        //
        // An eighth of a second at ♩ = 60 is a thirty-second note.
        //
        #expect(perNote == [RenderedNote(0, frac(1, 32), .d4),
                            RenderedNote(frac(1, 32), frac(15, 32), .c4)])
        #expect(share == [RenderedNote(0, frac(1, 16), .d4),
                          RenderedNote(frac(1, 16), frac(7, 16), .c4)])
    }

    @Test
    func graceBefore_tiedIntoTheMainNote() throws {
        let figure = try graceFigure([.d4, .c4], isTiedToMainNote: true)
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: figure))])

        //
        // The tied C4 becomes the main note's start.
        //
        #expect(notes == [RenderedNote(0, frac(1, 64), .d4),
                          RenderedNote(frac(1, 64), frac(31, 64), .c4)])
    }

    @Test
    func graceBefore_writtenLengthsShareTheTime() throws {
        let figure = try #require(BeatNotes.GraceFigure(events: [graceEvent([.d4], length: positiveBeats(1, 8)),
                                                                 graceEvent([.e4], length: positiveBeats(1, 16))],
                                                        execution: Execution(fromMain: .duration(positiveBeats(3, 32)))))
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: figure))])

        #expect(notes == [RenderedNote(0, frac(1, 16), .d4),
                          RenderedNote(frac(1, 16), frac(1, 32), .e4),
                          RenderedNote(frac(3, 32), frac(13, 32), .c4)])
    }

    @Test
    func holds_inSeveralPartsTakeTheLongest() throws {
        let first = try renderingPart([WrittenNote(0, frac(1, 2), .c4, Ornamentation(fermata: Fermata())),
                                       WrittenNote(frac(1, 2), frac(1, 2), .d4)])
        let second = try renderingPart([WrittenNote(0, frac(1, 2), .e4, Ornamentation(fermata: Fermata(shape: .long)))])
        let parts = try renderedNotes(renderingWork([first, second]).rendered(options: RenderingOptions(fermataMode: .stretchedNotes)))

        //
        // The long fermata triples the half note in both parts.
        //
        #expect(parts[0] == [RenderedNote(0, frac(3, 2), .c4), RenderedNote(frac(3, 2), frac(1, 2), .d4)])
        #expect(parts[1] == [RenderedNote(0, frac(3, 2), .e4)])
    }

    @Test
    func holds_markOverARestHoldsTheOtherParts() throws {
        var rest = try renderingPart([])

        rest.markTable.insert(time: 0, mark: .fermata(Fermata(), span: positiveBeats(1, 2)))

        let parts = try renderedNotes(renderingWork([rest, twoNotePart()]).rendered(options: RenderingOptions(fermataMode: .stretchedNotes)))

        #expect(parts[1] == [RenderedNote(0, 1, .c4), RenderedNote(1, frac(1, 2), .d4)])
    }

    @Test
    func leadIn_addsABarWhenThePickupWouldFillOne() throws {
        let rendering = try leadInRendering(pickup: frac(63, 64))

        #expect(rendering.leadIn == .beat(beats(frac(1, 64))))
        #expect(rendering.work.meterTable?.pickup == .zero)
    }

    @Test
    func leadIn_coversTheEarliestOfAGraceFigureAndARoll() throws {
        let part = try renderingPart([WrittenNote(0, frac(1, 4), .c4, Ornamentation(graceBefore: graceFigure([.d5], isSlashed: true),
                                                                                    arpeggio: rollArpeggio(.lastOnBeat))),
                                      WrittenNote(0, frac(1, 4), .e4, Ornamentation(arpeggio: rollArpeggio(.lastOnBeat)))])
        let rendering = try renderingWork([part],
                                          rules: InterpretationRules(grace: GraceRules(slashedPlacement: .beforeBeat))).rendered()

        //
        // The roll reaches a thirty-second before the beat; the grace note only a sixty-fourth.
        //
        #expect(rendering.leadIn == .beat(beats(frac(1, 32))))
        #expect(try renderedNotes(rendering).first == [RenderedNote(0, frac(9, 32), .c4),
                                                       RenderedNote(frac(1, 64), frac(1, 64), .d5),
                                                       RenderedNote(frac(1, 32), frac(1, 4), .e4)])
    }

    @Test
    func leadIn_createsAPickup() throws {
        let rendering = try leadInRendering(pickup: nil)

        #expect(rendering.leadIn == .beat(beats(frac(1, 64))))
        #expect(rendering.work.meterTable?.pickup == beats(frac(1, 64)))
        #expect(try renderedNotes(rendering).first == [RenderedNote(0, frac(1, 64), .d4),
                                                       RenderedNote(frac(1, 64), frac(1, 2), .c4)])
    }

    @Test
    func leadIn_growsAPickup() throws {
        let rendering = try leadInRendering(pickup: frac(1, 4))

        #expect(rendering.work.meterTable?.pickup == beats(frac(17, 64)))
    }

    @Test
    func leadIn_movesEverythingLater() throws {
        var part = try renderingPart([WrittenNote(0, frac(1, 4), .c4, Ornamentation(arpeggio: rollArpeggio(.lastOnBeat))),
                                      WrittenNote(0, frac(1, 4), .e4, Ornamentation(arpeggio: rollArpeggio(.lastOnBeat)))])

        part.dynamicMap.insert(time: 0, dynamic: .ff)

        let rendering = try renderingWork([part]).rendered()

        guard case let .standardBeat(parts, _, _, _) = rendering.work.content.cases
        else { Issue.record("Expected standard beat content"); return }

        //
        // The roll's first tone falls a thirty-second before the beat.
        //
        #expect(rendering.leadIn == .beat(beats(frac(1, 32))))
        #expect(parts.first?.dynamicMap.map(\.time) == [beatTime(frac(1, 32))])
        #expect(try renderedNotes(rendering).first == [RenderedNote(0, frac(9, 32), .c4),
                                                       RenderedNote(frac(1, 32), frac(1, 4), .e4)])
    }

    @Test
    func leadIn_noneWhenNothingStartsEarly() throws {
        let rendering = try renderingWork([renderingPart([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: graceFigure([.d4])))])])
            .rendered()

        #expect(rendering.leadIn == nil)
    }

    @Test
    func mordent_countIsCappedAtHalfTheNote() throws {
        let mordent = try ornament(.mordent, .step(.above, written: nil), OrnamentExecution(rate: .noteValue(positiveBeats(1, 8))))
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, Ornamentation(ornament: mordent))])

        #expect(notes == [RenderedNote(0, frac(1, 16), .c4),
                          RenderedNote(frac(1, 16), frac(1, 16), .d4),
                          RenderedNote(frac(1, 8), frac(1, 8), .c4)])
    }

    @Test
    func mordent_defaultsToOneAlternationAtTwelvePerSecond() throws {
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, Ornamentation(ornament: ornament(.mordent, .step(.above, written: nil))))])

        //
        // A twelfth of a second at ♩ = 60 is a forty-eighth of a whole note (through the tempo
        // map's rounded seconds, so compare closely).
        //
        #expect(notes.map(\.pitch) == [.c4, .d4, .c4])
        #expect(abs((notes[1].length - frac(1, 48)).doubleValue) < 1e-6)
        #expect(abs((notes[2].start + notes[2].length - frac(1, 4)).doubleValue) < 1e-12)
    }

    @Test
    func mordent_lowerWithAWrittenPartner() throws {
        let mordent = try ornament(.mordent, .step(.below, written: "B♭3"), OrnamentExecution(rate: .noteValue(positiveBeats(1, 32))))
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, Ornamentation(ornament: mordent))])

        #expect(notes == [RenderedNote(0, frac(1, 32), .c4),
                          RenderedNote(frac(1, 32), frac(1, 32), "B♭3"),
                          RenderedNote(frac(1, 16), frac(3, 16), .c4)])
    }

    @Test
    func ornament_graceFigureAndTrillOnOneNote() throws {
        let trill = try ornament(.trill, .step(.above, written: nil), OrnamentExecution(rate: .noteValue(positiveBeats(1, 12))))
        let notes = try render([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: graceFigure([.e4]), ornament: trill))])

        //
        // The appoggiatura takes the first half; the trill fills the rest.
        //
        #expect(notes == [RenderedNote(0, frac(1, 4), .e4),
                          RenderedNote(frac(1, 4), frac(1, 12), .c4),
                          RenderedNote(frac(1, 3), frac(1, 12), .d4),
                          RenderedNote(frac(5, 12), frac(1, 12), .c4)])
    }

    @Test
    func ornament_keyboardAndFrequencyPartnersAreAWholeTone() throws {
        var keys = NoteTable<BeatTime, NoteNumber>()
        var frequencies = NoteTable<BeatTime, Frequency>()
        let keyTrill = try #require(NoteTable<BeatTime, NoteNumber>.Ornament(sign: .trill,
                                                                             partner: .step(.above, written: nil),
                                                                             execution: .init(rate: .noteValue(positiveBeats(1, 12)))))
        let frequencyTrill = try #require(NoteTable<BeatTime, Frequency>.Ornament(sign: .trill,
                                                                                  partner: .step(.above, written: nil),
                                                                                  execution: .init(rate: .noteValue(positiveBeats(1, 12)))))

        try keys.insert(attack: 0, duration: beats(frac(1, 4)), pitch: #require(NoteNumber(uintValue: 60)), ornamentation: .init(ornament: keyTrill))
        try frequencies.insert(attack: 0, duration: beats(frac(1, 4)), pitch: Frequency(440), ornamentation: .init(ornament: frequencyTrill))

        let keyWork = Work(content: .keyboardBeat([Part(name: "K", noteTable: keys)], TempoMap(defaultTempo: Tempo(60)), MeterTable(), KeyTable()))
        let frequencyWork = Work(content: .absoluteBeat([Part(name: "F", noteTable: frequencies)],
                                                        TempoMap(defaultTempo: Tempo(60)),
                                                        MeterTable(),
                                                        KeyTable()))

        guard case let .keyboardBeat(keyParts, _, _, _) = try keyWork.rendered().work.content.cases,
              case let .absoluteBeat(frequencyParts, _, _, _) = try frequencyWork.rendered().work.content.cases
        else { Issue.record("Expected beat content"); return }

        let keyPitches = try #require(keyParts.first).noteTable.map(\.startPitch.uintValue)
        let frequencyPitches = try #require(frequencyParts.first).noteTable.map(\.startPitch)
        let wholeTone = Frequency(440).transposed(by: DirectedInterval(interval: Ratio(cents: 200), direction: .ascending))

        #expect(keyPitches == [60, 62, 60])
        #expect(frequencyPitches == [Frequency(440), wholeTone, Frequency(440)])
    }

    @Test
    func plainNotesAreUnchanged() throws {
        let notes = try render([WrittenNote(0, frac(1, 2), .c4), WrittenNote(frac(1, 2), frac(1, 4), .e4, endPitch: .g4)])

        #expect(notes == [RenderedNote(0, frac(1, 2), .c4),
                          RenderedNote(frac(1, 2), frac(1, 4), .e4, .g4)])
    }

    @Test
    func rendered_keepsTheRestAndUnlocks() throws {
        let rules = InterpretationRules(caesura: positiveSeconds(3))
        var work = try renderingWork([renderingPart([WrittenNote(0, frac(1, 2), .c4)], rules: rules)], rules: rules)

        work.isLocked = true

        let rendered = try work.rendered().work

        guard case let .standardBeat(parts, _, _, _) = rendered.content.cases
        else { Issue.record("Expected standard beat content"); return }

        #expect(!rendered.isLocked)
        #expect(rendered.interpretationRules == rules)
        #expect(parts.first?.interpretationRules == rules)
    }

    @Test
    func tremolo_measuredFollowsItsStrokes() throws {
        let tremolo = try ornament(.tremolo(.measured(TremoloStrokes(uintValue: 2).unsafelyUnwrapped)), .repeat)
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, Ornamentation(ornament: tremolo))])

        #expect(notes == [RenderedNote(0, frac(1, 16), .c4),
                          RenderedNote(frac(1, 16), frac(1, 16), .c4),
                          RenderedNote(frac(1, 8), frac(1, 16), .c4),
                          RenderedNote(frac(3, 16), frac(1, 16), .c4)])
    }

    @Test
    func tremolo_twoNotesAlternate() throws {
        let tremolo = try ornament(.tremolo(.unmeasured), .pitches([.e4]), OrnamentExecution(rate: .noteValue(positiveBeats(1, 16))))
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, Ornamentation(ornament: tremolo))])

        #expect(notes.map(\.pitch) == [.c4, .e4, .c4, .e4])
        #expect(notes.allSatisfy { $0.length == frac(1, 16) })
    }

    @Test
    func trill_aCountOfOneIsAMordent() throws {
        let execution = OrnamentExecution(rate: .noteValue(positiveBeats(1, 32)),
                                          extent: .count(AlternationCount(uintValue: 1).unsafelyUnwrapped))
        let trill = try ornament(.trill, .step(.above, written: nil), execution)
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, Ornamentation(ornament: trill))])

        #expect(notes == [RenderedNote(0, frac(1, 32), .c4),
                          RenderedNote(frac(1, 32), frac(1, 32), .d4),
                          RenderedNote(frac(1, 16), frac(3, 16), .c4)])
    }

    @Test
    func trill_aSpanShareThenHoldsTheMainNote() throws {
        let trill = try ornament(.trill, .step(.above, written: nil), OrnamentExecution(rate: .noteValue(positiveBeats(1, 24)),
                                                                                        extent: .span(proportion(1, 2))))
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, Ornamentation(ornament: trill))])

        //
        // An eighth at a twenty-fourth per note is three notes, C D C; the last C holds on.
        //
        #expect(notes == [RenderedNote(0, frac(1, 24), .c4),
                          RenderedNote(frac(1, 24), frac(1, 24), .d4),
                          RenderedNote(frac(1, 12), frac(1, 6), .c4)])
    }

    @Test
    func trill_defaultRateFillsWithAnOddCount() throws {
        let notes = try render([WrittenNote(0, frac(5, 16), .c4, Ornamentation(ornament: ornament(.trill, .step(.above, written: nil))))])

        //
        // 1.25 seconds at 12 per second is 15 notes, starting and ending on C.
        //
        #expect(notes.count == 15)
        #expect(notes.allSatisfy { $0.length == frac(1, 48) })
        #expect(notes.first?.pitch == .c4)
        #expect(notes.last?.pitch == .c4)
    }

    @Test
    func trill_defaultRateAtAnInexactTempo() throws {
        let onMain = try ornament(.trill, .step(.above, written: nil))
        let onPartner = try ornament(.trill, .step(.above, written: nil), OrnamentExecution(startNote: .partner))
        let part = try renderingPart([WrittenNote(0, frac(1, 4), .c4, Ornamentation(ornament: onMain)),
                                      WrittenNote(frac(1, 4), frac(1, 4), .d4, Ornamentation(ornament: onPartner))])
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: .zero,
                        tempo: Tempo(80))

        let work = Work(content: .standardBeat([part], tempoMap, MeterTable(), KeyTable()))
        let notes = try #require(renderedNotes(work.rendered()).first)

        //
        // A tempo map entry, as an import makes, gives inexact lengths, so the counts are inexact
        // before they're rounded. At ♩ = 80, a quarter note lasts 0.75 seconds, 9 notes at 12
        // per second: the first trill takes that odd count, starting on its main note; the
        // second, starting on its partner, takes the nearest even count.
        //
        #expect(notes.first?.pitch == .c4)
        #expect(notes.filter { $0.start < frac(1, 4) }.count == 9)
        #expect(notes.first { $0.start >= frac(1, 4) }?.pitch == .e4)
        #expect(notes.last?.pitch == .d4)
    }

    @Test
    func trill_diatonicStepInTheKey() throws {
        let trill = try ornament(.trill, .step(.above, written: nil), OrnamentExecution(rate: .noteValue(positiveBeats(1, 12))))
        let inF = try render([WrittenNote(0, frac(1, 4), .e4, Ornamentation(ornament: trill))],
                             keyTable: makeKeyTable([(0, -1)]))
        let noKey = try render([WrittenNote(0, frac(1, 4), .e4, Ornamentation(ornament: trill))])

        #expect(inF.map(\.pitch) == [.e4, .f4, .e4])
        #expect(noKey.map(\.pitch) == [.e4, "F♯4", .e4])
    }

    @Test
    func trill_rulesSetRatePartnerAndStart() throws {
        let rules = InterpretationRules(trill: OrnamentRules(startNote: .partner,
                                                             partnerRule: .halfStep,
                                                             rate: NotesPerSecond(numberValue: 8).unsafelyUnwrapped))
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, Ornamentation(ornament: ornament(.trill, .step(.above, written: nil))))],
                               rules: rules)

        //
        // 8 per second for a second, starting on the partner (D♭), ending on C: eight notes.
        //
        #expect(notes.map(\.pitch) == ["D♭4", .c4, "D♭4", .c4, "D♭4", .c4, "D♭4", .c4])
        #expect(notes.allSatisfy { $0.length == frac(1, 32) })
    }

    @Test
    func trill_unsignedLowerTrill() throws {
        let lower = try ornament(nil, .step(.below, written: nil), OrnamentExecution(rate: .noteValue(positiveBeats(1, 12))))
        let notes = try render([WrittenNote(0, frac(1, 4), .c4, Ornamentation(ornament: lower))])

        #expect(notes.map(\.pitch) == [.c4, "B♭3", .c4])
    }

    @Test
    func trill_withNoPartnerInRangeIsPlain() throws {
        var keys = NoteTable<BeatTime, NoteNumber>()
        let trill = try #require(NoteTable<BeatTime, NoteNumber>.Ornament(sign: .trill, partner: .step(.above, written: nil)))

        try keys.insert(attack: 0, duration: beats(frac(1, 4)), pitch: #require(NoteNumber(uintValue: 127)), ornamentation: .init(ornament: trill))

        let work = Work(content: .keyboardBeat([Part(name: "K", noteTable: keys)], TempoMap(defaultTempo: Tempo(60)), MeterTable(), KeyTable()))

        guard case let .keyboardBeat(parts, _, _, _) = try work.rendered().work.content.cases
        else { Issue.record("Expected keyboard beat content"); return }

        #expect(try #require(parts.first).noteTable.count == 1)
    }

    @Test
    func wall_alwaysInsertsTime() throws {
        var table = NoteTable<WallTime, Pitch>()

        try table.insert(attack: wallTime(0),
                         duration: wallDuration(2_000),
                         pitch: .c4,
                         ornamentation: .init(fermata: Fermata()))
        table.insert(attack: wallTime(2_000), duration: wallDuration(2_000), pitch: .d4)

        let work = Work(content: .standardWall([Part(name: "W", noteTable: table)]))

        for mode in [RenderingOptions.FermataMode.tempoChanges, .stretchedNotes] {
            let rendering = try work.rendered(options: RenderingOptions(fermataMode: mode))

            guard case let .standardWall(parts) = rendering.work.content.cases,
                  let notes = parts.first?.noteTable
            else { Issue.record("Expected standard wall content"); return }

            #expect(notes.map(\.attack) == [wallTime(0), wallTime(4_000)])
            #expect(notes.map(\.duration) == [wallDuration(4_000), wallDuration(2_000)])
            #expect(rendering.fermataTimes == [.wall(wallTime(0))])
        }
    }

    @Test
    func wall_graceNotesTakeFortyMillisecondsAndShiftTheStart() throws {
        var table = NoteTable<WallTime, Pitch>()
        let event = try #require(NoteTable<WallTime, Pitch>.GraceFigure.Event(pitches: [.d4]))
        let figure = try #require(NoteTable<WallTime, Pitch>.GraceFigure(events: [event], isSlashed: true))

        try table.insert(attack: wallTime(0),
                         duration: wallDuration(1_000),
                         pitch: .c4,
                         ornamentation: .init(graceBefore: figure))
        try table.insert(attack: wallTime(1_000),
                         duration: wallDuration(1_000),
                         pitch: .e4,
                         ornamentation: .init(graceBefore: figure))

        let rules = InterpretationRules(grace: GraceRules(slashedPlacement: .beforeBeat))
        let work = Work(content: .standardWall([Part(name: "W", noteTable: table)]), interpretationRules: rules)
        let rendering = try work.rendered()

        guard case let .standardWall(parts) = rendering.work.content.cases,
              let notes = parts.first?.noteTable
        else { Issue.record("Expected standard wall content"); return }

        #expect(rendering.leadIn == .wall(wallDuration(40)))
        #expect(notes.map(\.attack) == [wallTime(0), wallTime(40), wallTime(1_000), wallTime(1_040)])
        #expect(notes.map(\.startPitch) == [.d4, .c4, .d4, .e4])
        //
        // The C4 ends where the second grace note begins.
        //
        #expect(notes.map(\.duration) == [wallDuration(40), wallDuration(960), wallDuration(40), wallDuration(1_000)])
    }
}

// swiftlint:enable file_length
