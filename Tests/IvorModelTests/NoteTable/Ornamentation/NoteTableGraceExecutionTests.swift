// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableGraceExecutionTests {
}

// MARK: -

extension NoteTableGraceExecutionTests {
    typealias Execution = BeatNotes.GraceExecution

    @Test
    func codable_omitsNilFields() throws {
        #expect(try encodedJSON(Execution()) == "{}")
        #expect(try codingRoundTrip(Execution(fromPrevious: .share(proportion(1, 4)))) == Execution(fromPrevious: .share(proportion(1, 4))))
    }

    @Test
    func hashable() {
        #expect(Set([Execution(), Execution(), Execution(fromMain: .share(proportion(1, 2)))]).count == 2)
    }

    @Test
    func isEmpty() {
        #expect(Execution().isEmpty)
        #expect(!Execution(fromMain: .share(proportion(1, 2))).isEmpty)
    }

    @Test
    func scaled() {
        let execution = Execution(fromPrevious: .share(proportion(1, 4)),
                                  fromMain: .duration(positiveBeats(1, 8)))

        #expect(execution.scaled(by: 2) == Execution(fromPrevious: .share(proportion(1, 4)),
                                                     fromMain: .duration(positiveBeats(1, 4))))
        #expect(execution.scaled(by: 0) == nil)
    }
}
