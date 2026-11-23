// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableOrnamentExecutionTests {
}

// MARK: -

extension NoteTableOrnamentExecutionTests {
    typealias Execution = BeatNotes.OrnamentExecution

    @Test
    func codable_omitsNilFields() throws {
        #expect(try encodedJSON(Execution()) == "{}")
        #expect(try encodedJSON(Execution(startNote: .partner)) == #"{"startNote":"partner"}"#)
    }

    @Test
    func codable_roundTrip() throws {
        let execution = Execution(startNote: .main,
                                  partnerRule: .halfStep,
                                  rate: .perSecond(12),
                                  extent: .count(1))

        #expect(try codingRoundTrip(execution) == execution)
    }

    @Test
    func hashable() {
        #expect(Set([Execution(), Execution(), Execution(extent: .count(1))]).count == 2)
    }

    @Test
    func isEmpty() {
        #expect(Execution().isEmpty)
        #expect(!Execution(partnerRule: .diatonic).isEmpty)
    }

    @Test
    func scaled() {
        let execution = Execution(startNote: .partner,
                                  rate: .noteValue(positiveBeats(1, 32)),
                                  extent: .span(proportion(1, 2)))

        #expect(execution.scaled(by: 2) == Execution(startNote: .partner,
                                                     rate: .noteValue(positiveBeats(1, 16)),
                                                     extent: .span(proportion(1, 2))))
        #expect(execution.scaled(by: 0) == nil)
        #expect(Execution(startNote: .main).scaled(by: 0) == Execution(startNote: .main))
    }
}
