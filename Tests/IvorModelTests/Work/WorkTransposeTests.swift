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

        try work.transpose(by: interval, movesKeys: false)

        #expect(work.keyTable?.map(\.key) == [key(2)])
    }

    @Test
    func transpose_absolute_justFifthMovesKeys() throws {
        var work = try makeAbsoluteKeyWork()
        let fifth = try DirectedInterval(interval: #require(Ratio(numberValue: frac(3, 2))), direction: .ascending)

        try work.transpose(by: fifth)

        #expect(work.keyTable?.map(\.key) == [key(3)])
    }

    @Test
    func transpose_absolute_offSemitoneRemovesKeys() throws {
        for ratio in [frac(7, 4), Ratio(cents: 50).numberValue] {
            var work = try makeAbsoluteKeyWork()
            let interval = try DirectedInterval(interval: #require(Ratio(numberValue: ratio)), direction: .ascending)

            try work.transpose(by: interval)

            #expect(work.keyTable?.isEmpty == true)
        }
    }

    @Test
    func transpose_keyboard_movesKeysByKeySteps() throws {
        var work = try Work(content: .keyboardBeat([], TempoMap(), MeterTable(), makeKeyTable([(0, -1)])))
        let up = try DirectedInterval(interval: #require(NoteDistance(uintValue: 1)), direction: .ascending)

        try work.transpose(by: up)

        #expect(work.keyTable?.map(\.key) == [key(-6)])
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
        var work = try makeKeyWork(makeKeyTable([(0, 2)]))

        try work.transpose(by: #require(Pitch.c4.interval(to: .d4)), movesKeys: false)

        #expect(try work.keyTable == makeKeyTable([(0, 2)]))
        #expect(work.pitchRange?.lowerBound as? Pitch == .d4)
    }

    @Test
    func transpose_standard_movesKeysKeepingMode() throws {
        var table = KeyTable()

        try table.insert(beatTime: 0, key: key(-3), extras: sampleExtras("minor"))

        var work = makeKeyWork(table)

        try work.transpose(by: #require(Pitch.c4.interval(to: .d4)))

        #expect(work.keyTable?.first?.key == key(-1))
        #expect(work.keyTable?.first?.extras == sampleExtras("minor"))
    }

    @Test
    func transpose_wholeWork_transposesEveryPart() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.strands[0].noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        let interval = try #require(Pitch.c4.interval(to: .e4))

        try work.transpose(by: interval)

        #expect(work.pitchRange?.lowerBound as? Pitch == .e4)
    }

    @Test
    func transpose_wrongPitchNotationThrows() {
        var work = Work(content: .keyboardBeat([], TempoMap(), MeterTable(), KeyTable()))

        let interval = DirectedInterval(interval: Interval.unison, direction: .same)

        #expect(throws: Work.Error.pitchNotationMismatch(expected: .standard)) {
            try work.transpose(by: interval)
        }
    }
}
