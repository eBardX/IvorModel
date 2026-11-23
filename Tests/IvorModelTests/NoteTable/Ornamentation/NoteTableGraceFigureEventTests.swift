// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableGraceFigureEventTests {
}

// MARK: -

extension NoteTableGraceFigureEventTests {
    typealias Event = BeatNotes.GraceFigure.Event

    @Test
    func codable_isPositional() throws {
        let plain = try graceEvent(["D5"])
        let full = try graceEvent(["C4", "E4"],
                                  length: positiveBeats(1, 16),
                                  execution: BeatNotes.GraceExecution(fromMain: .share(proportion(1, 2))))
        let executionOnly = try graceEvent(["D5"],
                                           execution: BeatNotes.GraceExecution(fromMain: .share(proportion(1, 2))))

        #expect(try encodedJSON(plain) == "[" + encodedJSON([Pitch("D5")]) + "]")
        #expect(try encodedJSON(executionOnly).contains(",null,"))

        for event in [plain, full, executionOnly] {
            #expect(try codingRoundTrip(event) == event)
        }
    }

    @Test
    func codable_rejectsInvalidPitches() throws {
        for pitches: [Pitch] in [[], ["E4", "C4"], ["C4", "C4"]] {
            let json = try "[" + encodedJSON(pitches) + "]"

            #expect(throws: DecodingError.self) {
                try decodeJSON(Event.self, json)
            }
        }
    }

    @Test
    func hashable() throws {
        #expect(try Set([graceEvent(["C4"]), graceEvent(["C4"]), graceEvent(["D4"])]).count == 2)
    }

    @Test
    func init_requiresANonEmptySortedUniquePitchSet() {
        #expect(Event(pitches: []) == nil)
        #expect(Event(pitches: ["E4", "C4"]) == nil)
        #expect(Event(pitches: ["C4", "C4"]) == nil)
        #expect(Event(pitches: ["C4", "E4"])?.pitches == ["C4", "E4"])
    }

    @Test
    func mapPitches_sortsAndRemovesDuplicates() throws {
        let event = try graceEvent(["C4", "E4", "G4"], length: positiveBeats(1, 8))

        #expect(try event.mapPitches(swapCAndG) == graceEvent(["C4", "E4", "G4"], length: positiveBeats(1, 8)))
        #expect(event.mapPitches { _ in "D4" }.pitches == ["D4"])
        #expect(event.mapPitches { _ in "D4" }.length == positiveBeats(1, 8))
    }

    @Test
    func scaled() throws {
        let event = try graceEvent(["C4"],
                                   length: positiveBeats(1, 16),
                                   execution: BeatNotes.GraceExecution(fromMain: .duration(positiveBeats(1, 32))))

        #expect(try event.scaled(by: 2) == graceEvent(["C4"],
                                                      length: positiveBeats(1, 8),
                                                      execution: BeatNotes.GraceExecution(fromMain: .duration(positiveBeats(1, 16)))))
        #expect(event.scaled(by: 0) == nil)
        #expect(try graceEvent(["C4"]).scaled(by: 0) == graceEvent(["C4"]))
    }
}
