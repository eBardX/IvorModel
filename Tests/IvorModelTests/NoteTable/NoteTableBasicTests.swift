// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableBasicTests {
}

// MARK: -

extension NoteTableBasicTests {
    private typealias NoteTableSB = NoteTable<BeatTime, Pitch>

    @Test
    func collection_empty() {
        let table = NoteTableSB()

        #expect(table.isEmpty)
        #expect(table.startIndex == table.endIndex)
        #expect(table.first == nil)
        #expect(table.last == nil)
    }

    @Test
    func collection_iteratesNotesInAttackOrder() {
        var table = NoteTableSB()

        let laterID = table.insert(attack: 2, duration: 1, pitch: .e4)
        let earlierID = table.insert(attack: 1, duration: 1, pitch: .c4)

        #expect(table.count == 2)
        #expect(table.map(\.noteID) == [earlierID, laterID])
        #expect(table.map(\.attack) == [1, 2])
        #expect(table.first?.startPitch == .c4)
        #expect(table[table.index(after: table.startIndex)].endPitch == .e4)
        #expect(table.index(table.startIndex, offsetBy: 2) == table.endIndex)
        #expect(table.distance(from: table.endIndex, to: table.startIndex) == -2)
        #expect(table.index(before: table.endIndex) == table.index(after: table.startIndex))
    }

    @Test
    func forEach() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        var pitches: [Pitch] = []

        for note in table {
            pitches.append(note.startPitch)
        }

