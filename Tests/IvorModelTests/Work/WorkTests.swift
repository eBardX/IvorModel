// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct WorkTests {
}

// MARK: -

extension WorkTests {
    @Test
    func comparable() {
        let alpha = Work(name: "Alpha")
        let beta  = Work(name: "Beta")

        #expect(alpha < beta)
        #expect(!(beta < alpha))
    }

    @Test
    func currentVersion() {
        #expect(Work.currentVersion == 1)
    }

    @Test
    func duplicated() {
        let part = Part<BeatTime, Pitch>(name: "Viola")
        let original = Work(name: "Quartet", content: .standardBeat([part], TempoMap()))
        let duplicate = original.duplicated()

        #expect(duplicate.workID != original.workID)
        #expect(duplicate.name == original.name)
        #expect(duplicate.partCount == original.partCount)
        #expect(duplicate.partName(at: 0) == original.partName(at: 0))
    }

    @Test
    func duplicated_ofLockedWork_isUnlocked() {
        var original = Work(name: "Quartet")

        original.isLocked = true

        #expect(!original.duplicated().isLocked)
    }

    @Test
    func equality() {
        let work = Work(name: "My Work")

        #expect(work == work)   // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality() {
        let work1 = Work(name: "My Work")
        let work2 = Work(name: "My Work")

        #expect(work1 != work2)
    }

    @Test
    func init_defaults() {
        let work = Work()

        #expect(work.name.isEmpty)
        #expect(work.version == Work.currentVersion)
    }

    @Test
    func init_name() {
        let work = Work(name: "Symphony No. 1")

        #expect(work.name == "Symphony No. 1")
        #expect(work.version == Work.currentVersion)
    }

    @Test
    func isLocked_default() {
        let work = Work()

        #expect(!work.isLocked)
    }

    //
    // This type's `name` setter has no locked-check of its own — see `isLocked`'s doc comment —
    // so renaming a locked work here succeeds; it's `ProjectDocument` that's expected to refuse
    // to rename (or delete) a locked work before ever reaching this setter.
    //

    @Test
    func isLocked_nameSetterHasNoGuard() {
        var work = Work(name: "Original")

        work.isLocked = true
        work.name = "Renamed"

        #expect(work.name == "Renamed")
    }

    //
    // `content`'s setter traps (via `precondition`) rather than silently discarding an assignment
    // to a locked work's content — see its doc comment. A `precondition` failure aborts the test
    // process, so that contract isn't exercisable from here; `isLocked_unlockingAllowsContentAssignment`
    // below covers the unlocked-write path instead.
    //

    @Test
    func isLocked_unlockingAllowsContentAssignment() {
        var work = Work(content: .standardWall([]))
        let part = Part<WallTime, Pitch>(name: "Cello")

        work.isLocked = true
        work.isLocked = false
        work.content = .standardWall([part])

        #expect(work.partCount == 1)
    }

    @Test
    func partCount_empty() {
        let work = Work(content: .standardBeat([], TempoMap()))

        #expect(work.partCount == 0)
    }

    @Test
    func partCount_nonEmpty() {
        let part = Part<BeatTime, Pitch>(name: "Piano")
        let work = Work(content: .standardBeat([part], TempoMap()))

        #expect(work.partCount == 1)
    }

    @Test
    func partName() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        let work = Work(content: .standardBeat([part], TempoMap()))

        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func pitchNotation_absolute() {
        let work = Work(content: .absoluteWall([]))

        #expect(work.pitchNotation == .absolute)
    }

    @Test
    func pitchNotation_keyboard() {
        let work = Work(content: .keyboardWall([]))

        #expect(work.pitchNotation == .keyboard)
    }

    @Test
    func pitchNotation_standard() {
        let work = Work(content: .standardBeat([], TempoMap()))

        #expect(work.pitchNotation == .standard)
    }

    @Test
    func tempoMap_beat() {
        let work = Work(content: .standardBeat([], TempoMap()))

        #expect(work.tempoMap != nil)
    }

    @Test
    func tempoMap_wall() {
        let work = Work(content: .standardWall([]))

        #expect(work.tempoMap == nil)
    }

    @Test
    func timeBasis_beat() {
        let work = Work(content: .standardBeat([], TempoMap()))

        #expect(work.timeBasis == .beat)
    }

    @Test
    func timeBasis_wall() {
        let work = Work(content: .standardWall([]))

        #expect(work.timeBasis == .wall)
    }
}
