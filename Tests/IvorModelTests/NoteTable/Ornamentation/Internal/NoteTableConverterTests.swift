// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableConverterTests {
}

// MARK: -

extension NoteTableConverterTests {
    @Test
    func amount_durationConverts() throws {
        #expect(try swappingNoteConverter().amount(.duration(positiveBeats(1, 8))) == .duration(positiveBeats(1, 4)))
    }

    @Test
    func amount_shareIsUnchanged() throws {
        #expect(try swappingNoteConverter().amount(.share(proportion(1, 3))) == .share(proportion(1, 3)))
    }

    @Test
    func arpeggio_keepsGroupAndDirectionAndConvertsTheExecution() throws {
        let arpeggio = BeatNotes.Arpeggio(group: 2,
                                          direction: .down,
                                          execution: BeatNotes.ArpeggioExecution(spread: .perTone(positiveBeats(1, 32))))

        let expected = BeatNotes.Arpeggio(group: 2,
                                          direction: .down,
                                          execution: BeatNotes.ArpeggioExecution(spread: .perTone(positiveBeats(1, 16))))

        #expect(try swappingNoteConverter().arpeggio(arpeggio) == expected)
    }

    @Test
    func arpeggioExecution_keepsTheAnchor() throws {
        let execution = BeatNotes.ArpeggioExecution(spread: .total(proportion(1, 2)),
                                                    anchor: .lastOnBeat)

        #expect(try swappingNoteConverter().arpeggioExecution(execution) == execution)
    }

    @Test
    func fermataConverter_usesTheSameDurationConversion() throws {
        #expect(try swappingNoteConverter().fermataConverter.positive(positiveBeats(1, 4)) == positiveBeats(1, 2))
    }

    @Test
    func graceEvent_aPitchCollapseRemovesDuplicates() throws {
        let converter = BeatNotes.Converter<BeatTime, Pitch>(pitch: { _ in .c4 },
                                                             duration: { $0 })

        #expect(try converter.graceEvent(graceEvent([.c4, .e4])).pitches == [.c4])
    }

    @Test
    func graceEvent_mapsAndSortsPitchesAndConvertsTheLength() throws {
        let converted = try swappingNoteConverter().graceEvent(graceEvent([.c4, .e4], length: positiveBeats(1, 16)))

        #expect(converted.pitches == [.e4, .g4])
        #expect(converted.length == positiveBeats(1, 8))
    }

