// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableArpeggioTests {
}

// MARK: -

extension NoteTableArpeggioTests {
    typealias Arpeggio = BeatNotes.Arpeggio

    @Test
    func codable_omitsNilFields() throws {
        #expect(try encodedJSON(Arpeggio(group: 1)) == #"{"group":1}"#)
        #expect(try encodedJSON(Arpeggio(group: 2, direction: .down)) == #"{"direction":"down","group":2}"#)
    }

    @Test
    func codable_rejectsGroupZero() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Arpeggio.self, #"{"group":0}"#)
        }
    }

    @Test
    func codable_roundTrip() throws {
        let arpeggio = Arpeggio(group: 3,
                                direction: .up,
                                execution: BeatNotes.ArpeggioExecution(spread: .perTone(positiveBeats(1, 64))))

        #expect(try codingRoundTrip(arpeggio) == arpeggio)
    }

    @Test
    func hashable() {
        #expect(Set([Arpeggio(group: 1), Arpeggio(group: 1), Arpeggio(group: 2)]).count == 2)
    }

    @Test
    func scaled() {
        let arpeggio = Arpeggio(group: 1, execution: BeatNotes.ArpeggioExecution(spread: .perTone(positiveBeats(1, 64))))

        #expect(arpeggio.scaled(by: 2) == Arpeggio(group: 1, execution: BeatNotes.ArpeggioExecution(spread: .perTone(positiveBeats(1, 32)))))
        #expect(arpeggio.scaled(by: 0) == nil)
        #expect(Arpeggio(group: 1, direction: .down).scaled(by: 0) == Arpeggio(group: 1, direction: .down))
    }
}
