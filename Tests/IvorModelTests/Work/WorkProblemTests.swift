// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct WorkProblemTests {
}

// MARK: -

extension WorkProblemTests {
    @Test
    func equality() {
        let noteID = NoteID()

        let problem = Work.Problem(severity: .warning, kind: .ambiguousHoldSpan, partIndex: 1, noteID: noteID, time: .beat(beatTime(2)))

        #expect(problem == Work.Problem(severity: .warning, kind: .ambiguousHoldSpan, partIndex: 1, noteID: noteID, time: .beat(beatTime(2))))
    }

    @Test
    func hashable() {
        let problems: Set = [Work.Problem(severity: .error, kind: .conflictingArpeggio),
                             Work.Problem(severity: .error, kind: .conflictingArpeggio),
                             Work.Problem(severity: .warning, kind: .conflictingArpeggio)]

        #expect(problems.count == 2)
    }

    @Test
    func inequality_differentKind() {
        #expect(Work.Problem(severity: .error, kind: .conflictingDefaultHolds)
            != Work.Problem(severity: .error, kind: .conflictingExplicitHolds))
    }

    @Test
    func inequality_differentPlace() {
        #expect(Work.Problem(severity: .error, kind: .conflictingArpeggio, partIndex: 0)
            != Work.Problem(severity: .error, kind: .conflictingArpeggio, partIndex: 1))
    }

    @Test
    func init_defaultsToNoPlace() {
        let problem = Work.Problem(severity: .error, kind: .unorderedGraceAmounts)

        #expect(problem.kind == .unorderedGraceAmounts)
        #expect(problem.noteID == nil)
        #expect(problem.partIndex == nil)
        #expect(problem.severity == .error)
        #expect(problem.time == nil)
    }

    @Test
    func init_storesEveryField() {
        let noteID = NoteID()
        let problem = Work.Problem(severity: .warning,
                                   kind: .ambiguousHoldSpan,
                                   partIndex: 2,
                                   noteID: noteID,
                                   time: .wall(wallTime(250)))

        #expect(problem.kind == .ambiguousHoldSpan)
        #expect(problem.noteID == noteID)
        #expect(problem.partIndex == 2)
        #expect(problem.severity == .warning)
        #expect(problem.time == .wall(wallTime(250)))
    }
}
