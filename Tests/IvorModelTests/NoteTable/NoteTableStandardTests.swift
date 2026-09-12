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
    func augment_invalidAnchorThrows() {
        var table = NoteTableSB()

        table.insert(attack: 2, duration: 1, pitch: .c4)

        #expect(throws: NoteTableSB.Error.invalidAnchor) {
            try table.augment(by: Number(2), anchor: 3)
        }
    }

    @Test
    func augment_invalidFactor() {
        var table = NoteTableSB()

        #expect(throws: NoteTableSB.Error.self) {
            try table.augment(by: Number(0))
        }
    }

    @Test
    func augment_nilAnchorWithNoteIDsUsesSelectedRange() throws {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let noteID2 = table.insert(attack: 4, duration: 1, pitch: .d4)

        try table.augment(by: Number(2), noteIDs: [noteID2])

        var duration4: NoteTableSB.DurationType?

        table.forEach { noteID, _, duration, _, _, _ in
            if noteID == noteID2 {
                duration4 = duration
            }
        }

        //
        // Anchored to the selected note's own attack (4), not the whole table's low bound (0), so
        // its attack stays put while its duration still scales:
        //
        #expect(duration4 == 2)

        var attack4: BeatTime?

        table.forEach { noteID, attack, _, _, _, _ in
            if noteID == noteID2 {
                attack4 = attack
            }
        }

        #expect(attack4 == 4)
    }

    @Test
    func augment_noteIDsRestrictsAffectedNotes() throws {
        var table = NoteTableSB()

        let noteID1 = table.insert(attack: 0, duration: 1, pitch: .c4)

        table.insert(attack: 4, duration: 1, pitch: .d4)

        try table.augment(by: Number(2), noteIDs: [noteID1])

        var attacks: [BeatTime] = []

        table.forEach { _, attack, _, _, _, _ in
            attacks.append(attack)
        }

        #expect(attacks.sorted() == [0, 4])
    }

    @Test
    func augment_scalesTimings() throws {
        var table = NoteTableSB()

        table.insert(attack: 1, duration: 1, pitch: .c4)

        try table.augment(by: Number(2))

        #expect(table.timeRange?.upperBound == 3)
    }

    @Test
    func augment_validAnchorDoesNotThrow() throws {
        var table = NoteTableSB()

        table.insert(attack: 2, duration: 1, pitch: .c4)

        try table.augment(by: Number(2), anchor: 2)

        #expect(table.timeRange?.lowerBound == 2)
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
    func invert_invalidAnchorThrows() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        #expect(throws: NoteTableSB.Error.invalidAnchor) {
            try table.invert(around: .d4 ... .e4)
        }
    }

    @Test
    func invert_noteIDsRestrictsAffectedNotes() throws {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let noteID2 = table.insert(attack: 1, duration: 1, pitch: .e4)

        try table.invert(noteIDs: [noteID2])

        var pitch1: Pitch?

        table.forEach { _, attack, _, startPitch, _, _ in
            if attack == 0 {
                pitch1 = startPitch
            }
        }

        //
        // The untouched note's pitch is unaffected:
        //
        #expect(pitch1 == .c4)
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
    func invert_validAnchorDoesNotThrow() throws {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        let ownRange = try #require(table.pitchRange)

        try table.invert(around: ownRange)

        #expect(table.pitchRange == ownRange)
    }

    @Test
    func move_noteIDsRestrictsAffectedNotes() throws {
        var table = NoteTableSB()

        let noteID1 = table.insert(attack: 0, duration: 1, pitch: .c4)

        table.insert(attack: 4, duration: 1, pitch: .d4)

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try table.move(by: directedDuration, noteIDs: [noteID1])

        var attacks: [BeatTime] = []

        table.forEach { _, attack, _, _, _, _ in
            attacks.append(attack)
        }

        #expect(attacks.sorted() == [2, 4])
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
    func reverse_invalidAnchorThrows() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 2, duration: 1, pitch: .d4)

        #expect(throws: NoteTableSB.Error.invalidAnchor) {
            try table.reverse(within: BeatTime(1)...3)
        }
    }

    @Test
    func reverse_noteIDsSelectionIsSelfContained() throws {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let phraseID1 = table.insert(attack: 10, duration: 1, pitch: .d4)
        let phraseID2 = table.insert(attack: 12, duration: 1, pitch: .e4)

        table.insert(attack: 20, duration: 1, pitch: .f4)

        try table.reverse(noteIDs: [phraseID1, phraseID2])

        var phraseAttacks: [BeatTime] = []

        table.forEach { noteID, attack, _, _, _, _ in
            if noteID == phraseID1 || noteID == phraseID2 {
                phraseAttacks.append(attack)
            }
        }

        //
        // Mirrored around its own bounds (10...13), not the whole table's (0...21), so the phrase
        // lands back within its own span (10...13) rather than somewhere else entirely:
        //
        #expect(phraseAttacks.sorted() == [10, 12])

        //
        // The notes outside the selection are untouched:
        //
        #expect(table.timeRange == BeatTime(0)...21)
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
    func reverse_validAnchorDoesNotThrow() throws {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 2, duration: 1, pitch: .d4)

        let ownRange = try #require(table.timeRange)

        try table.reverse(within: ownRange)

        #expect(table.timeRange == ownRange)
    }

    @Test
    func transpose_noteIDsRestrictsAffectedNotes() throws {
        var table = NoteTableSB()

        let noteID1 = table.insert(attack: 0, duration: 1, pitch: .c4)

        table.insert(attack: 1, duration: 1, pitch: .d4)

        let interval = try #require(Pitch.c4.interval(to: .e4))

        try table.transpose(by: interval, noteIDs: [noteID1])

        var pitch2: Pitch?

        table.forEach { _, attack, _, startPitch, _, _ in
            if attack == 1 {
                pitch2 = startPitch
            }
        }

        //
        // The untouched note's pitch is unaffected:
        //
        #expect(pitch2 == .d4)
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
