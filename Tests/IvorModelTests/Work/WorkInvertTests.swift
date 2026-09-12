// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkInvertTests {
}

// MARK: -

extension WorkInvertTests {
    @Test
    func invert_wholeWork_invertsEveryPart() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 0, duration: 1, pitch: .e4)

        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.invert(around: nil as ClosedRange<Pitch>?)

        #expect(work.pitchRange != nil)
    }

    @Test
    func invert_wrongPitchNotationThrows() {
        var work = Work(content: .keyboardBeat([], TempoMap()))

        #expect(throws: Work.Error.pitchNotationMismatch(expected: .standard)) {
            try work.invert(around: nil as ClosedRange<Pitch>?)
        }
    }
}
