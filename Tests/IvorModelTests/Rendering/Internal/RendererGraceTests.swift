// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererGraceTests {
}

// MARK: -

extension RendererGraceTests {
    private typealias Moment = Renderer<BeatTime, Pitch>.Moment

    @Test
    func applyChordDelays_delaysEveryNoteOfTheChord() throws {
        let ornamentation = try BeatNotes.Ornamentation(graceBefore: graceFigure([.d5], isSlashed: true))
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4, ornamentation),
                                                        WrittenNote(0, frac(1, 2), .e4)])])

        renderer.planGraceFiguresBefore()
        renderer.applyChordDelays()

        #expect(renderer.starts == [frac(1, 64), frac(1, 64)])
    }

    @Test
    func applyChordDelays_withNoDelaysChangesNothing() throws {
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4)])])

        renderer.applyChordDelays()

        #expect(renderer.starts == [0])
    }

    @Test
    func planGraceFiguresAfter_takesTheEndOfTheMainNote() throws {
        let ornamentation = try BeatNotes.Ornamentation(graceAfter: graceFigure([.d4, .e4]))
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4, ornamentation)])])

        renderer.planGraceFiguresAfter()

        let events = renderer.afterEvents[0]

        #expect(renderer.ends == [frac(15, 32)])
        #expect(events.map(\.start) == [frac(15, 32), frac(31, 64)])
        #expect(events.map(\.end) == [frac(31, 64), frac(1, 2)])
        #expect(events.map(\.pitches) == [[.d4], [.e4]])
    }

    @Test
    func planGraceFiguresBefore_appoggiaturaTakesHalfTheMainNote() throws {
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4, BeatNotes.Ornamentation(graceBefore: graceFigure([.d4])))])])

        renderer.planGraceFiguresBefore()

        let events = renderer.beforeEvents[0]

        #expect(events.map(\.start) == [0])
        #expect(events.map(\.end) == [frac(1, 4)])
        #expect(renderer.chordDelays[Moment(part: 0, time: 0)] == frac(1, 4))
        #expect(renderer.starts == [0])
    }

    @Test
    func planGraceFiguresBefore_fromPreviousShortensTheNoteBefore() throws {
        let figure = try graceFigure([.e4], execution: BeatNotes.GraceExecution(fromPrevious: .duration(positiveBeats(1, 16))))
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4),
                                                        WrittenNote(frac(1, 2), frac(1, 2), .d4, BeatNotes.Ornamentation(graceBefore: figure))])])

        renderer.planGraceFiguresBefore()

        #expect(renderer.ends[0] == frac(7, 16))
        #expect(renderer.beforeEvents[1].map(\.start) == [frac(7, 16)])
        #expect(renderer.beforeEvents[1].map(\.end) == [frac(1, 2)])
        #expect((renderer.chordDelays[Moment(part: 0, time: frac(1, 2))] ?? 0) == 0)
    }

    @Test
    func planGraceFiguresBefore_withoutFiguresChangesNothing() throws {
        var renderer = try makeRenderer([renderingPart([WrittenNote(0, frac(1, 2), .c4)])])

        renderer.planGraceFiguresBefore()
        renderer.planGraceFiguresAfter()

        #expect(renderer.beforeEvents[0].isEmpty)
        #expect(renderer.afterEvents[0].isEmpty)
        #expect(renderer.ends == [frac(1, 2)])
        #expect(renderer.starts == [0])
    }
}
