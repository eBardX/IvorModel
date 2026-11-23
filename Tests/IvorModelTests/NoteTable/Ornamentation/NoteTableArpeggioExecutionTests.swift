// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableArpeggioExecutionTests {
}

// MARK: -

extension NoteTableArpeggioExecutionTests {
    typealias Execution = BeatNotes.ArpeggioExecution

    @Test
    func codable_omitsNilFields() throws {
        #expect(try encodedJSON(Execution()) == "{}")
        #expect(try encodedJSON(Execution(anchor: .lastOnBeat)) == #"{"anchor":"lastOnBeat"}"#)
        #expect(try codingRoundTrip(Execution(spread: .total(proportion(1, 4)), anchor: .firstOnBeat))
            == Execution(spread: .total(proportion(1, 4)), anchor: .firstOnBeat))
    }

    @Test
    func hashable() {
        #expect(Set([Execution(), Execution(), Execution(anchor: .firstOnBeat)]).count == 2)
    }

    @Test
    func isEmpty() {
        #expect(Execution().isEmpty)
        #expect(!Execution(anchor: .firstOnBeat).isEmpty)
    }

    @Test
    func scaled() {
        let execution = Execution(spread: .perTone(positiveBeats(1, 64)), anchor: .lastOnBeat)

        #expect(execution.scaled(by: 2) == Execution(spread: .perTone(positiveBeats(1, 32)), anchor: .lastOnBeat))
        #expect(execution.scaled(by: 0) == nil)
        #expect(Execution(anchor: .lastOnBeat).scaled(by: 0) == Execution(anchor: .lastOnBeat))
    }
}
