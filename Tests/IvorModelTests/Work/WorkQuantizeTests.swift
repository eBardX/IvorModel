// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkQuantizeTests {
}

// MARK: -

extension WorkQuantizeTests {
    @Test
    func quantize_wholeWork_absoluteBeat_snapsEveryPart() throws {
        var part = Part<BeatTime, Frequency>(name: "Violin")

        part.noteTable.insert(attack: BeatTime(0.49), duration: 1, pitch: Frequency(440))

        var work = Work(content: .absoluteBeat([part], TempoMap()))

        try work.quantize(to: [1])

        #expect(work.beatTimeRange?.lowerBound == 0)
    }

    @Test
    func quantize_wholeWork_keyboardBeat_snapsEveryPart() throws {
        var part = Part<BeatTime, NoteNumber>(name: "Violin")

        part.noteTable.insert(attack: BeatTime(0.49), duration: 1, pitch: NoteNumber(60))

        var work = Work(content: .keyboardBeat([part], TempoMap()))

        try work.quantize(to: [1])

        #expect(work.beatTimeRange?.lowerBound == 0)
    }

    @Test
    func quantize_wholeWork_standardBeat_snapsEveryPart() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: BeatTime(0.49), duration: 1, pitch: .c4)

        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.quantize(to: [1])

        #expect(work.beatTimeRange?.lowerBound == 0)
    }

    @Test
    func quantize_singlePart_snapsOnlyThatPart() throws {
        var part1 = Part<BeatTime, Pitch>(name: "Violin")
        var part2 = Part<BeatTime, Pitch>(name: "Cello")

        part1.noteTable.insert(attack: BeatTime(0.49), duration: 1, pitch: .c4)
        part2.noteTable.insert(attack: BeatTime(4.49), duration: 1, pitch: .e4)

        let targetID = part1.partID
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        try work.quantize(targetID, to: [1])

        guard case let .standardBeat(parts, _) = work.content
        else { Issue.record("Expected .standardBeat content."); return }

        #expect(parts[0].noteTable.timeRange?.lowerBound == 0)
        #expect(parts[1].noteTable.timeRange?.lowerBound == BeatTime(4.49))
    }

    @Test
    func quantize_singlePart_missingID_isNoOp() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.quantize(PartID(), to: [1])

        #expect(work.partCount == 1)
    }

    @Test
    func quantize_partIDs_snapsOnlyTargetedParts() throws {
        var part1 = Part<BeatTime, Pitch>(name: "Violin")
        var part2 = Part<BeatTime, Pitch>(name: "Cello")

        part1.noteTable.insert(attack: BeatTime(0.49), duration: 1, pitch: .c4)
        part2.noteTable.insert(attack: BeatTime(4.49), duration: 1, pitch: .e4)

        let partIDs: Set<PartID> = [part1.partID]
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        try work.quantize(partIDs, to: [1])

        guard case let .standardBeat(parts, _) = work.content
        else { Issue.record("Expected .standardBeat content."); return }

        #expect(parts[0].noteTable.timeRange?.lowerBound == 0)
        #expect(parts[1].noteTable.timeRange?.lowerBound == BeatTime(4.49))
    }

    @Test
    func quantize_noteIDs_restrictsAffectedNotes() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        let noteID1 = part.noteTable.insert(attack: BeatTime(0.49), duration: 1, pitch: .c4)
        let noteID2 = part.noteTable.insert(attack: BeatTime(4.49), duration: 1, pitch: .d4)

        let targetID = part.partID
        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.quantize(targetID, to: [1], noteIDs: [noteID1])

        guard case let .standardBeat(parts, _) = work.content
        else { Issue.record("Expected .standardBeat content."); return }

        var attacksByID: [NoteID: BeatTime] = [:]

        parts[0].noteTable.forEach { noteID, attack, _, _, _, _ in
            attacksByID[noteID] = attack
        }

        #expect(attacksByID[noteID1] == 0)
        #expect(attacksByID[noteID2] == BeatTime(4.49))
    }

    @Test
    func quantize_wholeWork_wrongTimeBasisThrows() {
        var work = Work(content: .standardWall([]))

        #expect(throws: Work.Error.timeBasisMismatch(expected: .beat)) {
            try work.quantize(to: [1])
        }
    }

    @Test
    func quantize_absoluteWall_wrongTimeBasisThrows() {
        var work = Work(content: .absoluteWall([]))

        #expect(throws: Work.Error.timeBasisMismatch(expected: .beat)) {
            try work.quantize(to: [1])
        }
    }

    @Test
    func quantize_keyboardWall_wrongTimeBasisThrows() {
        var work = Work(content: .keyboardWall([]))

        #expect(throws: Work.Error.timeBasisMismatch(expected: .beat)) {
            try work.quantize(to: [1])
        }
    }

    @Test
    func quantize_emptyFactorsThrowsEmptyQuantizationFactors() {
        var work = Work(content: .standardBeat([], TempoMap()))

        #expect(throws: Work.Error.emptyQuantizationFactors) {
            try work.quantize(to: [])
        }
    }

    @Test
    func quantize_invalidFactorThrowsInvalidQuantizationFactor() {
        var work = Work(content: .standardBeat([], TempoMap()))

        #expect(throws: Work.Error.invalidQuantizationFactor(0)) {
            try work.quantize(to: [0])
        }
    }

    @Test
    func quantize_partIDs_invalidFactorsLeavesWorkUnchanged() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: BeatTime(0.49), duration: 1, pitch: .c4)

        let partIDs: Set<PartID> = [part.partID]
        var work = Work(content: .standardBeat([part], TempoMap()))

        #expect(throws: Work.Error.emptyQuantizationFactors) {
            try work.quantize(partIDs, to: [])
        }

        guard case let .standardBeat(parts, _) = work.content
        else { Issue.record("Expected .standardBeat content."); return }

        #expect(parts[0].noteTable.timeRange?.lowerBound == BeatTime(0.49))
    }
}
