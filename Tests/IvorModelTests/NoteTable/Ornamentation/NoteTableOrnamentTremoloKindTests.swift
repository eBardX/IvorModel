// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiTools

struct NoteTableOrnamentTremoloKindTests {
}

// MARK: -

extension NoteTableOrnamentTremoloKindTests {
    typealias Kind = BeatNotes.Ornament.TremoloKind

    @Test
    func codable_encodesOneCase() throws {
        #expect(try encodedJSON(Kind.measured(3)) == #"{"measured":3}"#)
        #expect(try encodedJSON(Kind.unmeasured) == #"{"unmeasured":true}"#)
        #expect(try codingRoundTrip(Kind.measured(3)) == .measured(3))
        #expect(try codingRoundTrip(Kind.unmeasured) == .unmeasured)
    }

    @Test(arguments: [#"{}"#, #"{"measured":9}"#, #"{"unmeasured":false}"#, #"{"fast":true}"#])
    func codable_rejectsInvalid(_ json: String) {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Kind.self, json)
        }
    }

    @Test
    func hashable() {
        #expect(Set([Kind.measured(2), .measured(2), .unmeasured]).count == 2)
    }
}
