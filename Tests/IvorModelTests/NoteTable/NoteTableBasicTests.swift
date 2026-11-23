// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

// swiftlint:disable file_length

struct NoteTableBasicTests {
}

// MARK: -

extension NoteTableBasicTests {
    private typealias NoteTableSB = NoteTable<BeatTime, Pitch>
    private typealias Ornamentation = BeatNotes.Ornamentation

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
    func insert_emptyOrnamentationIsNotStored() throws {
        var table = BeatNotes()

        try table.insert(attack: 0, duration: 1, pitch: .c4, ornamentation: Ornamentation())

        #expect(!table.hasOrnamentation)
        #expect(table.first?.ornamentation == nil)
    }

    @Test
    func insert_outOfOrder_matchesInOrder() {
        let notes: [(attack: BeatTime, duration: BeatDuration, pitch: Pitch)] = [(0, 1, .c4),
                                                                                 (0, 1, .e4),
                                                                                 (0, 2, .c4),
                                                                                 (1, 1, .g4),
                                                                                 (1, 1, .c4),
                                                                                 (2, 1, .e4),
                                                                                 (2, 1, .e4)]
        var inOrder = NoteTableSB()
        var reversed = NoteTableSB()

        for note in notes {
            inOrder.insert(attack: note.attack, duration: note.duration, pitch: note.pitch)
        }

        for note in notes.reversed() {
            reversed.insert(attack: note.attack, duration: note.duration, pitch: note.pitch)
        }

        #expect(reversed.map(\.attack) == inOrder.map(\.attack))
        #expect(reversed.map(\.duration) == inOrder.map(\.duration))
        #expect(reversed.map(\.startPitch) == inOrder.map(\.startPitch))
        #expect(reversed.pitchRange == inOrder.pitchRange)
        #expect(reversed.timeRange == inOrder.timeRange)
    }

    @Test
    func insert_partnerOnTheRightSide() throws {
        var table = BeatNotes()

        try table.insert(attack: 0, duration: 1, pitch: .c4, ornamentation: trillOrnamentation(written: .d4))
        try table.insert(attack: 1, duration: 1, pitch: .c4, ornamentation: lowerMordentOrnamentation(written: .b3))
        try table.insert(attack: 2, duration: 1, pitch: .c4, ornamentation: trillOrnamentation(written: nil))

        #expect(table.count == 3)
    }

    @Test
    func insert_partnerOnTheWrongSide() throws {
        var table = BeatNotes()
        let wrongSides = try [(trillOrnamentation(written: .c4), Pitch.c4),
                              (trillOrnamentation(written: .b3), .c4),
                              (lowerMordentOrnamentation(written: .c4), .c4),
                              (lowerMordentOrnamentation(written: .d4), .c4)]

        for (ornamentation, pitch) in wrongSides {
            #expect(throws: BeatNotes.Error.partnerOnWrongSide(0, 1, pitch, pitch)) {
                try table.insert(attack: 0, duration: 1, pitch: pitch, ornamentation: ornamentation)
            }
        }

