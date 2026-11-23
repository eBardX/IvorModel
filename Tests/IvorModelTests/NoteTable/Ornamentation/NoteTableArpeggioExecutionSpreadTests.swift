// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableArpeggioExecutionSpreadTests {
}

// MARK: -

extension NoteTableArpeggioExecutionSpreadTests {
    typealias Spread = BeatNotes.ArpeggioExecution.Spread

    @Test
    func codable_encodesOneCase() throws {
        #expect(try encodedJSON(Spread.total(proportion(1, 4))).hasPrefix(#"{"total":"#))
        #expect(try codingRoundTrip(Spread.total(proportion(1, 4))) == .total(proportion(1, 4)))
        #expect(try codingRoundTrip(Spread.perTone(positiveBeats(1, 64))) == .perTone(positiveBeats(1, 64)))
    }

    @Test(arguments: [#"{}"#, #"{"total":2}"#, #"{"each":1}"#])
    func codable_rejectsInvalid(_ json: String) {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Spread.self, json)
        }
    }

    @Test
    func hashable() {
        #expect(Set([Spread.total(proportion(1, 4)), .total(proportion(1, 4)), .perTone(positiveBeats(1, 64))]).count == 2)
    }

    @Test
    func scaled_scalesOnlyPerToneDurations() {
        #expect(Spread.perTone(positiveBeats(1, 64)).scaled(by: 2) == .perTone(positiveBeats(1, 32)))
        #expect(Spread.total(proportion(1, 4)).scaled(by: 2) == .total(proportion(1, 4)))
        #expect(Spread.perTone(positiveBeats(1, 64)).scaled(by: 0) == nil)
    }
}
