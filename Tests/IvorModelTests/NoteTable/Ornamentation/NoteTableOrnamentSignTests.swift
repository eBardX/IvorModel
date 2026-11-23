// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiTools

struct NoteTableOrnamentSignTests {
}

// MARK: -

extension NoteTableOrnamentSignTests {
    typealias Sign = BeatNotes.Ornament.Sign

    @Test
    func allows_matchesEachSignToItsPartners() {
        #expect(Sign.trill.allows(.step(.above, written: nil)))
        #expect(!Sign.trill.allows(.step(.below, written: nil)))
        #expect(!Sign.trill.allows(.repeat))
        #expect(Sign.mordent.allows(.step(.above, written: nil)))
        #expect(Sign.mordent.allows(.step(.below, written: "B3")))
        #expect(!Sign.mordent.allows(.pitches(["E4"])))
        #expect(Sign.tremolo(.unmeasured).allows(.repeat))
        #expect(Sign.tremolo(.measured(2)).allows(.pitches(["E4"])))
        #expect(!Sign.tremolo(.unmeasured).allows(.step(.above, written: nil)))
    }

    @Test
    func codable_encodesOneCase() throws {
        #expect(try encodedJSON(Sign.trill) == #"{"trill":true}"#)
        #expect(try encodedJSON(Sign.mordent) == #"{"mordent":true}"#)
        #expect(try encodedJSON(Sign.tremolo(.measured(3))) == #"{"tremolo":{"measured":3}}"#)

        for sign in [Sign.trill, .mordent, .tremolo(.unmeasured), .tremolo(.measured(1))] {
            #expect(try codingRoundTrip(sign) == sign)
        }
    }

    @Test(arguments: [#"{}"#, #"{"trill":false}"#, #"{"turn":true}"#, #"{"trill":true,"mordent":true}"#])
    func codable_rejectsInvalid(_ json: String) {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Sign.self, json)
        }
    }

    @Test
    func hashable() {
        #expect(Set([Sign.trill, .trill, .mordent]).count == 2)
    }
}
