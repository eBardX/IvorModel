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
    func transpose_absolute_flagOffKeepsKeys() throws {
        var work = try makeAbsoluteKeyWork()
        let interval = try DirectedInterval(interval: #require(Ratio(numberValue: frac(7, 4))), direction: .ascending)

        try work.transpose(by: interval, movesKeySignatures: false)

        #expect(work.keySignatureTable?.map(\.keySignature) == [keySignature(2)])
    }

    @Test
    func transpose_absolute_justFifthMovesKeys() throws {
        var work = try makeAbsoluteKeyWork()
        let fifth = try DirectedInterval(interval: #require(Ratio(numberValue: frac(3, 2))), direction: .ascending)

        try work.transpose(by: fifth)

        #expect(work.keySignatureTable?.map(\.keySignature) == [keySignature(3)])
    }

    @Test
    func transpose_absolute_offSemitoneRemovesKeys() throws {
        for ratio in [frac(7, 4), Ratio(cents: 50).numberValue] {
            var work = try makeAbsoluteKeyWork()
            let interval = try DirectedInterval(interval: #require(Ratio(numberValue: ratio)), direction: .ascending)

            try work.transpose(by: interval)

            #expect(work.keySignatureTable?.isEmpty == true)
        }
    }

    @Test
    func transpose_keyboard_movesKeysByKeySteps() throws {
        var work = try Work(content: .keyboardBeat([], TempoMap(), MeterTable(), makeKeySignatureTable([(0, -1)])))
        let up = try DirectedInterval(interval: #require(NoteDistance(uintValue: 1)), direction: .ascending)

        try work.transpose(by: up)

        #expect(work.keySignatureTable?.map(\.keySignature) == [keySignature(-6)])
    }

    @Test
    func transpose_lockedWork_throwsAndLeavesWorkUnchanged() throws {
        var (work, partID) = makeLockedWorkSB()
        let interval = try #require(Pitch.c4.interval(to: .e4))
        let beatTimeRange = work.beatTimeRange

        #expect(throws: Work.Error.workIsLocked) {
            try work.transpose(by: interval, partIDs: [partID])
        }

        #expect(throws: Work.Error.workIsLocked) {
            try work.transpose(by: interval)
        }

        #expect(work.beatTimeRange == beatTimeRange)
        #expect(work.pitchRange?.lowerBound as? Pitch == .c4)
    }

    @Test
    func transpose_standard_flagOffKeepsKeys() throws {
        var work = try makeKeySignatureWork(makeKeySignatureTable([(0, 2)]))

        try work.transpose(by: #require(Pitch.c4.interval(to: .d4)), movesKeySignatures: false)

        #expect(try work.keySignatureTable == makeKeySignatureTable([(0, 2)]))
        #expect(work.pitchRange?.lowerBound as? Pitch == .d4)
    }

    @Test
    func transpose_standard_movesKeysKeepingMode() throws {
        var table = KeySignatureTable()

        try table.insert(beatTime: 0, keySignature: keySignature(-3), extras: modeExtras("minor"))

        var work = makeKeySignatureWork(table)

        try work.transpose(by: #require(Pitch.c4.interval(to: .d4)))

        #expect(work.keySignatureTable?.first?.keySignature == keySignature(-1))
        #expect(work.keySignatureTable?.first?.extras == modeExtras("minor"))
    }

    @Test
    func transpose_wholeWork_transposesEveryPart() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeySignatureTable()))

        let interval = try #require(Pitch.c4.interval(to: .e4))

        try work.transpose(by: interval)

        #expect(work.pitchRange?.lowerBound as? Pitch == .e4)
    }

    @Test
    func transpose_wrongPitchNotationThrows() {
        var work = Work(content: .keyboardBeat([], TempoMap(), MeterTable(), KeySignatureTable()))

        let interval = DirectedInterval(interval: Interval.unison, direction: .same)

        #expect(throws: Work.Error.pitchNotationMismatch(expected: .standard)) {
            try work.transpose(by: interval)
        }
    }
}
