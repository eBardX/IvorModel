// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableAdvancedTests {
}

// MARK: -

extension NoteTableAdvancedTests {
    private typealias NoteTableSB = NoteTable<BeatTime, Pitch>
    private typealias NoteTableSW = NoteTable<WallTime, Pitch>

    @Test
    func extractNoteEvents() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let events = table.extractNoteEvents()

        #expect(events.count == 1)
    }

    @Test
    func quantize_invalidFactors() {
        var table = NoteTableSB()

        #expect(throws: (any Error).self) {
            try table.quantize(to: [])
        }
    }

    @Test
    func quantize_snapsToGrid() throws {
        var table = NoteTableSB()

        table.insert(attack: BeatTime(0.49), duration: 1, pitch: .c4)

        try table.quantize(to: [1])

        #expect(table.timeRange?.lowerBound == 0)
    }

    @Test
    func unwarped_convertsToBeatTime() {
        var table = NoteTableSW()

        // 1000 ms = 1 second, which at the default tempo (60 BPM) is 1 beat.
        table.insert(attack: 1_000, duration: 1_000, pitch: .c4)

        let result = table.unwarped(using: TempoMap())

        #expect(result.timeRange?.lowerBound == 1)
    }

    @Test
    func varispeeded_preservesPitches() {
        var table = NoteTableSB()

        table.insert(attack: 1, duration: 1, pitch: .c4)

        let result = table.varispeeded(using: TempoMap())

        // 1 beat at the default tempo (60 BPM) is 1 second, i.e. 1000 ms.
        #expect(result.pitchRange?.lowerBound == .c4)
        #expect(result.timeRange?.lowerBound == 1_000)
    }

    @Test
    func warped_convertsToWallTime() {
        var table = NoteTableSB()

        table.insert(attack: 1, duration: 1, pitch: .c4)

        let result = table.warped(using: TempoMap())

        // 1 beat at the default tempo (60 BPM) is 1 second, i.e. 1000 ms.
        #expect(result.timeRange?.lowerBound == 1_000)
    }
}
