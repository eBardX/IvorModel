// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
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
    private typealias Ornamentation = BeatNotes.Ornamentation

    @Test
    func extractNoteEvents() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let events = table.extractNoteEvents()

        #expect(events.count == 1)
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
    func quantize_noteIDsRestrictsAffectedNotes() throws {
        var table = NoteTableSB()

        let noteID1 = table.insert(attack: BeatTime(0.49), duration: 1, pitch: .c4)
        let noteID2 = table.insert(attack: BeatTime(4.49), duration: 1, pitch: .d4)

        try table.quantize(to: [1], noteIDs: [noteID1])

        var attacksByID: [NoteID: BeatTime] = [:]

        for note in table {
            attacksByID[note.noteID] = note.attack
        }

        #expect(attacksByID[noteID1] == 0)
        #expect(attacksByID[noteID2] == BeatTime(4.49))
    }

    @Test
    func quantize_passesOrnamentationThrough() throws {
        var table = try c4Table(transformableOrnamentation())

        try table.quantize(using: BeatQuantizer(factors: [4]))

        #expect(try table.first?.ornamentation == transformableOrnamentation())
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

        // 1,000,000 µs = 1 second, which at the default tempo (♩ = 60) is a quarter note.
        table.insert(attack: 1_000_000, duration: 1_000_000, pitch: .c4)

        let result = table.unwarped(using: TempoMap())

        #expect(result.timeRange?.lowerBound == BeatTime(Number(numerator: 1, denominator: 4)))
    }

    @Test
    func unwarped_convertsWrittenLengthsAtTheAttack() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(60))

        var table = NoteTable<WallTime, Pitch>()
        let event = try #require(NoteTable<WallTime, Pitch>.GraceFigure.Event(pitches: [.d5],
                                                                              length: PositiveDuration(wallDuration(250))))
        let figure = try #require(NoteTable<WallTime, Pitch>.GraceFigure(events: [event]))

        try table.insert(attack: wallTime(1_000),
                         duration: 1,
                         pitch: .c4,
                         ornamentation: NoteTable<WallTime, Pitch>.Ornamentation(graceBefore: figure))

        let unwarped = table.unwarped(using: tempoMap)
        let converter = TimeConverter(tempoMap: tempoMap)
        let attack = converter.beatTime(at: wallTime(1_000))
        let expected = converter.beatTime(at: wallTime(1_250)) - attack

        let length = try #require(unwarped.first?.ornamentation?.graceBefore?.events.first?.length)

        //
        // Wall-to-beat conversion goes through floating point, so compare closely, not exactly.
        //
        #expect(abs(length.duration.numberValue.doubleValue - expected.numberValue.doubleValue) < 1e-9)
        #expect(expected.numberValue.doubleValue > 0.06)
    }

    @Test
    func varispeeded_pitchOutOfRange_throws() throws {
        var table = NoteTableFB()
        var tempoMap = TempoMap()
        let lowestPitch = try #require(Frequency(uintValue: 1))

        tempoMap.insert(beatTime: 0, tempo: Tempo(1))
        table.insert(attack: 0, duration: 1, pitch: lowestPitch)

        #expect(throws: NoteTableFB.Error.varispeedFailure(0, 1, lowestPitch, lowestPitch)) {
            try table.varispeeded(using: tempoMap, normalTempo: Tempo(60))
        }
    }

    @Test
    func varispeeded_shiftsGracePitchesByTheirTempo() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(120))
        tempoMap.insert(beatTime: 1, tempo: Tempo(30))

        let event = try #require(NoteTable<BeatTime, Frequency>.GraceFigure.Event(pitches: [Frequency(440)]))
        let figure = try #require(NoteTable<BeatTime, Frequency>.GraceFigure(events: [event]))
        var table = NoteTable<BeatTime, Frequency>()

        try table.insert(attack: 0,
                         duration: 1,
                         pitch: Frequency(440),
                         ornamentation: .init(graceBefore: figure, graceAfter: figure))

        let result = try table.varispeeded(using: tempoMap, normalTempo: Tempo(60))
        let note = try #require(result.first)
        let before = try #require(note.ornamentation?.graceBefore?.pitches.first)
        let after = try #require(note.ornamentation?.graceAfter?.pitches.first)

        //
        // The figure before shifts like the start pitch (up, at 120), the figure after like the
        // end pitch (down, at 30, where the note releases).
        //
        #expect(before == note.startPitch)
        #expect(after == note.endPitch)
        #expect(before.numberValue > 440)
        #expect(after.numberValue < 440)
    }

    @Test
    func varispeeded_tempoAboveNormalShiftsPitchUp() throws {
        var table = NoteTableFB()
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(120))
        table.insert(attack: 0, duration: 1, pitch: Frequency(440))

        let result = try table.varispeeded(using: tempoMap, normalTempo: Tempo(60))
        let pitchRange = try #require(result.pitchRange)

        #expect(pitchRange.lowerBound.numberValue > Frequency(440).numberValue)
    }

    @Test
    func varispeeded_tempoBelowNormalShiftsPitchDown() throws {
        var table = NoteTableFB()
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(30))
        table.insert(attack: 0, duration: 1, pitch: Frequency(440))

        let result = try table.varispeeded(using: tempoMap, normalTempo: Tempo(60))
        let pitchRange = try #require(result.pitchRange)

        #expect(pitchRange.lowerBound.numberValue < Frequency(440).numberValue)
    }

    @Test
    func varispeeded_tempoEqualToNormalPreservesPitch() throws {
        var table = NoteTableFB()

        table.insert(attack: 1, duration: 1, pitch: Frequency(440))

        let result = try table.varispeeded(using: TempoMap())

        // 1 whole note at the default tempo (♩ = 60) is 4 seconds, i.e. 4,000,000 µs.
        #expect(result.pitchRange?.lowerBound == Frequency(440))
        #expect(result.timeRange?.lowerBound == 4_000_000)
    }

    @Test
    func warped_convertsToWallTime() {
        var table = NoteTableSB()

        table.insert(attack: 1, duration: 1, pitch: .c4)

        let result = table.warped(using: TempoMap())

        // 1 whole note at the default tempo (♩ = 60) is 4 seconds, i.e. 4,000,000 µs.
        #expect(result.timeRange?.lowerBound == 4_000_000)
    }

    @Test
    func warped_convertsWrittenLengthsAndGivesMeasuredTremolosARate() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(90))

        let tremolo = try ornament(.tremolo(.measured(TremoloStrokes(uintValue: 2).unsafelyUnwrapped)), .repeat)
        var table = BeatNotes()

        try table.insert(attack: 1,
                         duration: 1,
                         pitch: .c4,
                         ornamentation: Ornamentation(graceBefore: graceFigure([.d5], length: positiveBeats(1, 16)),
                                                      ornament: tremolo))

        let warped = table.warped(using: tempoMap)
        let converter = TimeConverter(tempoMap: tempoMap)
        let attack = converter.wallTime(at: 1)
        let expected = converter.wallTime(at: beatTime(frac(17, 16))) - attack
        let ornamentation = try #require(warped.first?.ornamentation)

        #expect(ornamentation.graceBefore?.events.first?.length == PositiveDuration(expected))
        //
        // Sixteenths: 16 per whole note at 90 quarters per minute is 6 per second.
        //
        #expect(ornamentation.ornament?.execution?.rate == .perSecond(NotesPerSecond(numberValue: 6).unsafelyUnwrapped))
        #expect(ornamentation.ornament?.sign == .tremolo(.measured(TremoloStrokes(uintValue: 2).unsafelyUnwrapped)))
    }
}
