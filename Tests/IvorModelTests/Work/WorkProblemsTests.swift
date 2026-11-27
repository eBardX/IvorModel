// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

// `Work.problems()`, and turning fermata holds into time on conversion.
struct WorkProblemsTests {
}

// MARK: -

extension WorkProblemsTests {
    private typealias Ornamentation = BeatNotes.Ornamentation

    @Test
    func ambiguousHoldSpan() throws {
        let held = try renderingPart([WrittenNote(0, 1, .c4, Ornamentation(fermata: Fermata()))])
        let moving = try renderingPart([WrittenNote(0, frac(1, 2), .e4), WrittenNote(frac(1, 2), frac(1, 2), .f4)])
        let problems = renderingWork([held, moving]).problems()
        let noteID = try #require(held.strands[0].noteTable.first?.noteID)

        #expect(problems == [Work.Problem(severity: .warning, kind: .ambiguousHoldSpan, partIndex: 0, noteID: noteID, time: .beat(0))])
    }

    @Test
    func appliesFermataHolds_convertsTheHoldsAndDropsTheSigns() throws {
        var part = try renderingPart([WrittenNote(0, frac(1, 2), .c4, Ornamentation(fermata: Fermata())),
                                      WrittenNote(frac(1, 2), frac(1, 2), .d4)])

        part.markTable.insert(time: 1, mark: .caesura(nil))

        let work = renderingWork([part])
        let kept = try #require(try work.convert(timeBasis: .wall, pitchNotation: .standard))
        let applied = try #require(try work.convert(timeBasis: .wall, pitchNotation: .standard, appliesFermataHolds: true))
        let warped = try #require(work.warped(appliesFermataHolds: true))

        guard case let .standardWall(keptParts) = kept.content.cases,
              case let .standardWall(appliedParts) = applied.content.cases,
              case let .standardWall(warpedParts) = warped.content.cases
        else { Issue.record("Expected standard wall content"); return }

        //
        // Kept: the C4 lasts 2 seconds and keeps its fermata, and the caesura stays. Applied: the
        // C4 lasts 4 seconds, and the signs are gone.
        //
        #expect(keptParts.first?.strands[0].noteTable.map(\.duration) == [wallDuration(2_000), wallDuration(2_000)])
        #expect(keptParts.first?.strands[0].noteTable.hasOrnamentation ?? false)
        #expect(keptParts.first?.markTable.count == 1)
        #expect(appliedParts.first?.strands[0].noteTable.map(\.attack) == [wallTime(0), wallTime(4_000)])
        #expect(!(appliedParts.first?.strands[0].noteTable.hasOrnamentation ?? true))
        #expect(appliedParts.first?.markTable.isEmpty ?? false)
        #expect(warpedParts.first?.strands[0].noteTable.map(\.attack) == [wallTime(0), wallTime(4_000)])
    }

    @Test
    func conflictingArpeggio() throws {
        let part = try renderingPart([WrittenNote(0, frac(1, 4), .c4, Ornamentation(arpeggio: BeatNotes.Arpeggio(group: 1, direction: .up))),
                                      WrittenNote(0, frac(1, 4), .e4, Ornamentation(arpeggio: BeatNotes.Arpeggio(group: 1, direction: .down))),
                                      WrittenNote(0, frac(1, 4), .g4, Ornamentation(arpeggio: BeatNotes.Arpeggio(group: 2, direction: .down)))])

        #expect(renderingWork([part]).problems() == [Work.Problem(severity: .error, kind: .conflictingArpeggio, time: .beat(0))])
    }

    @Test
    func conflictingHolds() throws {
        let explicit = { (stretch: Int) in
            let hold = FermataExecution<BeatTime>.Hold.stretch(FermataStretch(numberValue: Number(stretch)).unsafelyUnwrapped)

            return Ornamentation(fermata: Fermata(execution: FermataExecution(hold: hold)))
        }
        let explicitParts = try [renderingPart([WrittenNote(0, frac(1, 2), .c4, explicit(2))]),
                                 renderingPart([WrittenNote(0, frac(1, 2), .e4, explicit(3))])]
        let defaultParts = try [renderingPart([WrittenNote(0, frac(1, 2), .c4, Ornamentation(fermata: Fermata()))]),
                                renderingPart([WrittenNote(0, frac(1, 2), .e4, Ornamentation(fermata: Fermata(shape: .long)))])]
        let agreeingParts = try [renderingPart([WrittenNote(0, frac(1, 2), .c4, Ornamentation(fermata: Fermata()))]),
                                 renderingPart([WrittenNote(0, frac(1, 2), .e4, explicit(2))])]

        #expect(renderingWork(explicitParts).problems() == [Work.Problem(severity: .error, kind: .conflictingExplicitHolds, time: .beat(0))])
        #expect(renderingWork(defaultParts).problems() == [Work.Problem(severity: .warning, kind: .conflictingDefaultHolds, time: .beat(0))])
        #expect(renderingWork(agreeingParts).problems().isEmpty)
    }

    @Test
    func noProblems() throws {
        #expect(try renderingWork([renderingPart([WrittenNote(0, 1, .c4, Ornamentation(graceBefore: graceFigure([.d4]), fermata: Fermata()))])])
            .problems()
            .isEmpty)
    }

    @Test
    func unorderedGraceAmounts() throws {
        let inside = BeatNotes.GraceExecution(fromMain: .duration(positiveBeats(1, 32)))
        let outside = BeatNotes.GraceExecution(fromPrevious: .duration(positiveBeats(1, 32)))
        let unordered = try #require(BeatNotes.GraceFigure(events: [graceEvent([.d4], execution: inside), graceEvent([.e4], execution: outside)]))
        let ordered = try #require(BeatNotes.GraceFigure(events: [graceEvent([.d4], execution: outside), graceEvent([.e4], execution: inside)]))
        let part = try renderingPart([WrittenNote(0, frac(1, 2), .c4, Ornamentation(graceBefore: ordered)),
                                      WrittenNote(frac(1, 2), frac(1, 2), .c4, Ornamentation(graceBefore: unordered)),
                                      WrittenNote(1, frac(1, 2), .c4, Ornamentation(graceAfter: ordered))])
        let problems = renderingWork([part]).problems()

        //
        // Before a note the outside event must come first; after it, last.
        //
        #expect(problems.map(\.kind) == [.unorderedGraceAmounts, .unorderedGraceAmounts])
        #expect(problems.map(\.time) == [.beat(beatTime(frac(1, 2))), .beat(1)])
    }
}
