// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableStoredNoteTests {
}

// MARK: -

extension NoteTableStoredNoteTests {
    private typealias StoredNote = NoteTable<BeatTime, Pitch>.StoredNote

    @Test
    func attack() {
        let note = StoredNote(attack: 2, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.attack == 2)
    }

    @Test
    func codable_extended() throws {
        let original = StoredNote(attack: 0,
                                  duration: 1,
                                  startPitch: .c4,
                                  endPitch: .c4,
                                  extras: Extras(elements: [Extra(name: "accent")]))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StoredNote.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func codable_glide() throws {
        let original = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StoredNote.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func codable_simple() throws {
        let original = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StoredNote.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func comparable() {
        let earlier = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)
        let later = StoredNote(attack: 1, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(earlier < later)
        #expect(!(later < earlier))
    }

    @Test
    func duration() {
        let note = StoredNote(attack: 0, duration: 2, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.duration == 2)
    }

    @Test
    func endPitch_glide() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil)

        #expect(note.endPitch == .e4)
    }

    @Test
    func endPitch_simple() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.endPitch == .c4)
    }

    @Test
    func equality_ignoresIdentity() {
        let n1 = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)
        let n2 = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(n1.noteID != n2.noteID)
        #expect(n1 == n2)
    }

    @Test
    func extras_extended() {
        let extras = Extras(elements: [Extra(name: "accent")])
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: extras)

        #expect(note.extras == extras)
    }

    @Test
    func extras_simple() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.extras == nil)
    }

    @Test
    func init_extended() {
        let note = StoredNote(attack: 0,
                              duration: 1,
                              startPitch: .c4,
                              endPitch: .c4,
                              extras: Extras(elements: [Extra(name: "accent")]))

        #expect(note.extras != nil)
    }

    @Test
    func init_glide() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil)

        #expect(note.startPitch != note.endPitch)
    }

    @Test
    func init_simple() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.startPitch == note.endPitch)
        #expect(note.extras == nil)
    }

    @Test
    func maximumPitch() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .e4, endPitch: .c4, extras: nil)

        #expect(note.maximumPitch == .e4)
    }

    @Test
    func minimumPitch() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .e4, endPitch: .c4, extras: nil)

        #expect(note.minimumPitch == .c4)
    }

    @Test
    func noteID_defaultsToFreshIdentity() {
        let n1 = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)
        let n2 = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(n1.noteID != n2.noteID)
    }

    @Test
    func noteID_explicit() {
        let noteID = NoteID()
        let note = StoredNote(noteID: noteID, attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.noteID == noteID)
    }

    @Test
    func release() {
        let note = StoredNote(attack: 1, duration: 2, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.release == 3)
    }

    @Test
    func startPitch() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .e4, endPitch: .c4, extras: nil)

        #expect(note.startPitch == .e4)
    }
}
