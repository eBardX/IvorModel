// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableOrnamentationTests {
}

// MARK: -

extension NoteTableOrnamentationTests {
    typealias Ornamentation = BeatNotes.Ornamentation

    @Test
    func codable_omitsNilSlots() throws {
        #expect(try encodedJSON(Ornamentation()) == "{}")
        #expect(try encodedJSON(Ornamentation(fermata: Fermata())) == #"{"fermata":{"shape":"normal"}}"#)
    }

    @Test
    func codable_rejectsAnInvalidSlot() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Ornamentation.self, #"{"graceBefore":{"events":[]}}"#)
        }
    }

    @Test
    func codable_roundTrip() throws {
        let ornamentation = try fullOrnamentation()

        #expect(try codingRoundTrip(ornamentation) == ornamentation)
    }

    @Test
    func hashable() throws {
        #expect(try Set([fullOrnamentation(), fullOrnamentation(), Ornamentation()]).count == 2)
    }

    @Test
    func isEmpty() throws {
        #expect(Ornamentation().isEmpty)
        #expect(!Ornamentation(arpeggio: BeatNotes.Arpeggio(group: 1)).isEmpty)
        #expect(try !fullOrnamentation().isEmpty)
    }

    @Test
    func mapPitches_mapsGraceAndPartnerPitchesOnly() throws {
        let ornamentation = try Ornamentation(graceBefore: graceFigure(["C4"]),
                                              graceAfter: graceFigure(["G4"]),
                                              ornament: ornament(.trill, .step(.above, written: "C4")),
                                              arpeggio: BeatNotes.Arpeggio(group: 1))
        let mapped = ornamentation.mapPitches(swapCAndG)

        #expect(mapped.graceBefore?.pitches == ["G4"])
        #expect(mapped.graceAfter?.pitches == ["C4"])
        #expect(mapped.ornament?.partner == .step(.above, written: "G4"))
        #expect(mapped.arpeggio == ornamentation.arpeggio)
    }

    @Test
    func merged_keepsTheFirstNotesSlotsAndTheLastNotesFigureAfter() throws {
        let first = try BeatNotes.Ornamentation(graceBefore: graceFigure([.d4]),
                                                graceAfter: graceFigure([.e4]),
                                                ornament: ornament(.trill, .step(.above, written: nil)),
                                                arpeggio: BeatNotes.Arpeggio(group: 1),
                                                fermata: Fermata())
        let last = try BeatNotes.Ornamentation(graceBefore: graceFigure([.f4]),
                                               graceAfter: graceFigure([.g4]),
                                               fermata: Fermata(shape: .long))
        let merged = try #require(BeatNotes.Ornamentation.merged(first: first, last: last))

        #expect(merged.graceBefore?.pitches == [.d4])
        #expect(merged.graceAfter?.pitches == [.g4])
        #expect(merged.ornament == first.ornament)
        #expect(merged.arpeggio == first.arpeggio)
        #expect(merged.fermata == Fermata())
        #expect(BeatNotes.Ornamentation.merged(first: nil, last: nil) == nil)
        #expect(try BeatNotes.Ornamentation.merged(first: BeatNotes.Ornamentation(graceAfter: graceFigure([.e4])), last: nil) == nil)
    }

    @Test
    func pitches_areInPerformanceOrder() throws {
        let ornamentation = try Ornamentation(graceBefore: graceFigure(["D4", "C4"]),
                                              graceAfter: graceFigure(["F4"]),
                                              ornament: ornament(.tremolo(.measured(2)), .pitches(["E4"])))

        #expect(ornamentation.pitches == ["D4", "C4", "E4", "F4"])
        #expect(Ornamentation().pitches.isEmpty)
    }

    @Test
    func reversed_swapsAndReversesTheFigures() throws {
        let ornamentation = try Ornamentation(graceBefore: graceFigure(["C4", "D4"]),
                                              ornament: ornament(.trill, .step(.above, written: nil)),
                                              arpeggio: BeatNotes.Arpeggio(group: 1, direction: .up))
        let reversed = ornamentation.reversed()

        #expect(reversed.graceBefore == nil)
        #expect(reversed.graceAfter?.pitches == ["D4", "C4"])
        #expect(reversed.ornament == ornamentation.ornament)
        #expect(reversed.arpeggio == ornamentation.arpeggio)
        #expect(reversed.reversed() == ornamentation)
    }

    @Test
    func scaled() throws {
        let ornamentation = try fullOrnamentation()
        let scaled = try #require(ornamentation.scaled(by: 2))

        #expect(try scaled.graceBefore == graceFigure(["D5"], length: positiveBeats(1, 8)))
        #expect(scaled.ornament?.execution?.rate == .noteValue(positiveBeats(1, 16)))
        #expect(scaled.arpeggio?.execution?.spread == .perTone(positiveBeats(1, 32)))
        #expect(scaled.fermata?.execution?.hold == .added(positiveBeats(1, 2)))
        #expect(scaled.graceAfter == ornamentation.graceAfter)
        #expect(ornamentation.scaled(by: 0) == nil)
        #expect(Ornamentation().scaled(by: 0) == Ornamentation())
    }
}
