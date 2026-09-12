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
    private typealias NoteTableFB = NoteTable<BeatTime, Frequency>
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
    func quantize_emptyFactors() {
        var table = NoteTableSB()

        #expect(throws: NoteTableSB.Error.emptyQuantizationFactors) {
            try table.quantize(to: [])
        }
    }

    @Test
    func quantize_invalidFactor() {
        var table = NoteTableSB()

        #expect(throws: NoteTableSB.Error.invalidQuantizationFactor(0)) {
            try table.quantize(to: [0])
        }
        #expect(throws: NoteTableSB.Error.invalidQuantizationFactor(-2)) {
            try table.quantize(to: [-2])
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
    func quantize_collapsedNoteFloorsToGridUnit() throws {
        var table = NoteTableSB()
        let quantizer = try BeatQuantizer(factors: [4])

        table.insert(attack: BeatTime(0.01), duration: BeatDuration(0.02), pitch: .c4)

        table.quantize(using: quantizer)

        let duration = table.notes.first?.duration

        #expect(duration == quantizer.gridUnit)
    }

    @Test
    func quantize_noteIDsRestrictsAffectedNotes() throws {
        var table = NoteTableSB()

        let noteID1 = table.insert(attack: BeatTime(0.49), duration: 1, pitch: .c4)
        let noteID2 = table.insert(attack: BeatTime(4.49), duration: 1, pitch: .d4)

        try table.quantize(to: [1], noteIDs: [noteID1])

        var attacksByID: [NoteTableSB.NoteID: BeatTime] = [:]

        table.forEach { noteID, attack, _, _, _, _ in
            attacksByID[noteID] = attack
        }

        #expect(attacksByID[noteID1] == 0)
        #expect(attacksByID[noteID2] == BeatTime(4.49))
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
    func varispeeded_tempoAboveNormalShiftsPitchUp() throws {
        var table = NoteTableFB()
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(120))
        table.insert(attack: 0, duration: 1, pitch: Frequency(440))

        let result = table.varispeeded(using: tempoMap, normalTempo: Tempo(60))
        let pitchRange = try #require(result.pitchRange)

        #expect(pitchRange.lowerBound.numberValue > Frequency(440).numberValue)
    }

    @Test
    func varispeeded_tempoBelowNormalShiftsPitchDown() throws {
        var table = NoteTableFB()
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(30))
        table.insert(attack: 0, duration: 1, pitch: Frequency(440))

        let result = table.varispeeded(using: tempoMap, normalTempo: Tempo(60))
        let pitchRange = try #require(result.pitchRange)

        #expect(pitchRange.lowerBound.numberValue < Frequency(440).numberValue)
    }

    @Test
    func varispeeded_tempoEqualToNormalPreservesPitch() {
        var table = NoteTableFB()

        table.insert(attack: 1, duration: 1, pitch: Frequency(440))

        let result = table.varispeeded(using: TempoMap())

        // 1 beat at the default tempo (60 BPM) is 1 second, i.e. 1000 ms.
        #expect(result.pitchRange?.lowerBound == Frequency(440))
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
