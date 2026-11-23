// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableOrnamentExecutionRateTests {
}

// MARK: -

extension NoteTableOrnamentExecutionRateTests {
    typealias Rate = BeatNotes.OrnamentExecution.Rate

    @Test
    func codable_encodesOneCase() throws {
        #expect(try encodedJSON(Rate.perSecond(12)).hasPrefix(#"{"perSecond":"#))
        #expect(try codingRoundTrip(Rate.perSecond(12)) == .perSecond(12))
        #expect(try codingRoundTrip(Rate.noteValue(positiveBeats(1, 32))) == .noteValue(positiveBeats(1, 32)))
    }

    @Test(arguments: [#"{}"#, #"{"perSecond":0}"#, #"{"speed":1}"#])
    func codable_rejectsInvalid(_ json: String) {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Rate.self, json)
        }
    }

    @Test
    func hashable() {
        #expect(Set([Rate.perSecond(12), .perSecond(12), .noteValue(positiveBeats(1, 32))]).count == 2)
    }

    @Test
    func scaled_scalesOnlyNoteValues() {
        #expect(Rate.noteValue(positiveBeats(1, 32)).scaled(by: 2) == .noteValue(positiveBeats(1, 16)))
        #expect(Rate.perSecond(12).scaled(by: 2) == .perSecond(12))
        #expect(Rate.noteValue(positiveBeats(1, 32)).scaled(by: 0) == nil)
    }
}