        #expect(pitches.count == 2)
        #expect(pitches[0] == .c4)
        #expect(pitches[1] == .e4)
    }

    @Test
    func forEach_yieldsDistinctIdentitiesEvenForDuplicates() {
        var table = NoteTableSB()
        var ids: [NoteID] = []

        // A note table allows exact duplicates (a doubled unison) — this confirms
        // identity still distinguishes them even when every field matches.
        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 0, duration: 1, pitch: .c4)

        for note in table {
            ids.append(note.noteID)
        }

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
    func last_empty() {
        #expect(NoteTable<BeatTime, Pitch>().last == nil)
    }

    @Test
    func last_returnsLastNoteInAttackOrder() throws {
        let extras = Extras(elements: [Extra(name: "accent")])
        var ntab = NoteTable<BeatTime, Pitch>()

        let laterID = ntab.insert(attack: 2,
                                  duration: 3,
                                  startPitch: .c4,
                                  endPitch: .e4,
                                  extras: extras)

        ntab.insert(attack: 1,
                    duration: 1,
                    pitch: .g4)

        let last = try #require(ntab.last)

        #expect(last.noteID == laterID)
        #expect(last.attack == 2)
        #expect(last.duration == 3)
        #expect(last.startPitch == .c4)
        #expect(last.endPitch == .e4)
        #expect(last.extras == extras)
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
        var foundNoteID: NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        for note in table {
            foundNoteID = note.noteID
        }

        let moved = try table.moveAttack(noteID: #require(foundNoteID), to: 5)

        #expect(moved)
        #expect(table.timeRange?.lowerBound == 5)
    }

    @Test
    func moveAttack_notFound() {
        var table = NoteTableSB()
        let moved = table.moveAttack(noteID: NoteID(), to: 5)

        #expect(!moved)
    }

    @Test
    func moveDuration_found() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        for note in table {
            foundNoteID = note.noteID
        }

        let moved = try table.moveDuration(noteID: #require(foundNoteID), to: 4)

        #expect(moved)
        #expect(table.timeRange?.upperBound == 4)
    }

    @Test
    func moveDuration_notFound() {
        var table = NoteTableSB()
        let moved = table.moveDuration(noteID: NoteID(), to: 4)

        #expect(!moved)
    }

    @Test
    func movePitchEnd_found() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        for note in table {
            foundNoteID = note.noteID
        }

        let moved = try table.movePitchEnd(noteID: #require(foundNoteID), to: .e4)

        #expect(moved)
        #expect(table.hasPortamento)
    }

    @Test
    func movePitchEnd_notFound() {
        var table = NoteTableSB()
        let moved = table.movePitchEnd(noteID: NoteID(), to: .e4)

        #expect(!moved)
    }

    @Test
    func movePitchStart_found() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        for note in table {
            foundNoteID = note.noteID
        }

        let moved = try table.movePitchStart(noteID: #require(foundNoteID), to: .e4)
        var startPitch: Pitch?

        for note in table {
            startPitch = note.startPitch
        }

        #expect(moved)
        #expect(startPitch == .e4)
    }

    @Test
    func movePitchStart_notFound() {
        var table = NoteTableSB()
        let moved = table.movePitchStart(noteID: NoteID(), to: .e4)

        #expect(!moved)
    }

    @Test
    func moves_preserveIdentity() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        for note in table {
            foundNoteID = note.noteID
        }

        let originalID = try #require(foundNoteID)

        table.moveAttack(noteID: originalID, to: 5)

        var idAfterMove: NoteID?

        for note in table {
            idAfterMove = note.noteID
        }

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
    func remove_noteID_found() throws {
        var table = NoteTableSB()
        var removedID: NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        for note in table {
            removedID = note.noteID
        }

        let noteID = try #require(removedID)
        let removed = table.remove(noteID: noteID)

        #expect(removed)
        #expect(table.isEmpty)
    }

    @Test
    func remove_noteID_notFound() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let removed = table.remove(noteID: NoteID())

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

    @Test
    func updateExtras_found() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        for note in table {
            foundNoteID = note.noteID
        }

        let noteID = try #require(foundNoteID)
        let updated = table.updateExtras(noteID: noteID,
                                         extras: Extras(elements: [Extra(name: "accent")]))

        #expect(updated)
        #expect(table.hasExtras)
    }

    @Test
    func updateExtras_notFound() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let updated = table.updateExtras(noteID: NoteID(),
                                         extras: Extras(elements: [Extra(name: "accent")]))

        #expect(!updated)
    }

    @Test
    func updateExtras_preservesIdentity() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        for note in table {
            foundNoteID = note.noteID
        }

        let originalID = try #require(foundNoteID)

        table.updateExtras(noteID: originalID,
                           extras: Extras(elements: [Extra(name: "accent")]))

        var idAfterUpdate: NoteID?

        for note in table {
            idAfterUpdate = note.noteID
        }

        #expect(idAfterUpdate == originalID)
    }

    //
    // Regression test: two notes tying on attack/duration/pitch used to swap relative order
    // whenever the array-first one had its extras "updated" via remove-then-reinsert (the same
    // mechanism `moveAttack` and its siblings use) — `insertionIndex` always lands a reinserted
    // note after every note it ties with. `updateExtras` exists specifically to update in place
    // instead, so order among ties must survive regardless of which of the pair is edited.
    //
    @Test
    func updateExtras_preservesOrderAmongTies() {
        var table = NoteTableSB()

        let firstID = table.insert(attack: 0, duration: 1, pitch: .c4)
        let secondID = table.insert(attack: 0, duration: 1, pitch: .c4)

        table.updateExtras(noteID: firstID,
                           extras: Extras(elements: [Extra(name: "accent")]))

        var order: [NoteID] = []

        for note in table {
            order.append(note.noteID)
        }

        #expect(order == [firstID, secondID])
    }

    @Test
    func updateExtras_removesExtras() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteID?

        table.insert(attack: 0,
                     duration: 1,
                     pitch: .c4,
                     extras: Extras(elements: [Extra(name: "accent")]))

        for note in table {
            foundNoteID = note.noteID
        }

        let noteID = try #require(foundNoteID)
        let updated = table.updateExtras(noteID: noteID, extras: nil)

        #expect(updated)
        #expect(!table.hasExtras)
    }
}
