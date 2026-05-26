// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct WorkContentTests {
}

// MARK: -

extension WorkContentTests {
    @Test
    func partCount_empty() {
        let content = Work.Content.standardBeat([], TempoMap())

        #expect(content.partCount == 0)
    }

    @Test
    func partCount_nonEmpty() {
        let part = Part<BeatTime, Pitch>(name: "Piano")
        let content = Work.Content.standardBeat([part], TempoMap())

        #expect(content.partCount == 1)
    }

    @Test
    func partName() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        let content = Work.Content.standardBeat([part], TempoMap())

        #expect(content.partName(at: 0) == "Violin")
    }

    @Test
    func pitchNotation_absolute() {
        let content = Work.Content.absoluteWall([])

        #expect(content.pitchNotation == .absolute)
    }

    @Test
    func pitchNotation_keyboard() {
        let content = Work.Content.keyboardWall([])

        #expect(content.pitchNotation == .keyboard)
    }

    @Test
    func pitchNotation_standard() {
        let content = Work.Content.standardBeat([], TempoMap())

        #expect(content.pitchNotation == .standard)
    }

    @Test
    func tempoMap_beat() {
        let content = Work.Content.standardBeat([], TempoMap())

        #expect(content.tempoMap != nil)
    }

    @Test
    func tempoMap_wall() {
        let content = Work.Content.standardWall([])

        #expect(content.tempoMap == nil)
    }

    @Test
    func timeBasis_beat() {
        let content = Work.Content.standardBeat([], TempoMap())

        #expect(content.timeBasis == .beat)
    }

    @Test
    func timeBasis_wall() {
        let content = Work.Content.standardWall([])

        #expect(content.timeBasis == .wall)
    }
}
