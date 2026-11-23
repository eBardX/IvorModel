// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct FermataExecutionTests {
}

// MARK: -

extension FermataExecutionTests {
    typealias Execution = FermataExecution<BeatTime>

    @Test
    func codable_omitsNilFields() throws {
        #expect(try encodedJSON(Execution()) == "{}")
        #expect(try encodedJSON(Execution(isPlayed: false)) == #"{"isPlayed":false}"#)
    }

    @Test
    func codable_roundTrip() throws {
        let execution = Execution(hold: .stretch(FermataStretch(2)),
                                  pauseAfter: .seconds(positiveSeconds(1)),
                                  isPlayed: true)

        #expect(try codingRoundTrip(execution) == execution)
    }

    @Test
    func hashable() {
        #expect(Set([Execution(isPlayed: true), Execution(isPlayed: true), Execution()]).count == 2)
    }

    @Test
    func isEmpty() {
        #expect(Execution().isEmpty)
        #expect(!Execution(isPlayed: false).isEmpty)
        #expect(!Execution(pauseAfter: .seconds(positiveSeconds(1))).isEmpty)
    }

    @Test
    func scaled() {
        let execution = Execution(hold: .added(positiveBeats(1, 4)),
                                  pauseAfter: .added(positiveBeats(1, 8)),
                                  isPlayed: true)

        #expect(execution.scaled(by: 2) == Execution(hold: .added(positiveBeats(1, 2)),
                                                     pauseAfter: .added(positiveBeats(1, 4)),
                                                     isPlayed: true))
        #expect(execution.scaled(by: 0) == nil)
        #expect(Execution().scaled(by: 0) == Execution())
    }
}
