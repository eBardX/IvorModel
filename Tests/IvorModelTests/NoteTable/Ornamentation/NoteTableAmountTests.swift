// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableAmountTests {
}

// MARK: -

extension NoteTableAmountTests {
    @Test
    func codable_encodesOneCase() throws {
        let share = BeatNotes.Amount.share(proportion(1, 2))

        #expect(try encodedJSON(share).hasPrefix(#"{"share":"#))
        #expect(try codingRoundTrip(share) == share)
        #expect(try codingRoundTrip(BeatNotes.Amount.duration(positiveBeats(1, 16))) == .duration(positiveBeats(1, 16)))
    }

    @Test(arguments: [#"{}"#, #"{"portion":1}"#, #"{"share":2}"#])
    func codable_rejectsInvalid(_ json: String) {
        #expect(throws: DecodingError.self) {
            try decodeJSON(BeatNotes.Amount.self, json)
        }
    }

    @Test
    func hashable() {
        #expect(Set([BeatNotes.Amount.share(proportion(1, 2)), .share(proportion(1, 2)), .duration(positiveBeats(1, 8))]).count == 2)
    }

    @Test
    func scaled_scalesOnlyDurations() {
        #expect(BeatNotes.Amount.duration(positiveBeats(1, 16)).scaled(by: 2) == .duration(positiveBeats(1, 8)))
        #expect(BeatNotes.Amount.share(proportion(1, 2)).scaled(by: 2) == .share(proportion(1, 2)))
        #expect(BeatNotes.Amount.duration(positiveBeats(1, 16)).scaled(by: 0) == nil)
    }
}
