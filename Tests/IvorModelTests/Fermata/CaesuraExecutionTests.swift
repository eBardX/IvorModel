// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct CaesuraExecutionTests {
}

// MARK: -

extension CaesuraExecutionTests {
    typealias Execution = CaesuraExecution<BeatTime>

    @Test
    func codable_roundTrip() throws {
        let execution = Execution(pause: .seconds(positiveSeconds(2)))

        #expect(try codingRoundTrip(execution) == execution)
        #expect(try encodedJSON(Execution()) == "{}")
    }

    @Test
    func hashable() {
        #expect(Set([Execution(), Execution(), Execution(pause: .added(positiveBeats(1)))]).count == 2)
    }

    @Test
    func scaled() {
        #expect(Execution(pause: .added(positiveBeats(1, 4))).scaled(by: 2) == Execution(pause: .added(positiveBeats(1, 2))))
        #expect(Execution(pause: .added(positiveBeats(1, 4))).scaled(by: 0) == nil)
        #expect(Execution().scaled(by: 0) == Execution())
    }
}