        #expect(table.isEmpty)
        #expect(!table.hasOrnamentation)
    }

    @Test
    func insert_partnerSideIsCheckedAgainstTheStartPitch() throws {
        var table = BeatNotes()

        // A glide may end below a trill’s partner: only the start pitch counts.
        try table.insert(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, ornamentation: trillOrnamentation(written: .d4))

        #expect(throws: BeatNotes.Error.partnerOnWrongSide(0, 1, .e4, .c4)) {
            try table.insert(attack: 0, duration: 1, startPitch: .e4, endPitch: .c4, ornamentation: trillOrnamentation(written: .d4))
        }
    }

    @Test
    func insert_withOrnamentation() throws {
        var table = BeatNotes()
        let ornamentation = try trillOrnamentation(written: .d4)
        let noteID = try table.insert(attack: 0,
                                      duration: 1,
                                      pitch: .c4,
                                      extras: Extras(elements: [Extra(name: "accent")]),
                                      ornamentation: ornamentation)
        let note = try #require(table.first)

        #expect(note.noteID == noteID)
        #expect(note.ornamentation == ornamentation)
        #expect(note.extras == Extras(elements: [Extra(name: "accent")]))
        #expect(table.hasOrnamentation)
        #expect(table.hasExtras)
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
    func isMonophonic_gapFilledOutOfOrder() {
        var table = NoteTableSB()

        table.insert(attack: 2, duration: 1, pitch: .c4)
        table.insert(attack: 0, duration: 1, pitch: .e4)
        table.insert(attack: 1, duration: 1, pitch: .g4)

        #expect(table.isMonophonic)
    }

    @Test
    func isMonophonic_overlapInsertedBefore() {
        var table = NoteTableSB()

        table.insert(attack: 2, duration: 1, pitch: .c4)
        table.insert(attack: 0, duration: 3, pitch: .e4)

        #expect(!table.isMonophonic)
    }

    @Test
    func isMonophonic_overlapping() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 2, pitch: .c4)
        table.insert(attack: 1, duration: 2, pitch: .e4)

        #expect(!table.isMonophonic)
    }

    @Test
    func isMonophonic_restoredByMoveDuration() {
        var table = NoteTableSB()

        let noteID = table.insert(attack: 0, duration: 2, pitch: .c4)

        table.insert(attack: 1, duration: 1, pitch: .e4)

        #expect(!table.isMonophonic)

        let moved = table.moveDuration(noteID: noteID, to: 1)

        #expect(moved)
        #expect(table.isMonophonic)
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
    func merge_combinesTheFlag() throws {
        var plain = BeatNotes()
        var ornamented = BeatNotes()

        plain.insert(attack: 0, duration: 1, pitch: .c4)
        try ornamented.insert(attack: 1, duration: 1, pitch: .c4, ornamentation: trillOrnamentation(written: nil))

        var merged = plain

        merged.merge(with: ornamented)

        #expect(merged.hasOrnamentation)
        #expect(try merged.map(\.ornamentation) == [nil, trillOrnamentation(written: nil)])

        plain.merge(with: BeatNotes())

        #expect(!plain.hasOrnamentation)
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
    func movePitchStart_notFound() throws {
        var table = NoteTableSB()
        let moved = try table.movePitchStart(noteID: NoteID(), to: .e4)

        #expect(!moved)
    }

    @Test
    func movePitchStart_partnerOnTheWrongSide() throws {
        var table = BeatNotes()
        let noteID = try table.insert(attack: 0, duration: 1, pitch: .c4, ornamentation: trillOrnamentation(written: .d4))

        for pitch in [Pitch.d4, .e4] {
            #expect(throws: BeatNotes.Error.partnerOnWrongSide(0, 1, pitch, .c4)) {
                try table.movePitchStart(noteID: noteID, to: pitch)
            }
        }

        #expect(table.first?.startPitch == .c4)
        #expect(table.first?.noteID == noteID)
    }

    @Test
    func moves_keepOrnamentation() throws {
        var table = BeatNotes()
        let ornamentation = try trillOrnamentation(written: .d4)
        let noteID = try table.insert(attack: 0, duration: 1, pitch: .c4, ornamentation: ornamentation)

        table.moveAttack(noteID: noteID, to: 1)
        table.moveDuration(noteID: noteID, to: 2)
        table.movePitchEnd(noteID: noteID, to: .e4)
        try table.movePitchStart(noteID: noteID, to: .b3)

        let note = try #require(table.first)

        #expect(note.noteID == noteID)
        #expect(note.attack == 1)
        #expect(note.duration == 2)
        #expect(note.startPitch == .b3)
        #expect(note.endPitch == .e4)
        #expect(note.ornamentation == ornamentation)
        #expect(table.hasOrnamentation)
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
    func release_isAttackPlusDuration() {
        var table = NoteTableSB()

        table.insert(attack: 1, duration: 2, pitch: .c4)

        #expect(table.first?.release == 3)
    }

    //
    // 29.381986 + 1.304348 as doubles is a hair over 30.686334.
    //
    @Test
    func release_meetsNextAttackExactly() throws {
        var table = NoteTable<WallTime, Pitch>()

        try table.insert(attack: #require(WallTime(uintValue: 29_381_986)),
                         duration: #require(WallDuration(uintValue: 1_304_348)),
                         pitch: .c4)
        try table.insert(attack: #require(WallTime(uintValue: 30_686_334)),
                         duration: #require(WallDuration(uintValue: 652_174)),
                         pitch: .c4)

        let notes = Array(table)

        #expect(notes[0].release == notes[1].attack)
        #expect(notes[0].release.doubleValue == notes[1].attack.doubleValue)
    }

    @Test
    func remove_clearsTheFlagWithTheLastOrnamentedNote() throws {
        var table = BeatNotes()
        let firstID = try table.insert(attack: 0, duration: 1, pitch: .c4, ornamentation: trillOrnamentation(written: nil))
        let secondID = try table.insert(attack: 1, duration: 1, pitch: .c4, ornamentation: trillOrnamentation(written: nil))

        table.insert(attack: 2, duration: 1, pitch: .c4)
        table.remove(noteID: firstID)

        #expect(table.hasOrnamentation)

        table.remove(noteID: secondID)

        #expect(!table.hasOrnamentation)
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
    func timeRange_outOfOrderInserts() {
        var table = NoteTableSB()

        table.insert(attack: 2, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 4, pitch: .e4)
        table.insert(attack: 0, duration: 1, pitch: .g4)

        #expect(table.timeRange?.lowerBound == 0)
        #expect(table.timeRange?.upperBound == 5)
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
    func updateExtras_keepsOrnamentation() throws {
        var table = BeatNotes()
        let ornamentation = try trillOrnamentation(written: .d4)
        let noteID = try table.insert(attack: 0, duration: 1, pitch: .c4, ornamentation: ornamentation)

        table.updateExtras(noteID: noteID, extras: Extras(elements: [Extra(name: "accent")]))
        table.updateExtras(noteID: noteID, extras: nil)

        #expect(table.first?.ornamentation == ornamentation)
        #expect(table.hasOrnamentation)
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

    @Test
    func updateOrnamentation_clears() throws {
        var table = BeatNotes()
        let noteID = try table.insert(attack: 0,
                                      duration: 1,
                                      pitch: .c4,
                                      extras: Extras(elements: [Extra(name: "accent")]),
                                      ornamentation: trillOrnamentation(written: nil))

        #expect(try table.updateOrnamentation(noteID: noteID, ornamentation: nil))
        #expect(table.first?.ornamentation == nil)
        #expect(table.first?.extras == Extras(elements: [Extra(name: "accent")]))
        #expect(!table.hasOrnamentation)
    }

    @Test
    func updateOrnamentation_found() throws {
        var table = BeatNotes()
        let noteID = table.insert(attack: 0, duration: 1, pitch: .c4)
        let ornamentation = try lowerMordentOrnamentation(written: .b3)

        #expect(try table.updateOrnamentation(noteID: noteID, ornamentation: ornamentation))
        #expect(table.first?.ornamentation == ornamentation)
        #expect(table.first?.noteID == noteID)
        #expect(table.hasOrnamentation)
    }

    @Test
    func updateOrnamentation_notFound() throws {
        var table = BeatNotes()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        #expect(try !table.updateOrnamentation(noteID: NoteID(), ornamentation: trillOrnamentation(written: nil)))
        #expect(!table.hasOrnamentation)
    }

    @Test
    func updateOrnamentation_partnerOnTheWrongSide() throws {
        var table = BeatNotes()
        let ornamentation = try trillOrnamentation(written: .d4)
        let noteID = try table.insert(attack: 0, duration: 1, pitch: .c4, ornamentation: ornamentation)

        #expect(throws: BeatNotes.Error.partnerOnWrongSide(0, 1, .c4, .c4)) {
            try table.updateOrnamentation(noteID: noteID, ornamentation: lowerMordentOrnamentation(written: .d4))
        }

        #expect(table.first?.ornamentation == ornamentation)
    }

    @Test
    func updateOrnamentation_preservesOrderAmongTies() throws {
        var table = BeatNotes()
        let firstID = table.insert(attack: 0, duration: 1, pitch: .c4)
        let secondID = table.insert(attack: 0, duration: 1, pitch: .c4)

        try table.updateOrnamentation(noteID: firstID, ornamentation: trillOrnamentation(written: nil))

        #expect(table.map(\.noteID) == [firstID, secondID])
    }
}

// swiftlint:enable file_length
