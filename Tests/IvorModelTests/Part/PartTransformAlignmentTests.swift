// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

//
// With no explicit anchor or range, `Part`'s time transforms resolve one default and pass it to
// the note table and to each map, so the layers can't drift apart. Each test checks the
// invariant that guarantees: a dynamic written at a note's attack is still at that note's
// attack after augment or diminish, and at its release after reverse (reversing turns an
// attack into a release).
//
struct PartTransformAlignmentTests {
}

// MARK: -

extension PartTransformAlignmentTests {
    private typealias PartSB = Part<BeatTime, Pitch>

    @Test
    func augment_noAnchor_keepsMapAlignedWithNotes() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)
        part.dynamicMap.insert(time: 0, dynamic: .mp)

        let entryID = part.dynamicMap.insert(time: 2, dynamic: .ff).entryID

        try part.augment(by: Number(2))

        #expect(_time(of: entryID, in: part) == _note(.e4, in: part)?.attack)
    }

    @Test
    func augment_noteIDsNoAnchor_keepsMapAlignedWithNotes() throws {
        var part = PartSB(name: "Test")

        let noteID1 = part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)
        let noteID2 = part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)

        part.noteTable.insert(attack: 5, duration: 1, pitch: .g4)

        let entryID = part.dynamicMap.insert(time: 2, dynamic: .ff).entryID

        try part.augment(by: Number(2), noteIDs: [noteID1, noteID2])

        #expect(_time(of: entryID, in: part) == _note(.e4, in: part)?.attack)
    }

    @Test
    func diminish_noAnchor_keepsMapAlignedWithNotes() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 3, duration: 1, pitch: .e4)
        part.dynamicMap.insert(time: 0, dynamic: .mp)

        let entryID = part.dynamicMap.insert(time: 3, dynamic: .ff).entryID

        try part.diminish(by: Number(2))

        #expect(_time(of: entryID, in: part) == _note(.e4, in: part)?.attack)
    }

    @Test
    func diminish_noteIDsNoAnchor_keepsMapAlignedWithNotes() throws {
        var part = PartSB(name: "Test")

        let noteID1 = part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)
        let noteID2 = part.noteTable.insert(attack: 3, duration: 1, pitch: .e4)

        part.noteTable.insert(attack: 6, duration: 1, pitch: .g4)

        let entryID = part.dynamicMap.insert(time: 3, dynamic: .ff).entryID

        try part.diminish(by: Number(2), noteIDs: [noteID1, noteID2])

        #expect(_time(of: entryID, in: part) == _note(.e4, in: part)?.attack)
    }

    @Test
    func reverse_noRange_keepsMapAlignedWithNotes() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)
        part.dynamicMap.insert(time: 0, dynamic: .mp)

        let entryID = part.dynamicMap.insert(time: 1, dynamic: .ff).entryID

        try part.reverse()

        #expect(_time(of: entryID, in: part) == _note(.c4, in: part)?.release)
    }

    @Test
    func reverse_noteIDsNoRange_keepsMapAlignedWithNotes() throws {
        var part = PartSB(name: "Test")

        let noteID1 = part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)
        let noteID2 = part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)

        part.noteTable.insert(attack: 5, duration: 1, pitch: .g4)

        let entryID = part.dynamicMap.insert(time: 1, dynamic: .ff).entryID

        try part.reverse(noteIDs: [noteID1, noteID2])

        #expect(_time(of: entryID, in: part) == _note(.c4, in: part)?.release)
    }
}

// MARK: -

extension PartTransformAlignmentTests {
    private func _note(_ pitch: Pitch,
                       in part: PartSB) -> NoteTable<BeatTime, Pitch>.Note? {
        part.noteTable.first { $0.startPitch == pitch }
    }

    private func _time(of entryID: EntryID,
                       in part: PartSB) -> BeatTime? {
        part.dynamicMap.first { $0.entryID == entryID }?.time
    }
}
