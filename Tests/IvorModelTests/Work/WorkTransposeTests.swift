// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkTransposeTests {
}

// MARK: -

extension WorkTransposeTests {
    @Test
    func transpose_wholeWork_transposesEveryPart() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var work = Work(content: .standardBeat([part], TempoMap()))

        let interval = try #require(Pitch.c4.interval(to: .e4))

        try work.transpose(by: interval)

        #expect(work.pitchRange?.lowerBound as? Pitch == .e4)
    }

    @Test
    func transpose_wrongPitchNotationThrows() {
        var work = Work(content: .keyboardBeat([], TempoMap()))

        let interval = DirectedInterval(interval: Interval.unison, direction: .same)

        #expect(throws: Work.Error.pitchNotationMismatch(expected: .standard)) {
            try work.transpose(by: interval)
        }
    }
}
