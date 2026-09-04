// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableBasicTests {
}

// MARK: -

extension NoteTableBasicTests {
    private typealias NoteTableSB = NoteTable<BeatTime, Pitch>

    @Test
    func forEach() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        var pitches: [Pitch] = []

        table.forEach { _, _, _, startPitch, _, _ in
            pitches.append(startPitch)
        }

        #expect(pitches.count == 2)
        #expect(pitches[0] == .c4)
        #expect(pitches[1] == .e4)
    }

    @Test
    func forEach_yieldsDistinctIdentitiesEvenForDuplicates() {
        var table = NoteTableSB()
        var ids: [NoteTableSB.NoteID] = []

        // A note table allows exact duplicates (a doubled unison) — this confirms
        // identity still distinguishes them even when every field matches.
        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 0, duration: 1, pitch: .c4)

        table.forEach { noteID, _, _, _, _, _ in ids.append(noteID) }

        #expect(Set(ids).count == 2)
    }

    @Test
    func hasPortamento_afterInsert() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4)

        #expect(table.hasPortamento)
    }

    @Test
    func isEmpty_afterInsert() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        #expect(!table.isEmpty)
    }

    @Test
    func isEmpty_initial() {
        let table = NoteTableSB()

        #expect(table.isEmpty)
    }

    @Test
    func isMonophonic_overlapping() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 2, pitch: .c4)
        table.insert(attack: 1, duration: 2, pitch: .e4)

        #expect(!table.isMonophonic)
    }

    @Test
    func isMonophonic_sequential() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        #expect(table.isMonophonic)
    }

    @Test
    func merge() {
        var table1 = NoteTableSB()
        var table2 = NoteTableSB()

        table1.insert(attack: 0, duration: 1, pitch: .c4)
        table2.insert(attack: 2, duration: 1, pitch: .g4)
        table1.merge(with: table2)

        #expect(!table1.isEmpty)
        #expect(table1.pitchRange?.lowerBound == .c4)
        #expect(table1.pitchRange?.upperBound == .g4)
    }

    @Test
    func moveAttack_found() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteTableSB.NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        table.forEach { noteID, _, _, _, _, _ in foundNoteID = noteID }

        let moved = try table.moveAttack(noteID: #require(foundNoteID), to: 5)

        #expect(moved)
        #expect(table.timeRange?.lowerBound == 5)
    }

    @Test
    func moveAttack_notFound() {
        var table = NoteTableSB()
        let moved = table.moveAttack(noteID: NoteTableSB.NoteID(), to: 5)

        #expect(!moved)
    }

    @Test
    func moveDuration_found() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteTableSB.NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        table.forEach { noteID, _, _, _, _, _ in foundNoteID = noteID }

        let moved = try table.moveDuration(noteID: #require(foundNoteID), to: 4)

        #expect(moved)
        #expect(table.timeRange?.upperBound == 4)
    }

    @Test
    func moveDuration_notFound() {
        var table = NoteTableSB()
        let moved = table.moveDuration(noteID: NoteTableSB.NoteID(), to: 4)

        #expect(!moved)
    }

    @Test
    func movePitchEnd_found() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteTableSB.NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        table.forEach { noteID, _, _, _, _, _ in foundNoteID = noteID }

        let moved = try table.movePitchEnd(noteID: #require(foundNoteID), to: .e4)

        #expect(moved)
        #expect(table.hasPortamento)
    }

    @Test
    func movePitchEnd_notFound() {
        var table = NoteTableSB()
        let moved = table.movePitchEnd(noteID: NoteTableSB.NoteID(), to: .e4)

        #expect(!moved)
    }

    @Test
    func movePitchStart_found() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteTableSB.NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        table.forEach { noteID, _, _, _, _, _ in foundNoteID = noteID }

        let moved = try table.movePitchStart(noteID: #require(foundNoteID), to: .e4)
        var startPitch: Pitch?

        table.forEach { _, _, _, notePitch, _, _ in startPitch = notePitch }

        #expect(moved)
        #expect(startPitch == .e4)
    }

    @Test
    func movePitchStart_notFound() {
        var table = NoteTableSB()
        let moved = table.movePitchStart(noteID: NoteTableSB.NoteID(), to: .e4)

        #expect(!moved)
    }

    @Test
    func moves_preserveIdentity() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteTableSB.NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        table.forEach { noteID, _, _, _, _, _ in foundNoteID = noteID }

        let originalID = try #require(foundNoteID)

        table.moveAttack(noteID: originalID, to: 5)

        var idAfterMove: NoteTableSB.NoteID?

        table.forEach { noteID, _, _, _, _, _ in idAfterMove = noteID }

        #expect(idAfterMove == originalID)
    }

    @Test
    func pitchRange() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .g5)
        table.insert(attack: 2, duration: 1, pitch: .e4)

        #expect(table.pitchRange?.lowerBound == .c4)
        #expect(table.pitchRange?.upperBound == .g5)
    }

    @Test
    func remove_found() {
        var table = NoteTableSB()

        let insertedID = table.insert(attack: 0, duration: 1, pitch: .c4)
        let removedID = table.remove(attack: 0, duration: 1, pitch: .c4)

        #expect(removedID == insertedID)
        #expect(table.isEmpty)
    }

    @Test
    func remove_notFound() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let removedID = table.remove(attack: 0, duration: 1, pitch: .g5)

        #expect(removedID == nil)
        #expect(!table.isEmpty)
    }

    @Test
    func remove_matchesEarliestDuplicate() {
        var table = NoteTableSB()

        // Exact duplicates are allowed in a note table, so both of these match the
        // same `attack`/`duration`/`pitch`/`extras`. `remove` should remove the one
        // that was inserted first and report its identity, leaving the other intact.
        let firstID = table.insert(attack: 0, duration: 1, pitch: .c4)
        let secondID = table.insert(attack: 0, duration: 1, pitch: .c4)

        let removedID = table.remove(attack: 0, duration: 1, pitch: .c4)

        #expect(removedID == firstID)

        var remaining: [NoteTableSB.NoteID] = []

        table.forEach { noteID, _, _, _, _, _ in remaining.append(noteID) }

        #expect(remaining == [secondID])
    }

    @Test
    func remove_noteID_found() throws {
        var table = NoteTableSB()
        var removedID: NoteTableSB.NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        table.forEach { noteID, _, _, _, _, _ in removedID = noteID }

        let noteID = try #require(removedID)
        let removed = table.remove(noteID: noteID)

        #expect(removed)
        #expect(table.isEmpty)
    }

    @Test
    func remove_noteID_notFound() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let removed = table.remove(noteID: NoteTableSB.NoteID())

        #expect(!removed)
        #expect(!table.isEmpty)
    }

    @Test
    func timeRange() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 2, pitch: .c4)
        table.insert(attack: 3, duration: 1, pitch: .e4)

        #expect(table.timeRange?.lowerBound == 0)
        #expect(table.timeRange?.upperBound == 4)
    }
}
