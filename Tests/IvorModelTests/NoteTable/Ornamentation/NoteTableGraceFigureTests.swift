// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableGraceFigureTests {
}

// MARK: -

extension NoteTableGraceFigureTests {
    typealias Figure = BeatNotes.GraceFigure

    @Test
    func codable_omitsFalseFlagsAndNilExecution() throws {
        let figure = try graceFigure(["D5"])
        let json = try encodedJSON(figure)
        let events = try encodedJSON(figure.events)

        #expect(json == #"{"events":"# + events + "}")
        #expect(try codingRoundTrip(figure) == figure)
    }

    @Test
    func codable_rejectsNoEvents() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Figure.self, #"{"events":[]}"#)
        }
    }

    @Test
    func codable_roundTrip_withEverything() throws {
        let figure = try graceFigure(["D5", "E5"],
                                     length: positiveBeats(1, 16),
                                     isSlashed: true,
                                     isTiedToMainNote: true,
                                     execution: BeatNotes.GraceExecution(fromPrevious: .share(proportion(1, 2))))
        let json = try encodedJSON(figure)

        #expect(json.contains(#""slashed":true"#))
        #expect(json.contains(#""tied":true"#))
        #expect(try codingRoundTrip(figure) == figure)
    }

    @Test
    func hashable() throws {
        #expect(try Set([graceFigure(["D5"]), graceFigure(["D5"]), graceFigure(["D5"], isSlashed: true)]).count == 2)
    }

    @Test
    func init_requiresEvents() throws {
        #expect(Figure(events: []) == nil)
        #expect(try Figure(events: [graceEvent(["D5"])])?.isSlashed == false)
        #expect(try Figure(events: [graceEvent(["D5"])])?.isTiedToMainNote == false)
    }

    @Test
    func mapPitches() throws {
        let figure = try graceFigure(["C4", "G4"], isSlashed: true)

        #expect(try figure.mapPitches(swapCAndG) == graceFigure(["G4", "C4"], isSlashed: true))
    }

    @Test
    func pitches_areInPlayingOrder() throws {
        let figure = try #require(Figure(events: [graceEvent(["E4"]), graceEvent(["C4", "G4"])]))

        #expect(figure.pitches == ["E4", "C4", "G4"])
    }

    @Test
    func reversed_reversesEventsAndKeepsExecutions() throws {
        let execution = BeatNotes.GraceExecution(fromPrevious: .share(proportion(1, 4)))
        let figure = try #require(Figure(events: [graceEvent(["C4"], execution: execution), graceEvent(["D4"])],
                                         isSlashed: true,
                                         isTiedToMainNote: true,
                                         execution: execution))
        let reversed = figure.reversed()

        #expect(reversed.pitches == ["D4", "C4"])
        #expect(reversed.events.last?.execution == execution)
        #expect(reversed.execution == execution)
        #expect(reversed.isSlashed)
        #expect(reversed.isTiedToMainNote)
        #expect(reversed.reversed() == figure)
    }

    @Test
    func scaled() throws {
        let figure = try graceFigure(["C4", "D4"], length: positiveBeats(1, 16))

        #expect(try figure.scaled(by: 2) == graceFigure(["C4", "D4"], length: positiveBeats(1, 8)))
        #expect(figure.scaled(by: 0) == nil)
    }
}
