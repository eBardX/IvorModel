// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableNoteTests {
}

// MARK: -

extension NoteTableNoteTests {
    @Test
    func collection_yieldsInsertedNote() throws {
        var table = NoteTable<BeatTime, Pitch>()

        let noteID = table.insert(attack: 1,
                                  duration: 2,
                                  pitch: .c4)

        let note = try #require(table.first)

        #expect(note.attack == 1)
        #expect(note.duration == 2)
        #expect(note.endPitch == .c4)
        #expect(note.extras == nil)
        #expect(note.noteID == noteID)
        #expect(note.release == 3)
        #expect(note.startPitch == .c4)
    }

    @Test
    func equality() {
        let stored = NoteTable<BeatTime, Pitch>.StoredNote(attack: 0,
                                                           duration: 1,
                                                           startPitch: .c4,
                                                           endPitch: .c4,
                                                           extras: nil)

        #expect(NoteTable<BeatTime, Pitch>.Note(stored) == NoteTable<BeatTime, Pitch>.Note(stored)) // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality_differentNoteID() {
        let stored1 = NoteTable<BeatTime, Pitch>.StoredNote(attack: 0,
                                                            duration: 1,
                                                            startPitch: .c4,
                                                            endPitch: .c4,
                                                            extras: nil)
        let stored2 = NoteTable<BeatTime, Pitch>.StoredNote(attack: 0,
                                                            duration: 1,
                                                            startPitch: .c4,
                                                            endPitch: .c4,
                                                            extras: nil)

        #expect(NoteTable<BeatTime, Pitch>.Note(stored1) != NoteTable<BeatTime, Pitch>.Note(stored2))
    }

    @Test
    func init_extended_copiesExtras() {
        let stored = NoteTable<BeatTime, Pitch>.StoredNote(attack: 0,
                                                           duration: 1,
                                                           startPitch: .c4,
                                                           endPitch: .c4,
                                                           extras: makeChannelExtras(2))

        #expect(NoteTable<BeatTime, Pitch>.Note(stored).extras == makeChannelExtras(2))
    }

    @Test
    func init_glide_copiesBothPitches() {
        let noteID = NoteID()
        let stored = NoteTable<BeatTime, Pitch>.StoredNote(noteID: noteID,
                                                           attack: 2,
                                                           duration: 3,
                                                           startPitch: .c4,
                                                           endPitch: .g4,
                                                           extras: nil)
        let note = NoteTable<BeatTime, Pitch>.Note(stored)

        #expect(note.attack == 2)
        #expect(note.duration == 3)
        #expect(note.endPitch == .g4)
        #expect(note.noteID == noteID)
        #expect(note.release == 5)
        #expect(note.startPitch == .c4)
    }
}
