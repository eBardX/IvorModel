// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableOrnamentTests {
}

// MARK: -

extension NoteTableOrnamentTests {
    typealias Ornament = BeatNotes.Ornament

    @Test
    func codable_omitsNilFields() throws {
        let trill = try ornament(.trill, .step(.above, written: nil))

        #expect(try encodedJSON(trill) == #"{"partner":{"step":{"side":"above"}},"sign":{"trill":true}}"#)
        #expect(try encodedJSON(ornament(nil, .step(.below, written: nil))) == #"{"partner":{"step":{"side":"below"}}}"#)
    }

    @Test
    func codable_rejectsMismatchedParts() {
        let jsons = [#"{"sign":{"trill":true},"partner":{"step":{"side":"below"}}}"#,
                     #"{"sign":{"mordent":true},"partner":{"repeat":true}}"#,
                     #"{"partner":{"repeat":true},"execution":{"partnerRule":"halfStep"}}"#,
                     #"{"sign":{"trill":true}}"#]

        for json in jsons {
            #expect(throws: DecodingError.self) {
                try decodeJSON(Ornament.self, json)
            }
        }
    }

    @Test
    func codable_roundTrip() throws {
        let ornaments = try [ornament(.trill, .step(.above, written: "D♭5"), BeatNotes.OrnamentExecution(startNote: .partner)),
                             ornament(.mordent, .step(.below, written: nil), BeatNotes.OrnamentExecution(partnerRule: .halfStep)),
                             ornament(.tremolo(.measured(3)), .pitches(["E4", "G4"])),
                             ornament(.tremolo(.unmeasured), .repeat),
                             ornament(nil, .step(.below, written: nil), BeatNotes.OrnamentExecution(extent: .span(proportion(1, 2))))]

        for value in ornaments {
            #expect(try codingRoundTrip(value) == value)
        }
    }

    @Test
    func hashable() throws {
        let trill = try ornament(.trill, .step(.above, written: nil))

        #expect(try Set([trill, trill, ornament(.mordent, .step(.above, written: nil))]).count == 2)
    }

    @Test
    func init_allowsAPartnerRuleOnlyWithAStep() {
        let rule = BeatNotes.OrnamentExecution(partnerRule: .wholeStep)

        #expect(Ornament(sign: .trill, partner: .step(.above, written: nil), execution: rule) != nil)
        #expect(Ornament(sign: .tremolo(.unmeasured), partner: .repeat, execution: rule) == nil)
        #expect(Ornament(partner: .pitches(["E4"]), execution: rule) == nil)
    }

    @Test
    func init_checksTheSignAgainstThePartner() {
        #expect(Ornament(sign: .trill, partner: .step(.above, written: nil)) != nil)
        #expect(Ornament(sign: .trill, partner: .step(.below, written: nil)) == nil)
        #expect(Ornament(sign: .mordent, partner: .step(.below, written: nil)) != nil)
        #expect(Ornament(sign: .mordent, partner: .pitches(["E4"])) == nil)
        #expect(Ornament(sign: .tremolo(.unmeasured), partner: .repeat) != nil)
        #expect(Ornament(sign: .tremolo(.unmeasured), partner: .step(.above, written: nil)) == nil)
        #expect(Ornament(partner: .step(.below, written: nil)) != nil)
    }

    @Test
    func init_rejectsInvalidPartnerPitches() {
        #expect(Ornament(sign: .tremolo(.measured(2)), partner: .pitches([])) == nil)
        #expect(Ornament(partner: .pitches(["G4", "E4"])) == nil)
    }

    @Test
    func mapPitches_mapsOnlyWrittenPartners() throws {
        let trill = try ornament(.trill, .step(.above, written: "C4"))

        #expect(try trill.mapPitches(swapCAndG) == ornament(.trill, .step(.above, written: "G4")))
        #expect(try ornament(.tremolo(.unmeasured), .repeat).mapPitches(swapCAndG) == ornament(.tremolo(.unmeasured), .repeat))
    }

    @Test
    func pitches() throws {
        #expect(try ornament(.tremolo(.measured(2)), .pitches(["E4", "G4"])).pitches == ["E4", "G4"])
        #expect(try ornament(.trill, .step(.above, written: nil)).pitches.isEmpty)
    }

    @Test
    func scaled() throws {
        let trill = try ornament(.trill,
                                 .step(.above, written: nil),
                                 BeatNotes.OrnamentExecution(rate: .noteValue(positiveBeats(1, 32))))

        #expect(try trill.scaled(by: 2) == ornament(.trill,
                                                    .step(.above, written: nil),
                                                    BeatNotes.OrnamentExecution(rate: .noteValue(positiveBeats(1, 16)))))
        #expect(trill.scaled(by: 0) == nil)
        #expect(try ornament(.mordent, .step(.above, written: nil)).scaled(by: 0) == ornament(.mordent, .step(.above, written: nil)))
    }
}
