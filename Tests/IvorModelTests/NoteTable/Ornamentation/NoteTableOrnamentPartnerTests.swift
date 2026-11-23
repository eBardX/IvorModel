// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct NoteTableOrnamentPartnerTests {
}

// MARK: -

extension NoteTableOrnamentPartnerTests {
    typealias Partner = BeatNotes.Ornament.Partner

    @Test
    func codable_encodesOneCase() throws {
        #expect(try encodedJSON(Partner.repeat) == #"{"repeat":true}"#)
        #expect(try encodedJSON(Partner.step(.below, written: nil)) == #"{"step":{"side":"below"}}"#)

        for partner in [Partner.repeat, .step(.above, written: nil), .step(.above, written: "D♭5"), .pitches(["E4", "G4"])] {
            #expect(try codingRoundTrip(partner) == partner)
        }
    }

    @Test(arguments: [#"{}"#, #"{"repeat":false}"#, #"{"pitches":[]}"#, #"{"step":{}}"#, #"{"neighbor":true}"#])
    func codable_rejectsInvalid(_ json: String) {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Partner.self, json)
        }
    }

    @Test
    func codable_rejectsUnsortedPitches() throws {
        let json = try #"{"pitches":"# + encodedJSON([Pitch("G4"), Pitch("E4")]) + "}"

        #expect(throws: DecodingError.self) {
            try decodeJSON(Partner.self, json)
        }
    }

    @Test
    func hashable() {
        #expect(Set([Partner.repeat, .repeat, .step(.above, written: nil)]).count == 2)
    }

    @Test
    func isValid() {
        #expect(Partner.repeat.isValid)
        #expect(Partner.step(.above, written: nil).isValid)
        #expect(Partner.pitches(["E4"]).isValid)
        #expect(!Partner.pitches([]).isValid)
        #expect(!Partner.pitches(["G4", "E4"]).isValid)
        #expect(!Partner.pitches(["E4", "E4"]).isValid)
    }

    @Test
    func mapPitches() {
        #expect(Partner.repeat.mapPitches(swapCAndG) == .repeat)
        #expect(Partner.step(.above, written: nil).mapPitches(swapCAndG) == .step(.above, written: nil))
        #expect(Partner.step(.below, written: "C4").mapPitches(swapCAndG) == .step(.below, written: "G4"))
        #expect(Partner.pitches(["C4", "E4", "G4"]).mapPitches(swapCAndG) == .pitches(["C4", "E4", "G4"]))
        #expect(Partner.pitches(["C4", "G4"]).mapPitches { _ in "E4" } == .pitches(["E4"]))
    }

    @Test
    func pitches() {
        #expect(Partner.repeat.pitches.isEmpty)
        #expect(Partner.step(.above, written: nil).pitches.isEmpty)
        #expect(Partner.step(.above, written: "D5").pitches == ["D5"])
        #expect(Partner.pitches(["E4", "G4"]).pitches == ["E4", "G4"])
    }
}
