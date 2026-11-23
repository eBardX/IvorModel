// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PositiveDurationTests {
}

// MARK: -

extension PositiveDurationTests {
    @Test
    func codable_encodesTheDuration() throws {
        #expect(try encodedJSON(positiveBeats(1, 8)) == encodedJSON(beats(frac(1, 8))))
        #expect(try codingRoundTrip(positiveBeats(1, 8)) == positiveBeats(1, 8))
        #expect(try codingRoundTrip(positiveSeconds(3, 2)) == positiveSeconds(3, 2))
    }

    @Test
    func codable_rejectsZero() throws {
        let data = try JSONEncoder().encode(BeatDuration.zero)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PositiveDuration<BeatDuration>.self, from: data)
        }
    }

    @Test
    func hashable() {
        #expect(Set([positiveBeats(1, 4), positiveBeats(1, 4), positiveBeats(1, 8)]).count == 2)
    }

    @Test
    func init_rejectsZero() {
        #expect(PositiveDuration(BeatDuration.zero) == nil)
        #expect(PositiveDuration(beats(frac(1, 4)))?.duration == beats(frac(1, 4)))
        #expect(!PositiveDuration.isValid(BeatDuration.zero))
    }

    @Test
    func scaled() {
        #expect(positiveBeats(1, 8).scaled(by: 2) == positiveBeats(1, 4))
        #expect(positiveBeats(1, 8).scaled(by: frac(1, 2)) == positiveBeats(1, 16))
        #expect(positiveBeats(1, 8).scaled(by: 0) == nil)
    }
}