    @Test
    func graceExecution_convertsBothAmounts() throws {
        let execution = BeatNotes.GraceExecution(fromPrevious: .duration(positiveBeats(1, 16)),
                                                 fromMain: .share(proportion(1, 4)))

        #expect(try swappingNoteConverter().graceExecution(execution) == BeatNotes.GraceExecution(fromPrevious: .duration(positiveBeats(1, 8)),
                                                                                                  fromMain: .share(proportion(1, 4))))
    }

    @Test
    func graceFigure_keepsItsFlags() throws {
        let figure = try graceFigure([.c4, .d4],
                                     length: positiveBeats(1, 16),
                                     isSlashed: true,
                                     isTiedToMainNote: true)
        let converted = try swappingNoteConverter().graceFigure(figure)

        #expect(converted.isSlashed)
        #expect(converted.isTiedToMainNote)
        #expect(converted.pitches == [.g4, .d4])
        #expect(converted.events.map(\.length) == [positiveBeats(1, 8), positiveBeats(1, 8)])
    }

    @Test
    func init_storesTheConversions() throws {
        let converter = swappingNoteConverter()

        #expect(try converter.duration(beats(1)) == beats(2))
        #expect(try converter.pitch(.g4) == .c4)
    }

    @Test
    func ornament_aFailingPitchThrows() {
        let converter = BeatNotes.Converter<BeatTime, Pitch>(pitch: { _ in throw ConversionFailure() },
                                                             duration: { $0 })

        #expect(throws: ConversionFailure.self) {
            try converter.ornament(ornament(.trill, .step(.above, written: .d4)))
        }
    }

    @Test
    func ornament_convertsSignPartnerAndExecution() throws {
        let value = try ornament(.tremolo(.unmeasured),
                                 .pitches([.c4]),
                                 BeatNotes.OrnamentExecution(rate: .noteValue(positiveBeats(1, 32))))

        #expect(try swappingNoteConverter().ornament(value) == ornament(.tremolo(.unmeasured),
                                                                        .pitches([.g4]),
                                                                        BeatNotes.OrnamentExecution(rate: .noteValue(positiveBeats(1, 16)))))
    }

    @Test
    func ornamentation_convertsEverySlot() throws {
        let value = try BeatNotes.Ornamentation(graceBefore: graceFigure([.c4]),
                                                graceAfter: graceFigure([.e4], length: positiveBeats(1, 16)),
                                                ornament: ornament(.trill, .step(.above, written: .d4)),
                                                arpeggio: BeatNotes.Arpeggio(group: 1),
                                                fermata: Fermata(execution: FermataExecution(hold: .added(positiveBeats(1, 4)))))
        let converted = try swappingNoteConverter().ornamentation(value)

        #expect(converted.graceBefore?.pitches == [.g4])
        #expect(converted.graceAfter?.events.first?.length == positiveBeats(1, 8))
        #expect(converted.ornament == value.ornament)
        #expect(converted.arpeggio == value.arpeggio)
        #expect(converted.fermata == Fermata(execution: FermataExecution(hold: .added(positiveBeats(1, 2)))))
    }

    @Test
    func ornamentExecution_keepsEverythingButTheRate() throws {
        let execution = BeatNotes.OrnamentExecution(startNote: .partner,
                                                    partnerRule: .diatonic,
                                                    rate: .noteValue(positiveBeats(1, 32)),
                                                    extent: .span(proportion(1, 2)))

        #expect(try swappingNoteConverter().ornamentExecution(execution) == BeatNotes.OrnamentExecution(startNote: .partner,
                                                                                                        partnerRule: .diatonic,
                                                                                                        rate: .noteValue(positiveBeats(1, 16)),
                                                                                                        extent: .span(proportion(1, 2))))
    }

    @Test
    func partner_pitchesAreMappedAndSorted() throws {
        #expect(try swappingNoteConverter().partner(.pitches([.c4, .e4])) == .pitches([.e4, .g4]))
    }

    @Test
    func partner_repeat() throws {
        #expect(try swappingNoteConverter().partner(.repeat) == .repeat)
    }

    @Test
    func partner_stepMapsItsWrittenPitch() throws {
        #expect(try swappingNoteConverter().partner(.step(.above, written: .g4)) == .step(.above, written: .c4))
        #expect(try swappingNoteConverter().partner(.step(.below, written: nil)) == .step(.below, written: nil))
    }

    @Test
    func positive_aLengthThatConvertsToZeroThrows() {
        let converter = BeatNotes.Converter<BeatTime, Pitch>(pitch: { $0 },
                                                             duration: { _ in beats(0) })

        #expect(throws: ConversionFailure.self) {
            try converter.positive(positiveBeats(1))
        }
    }

    @Test
    func rate_noteValueConverts() throws {
        #expect(try swappingNoteConverter().rate(.noteValue(positiveBeats(1, 32))) == .noteValue(positiveBeats(1, 16)))
    }

    @Test
    func rate_perSecondIsUnchanged() throws {
        #expect(try swappingNoteConverter().rate(.perSecond(notesPerSecond(12))) == .perSecond(notesPerSecond(12)))
    }

    @Test
    func sign_everyCase() throws {
        let strokes = try #require(TremoloStrokes(uintValue: 3))
        let converter = swappingNoteConverter()

        #expect(converter.sign(.mordent) == .mordent)
        #expect(converter.sign(.tremolo(.measured(strokes))) == .tremolo(.measured(strokes)))
        #expect(converter.sign(.tremolo(.unmeasured)) == .tremolo(.unmeasured))
        #expect(converter.sign(.trill) == .trill)
    }

    @Test
    func spread_perToneConverts() throws {
        #expect(try swappingNoteConverter().spread(.perTone(positiveBeats(1, 32))) == .perTone(positiveBeats(1, 16)))
    }

    @Test
    func spread_totalIsUnchanged() throws {
        #expect(try swappingNoteConverter().spread(.total(proportion(1, 2))) == .total(proportion(1, 2)))
    }
}
