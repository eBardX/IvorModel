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
