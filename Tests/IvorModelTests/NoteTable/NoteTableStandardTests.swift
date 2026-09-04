// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableStandardTests {
}

// MARK: -

extension NoteTableStandardTests {
    private typealias NoteTableSB = NoteTable<BeatTime, Pitch>

    @Test
    func augment_invalidFactor() {
        var table = NoteTableSB()

        #expect(throws: NoteTableSB.Error.self) {
            try table.augment(by: Number(0))
        }
    }

    @Test
    func augment_scalesTimings() throws {
        var table = NoteTableSB()

        table.insert(attack: 1, duration: 1, pitch: .c4)

        try table.augment(by: Number(2))

        #expect(table.timeRange?.upperBound == 3)
    }

    @Test
    func diminish_invalidFactor() {
        var table = NoteTableSB()

        #expect(throws: NoteTableSB.Error.self) {
            try table.diminish(by: Number(0))
        }
    }

    @Test
    func diminish_scalesTimings() throws {
        var table = NoteTableSB()

        table.insert(attack: 2, duration: 2, pitch: .c4)

        try table.diminish(by: Number(2))

        #expect(table.timeRange?.upperBound == 3)
    }

    @Test
    func invert_preservesPitchRange() throws {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        let originalRange = table.pitchRange

        try table.invert()

        #expect(table.pitchRange == originalRange)
    }

    @Test
    func move_shiftsAttackTimes() throws {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try table.move(by: directedDuration)

        #expect(table.timeRange?.lowerBound == 2)
    }

    @Test
    func reverse_swapsGlidePitches() throws {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4)

        let originalTimeRange = table.timeRange

        try table.reverse()

        var swapped = false

        table.forEach { _, _, _, startPitch, endPitch, _ in
            swapped = (startPitch == .e4 && endPitch == .c4)
        }

        #expect(table.timeRange == originalTimeRange)
        #expect(swapped)
    }

    @Test
    func transpose_shiftsPitches() throws {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let interval = try #require(Pitch.c4.interval(to: .e4))

        try table.transpose(by: interval)

        #expect(table.pitchRange?.lowerBound == .e4)
    }
}
