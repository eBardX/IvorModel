// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
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
    private typealias Note = NoteTable<BeatTime, Pitch>.Note

    @Test
    func attack() {
        let note = Note(attack: 2, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.attack == 2)
    }

    @Test
    func codable_extended() throws {
        let original = Note(attack: 0,
                            duration: 1,
                            startPitch: .c4,
                            endPitch: .c4,
                            extras: Extras(elements: [Extra(name: "accent")]))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Note.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func codable_glide() throws {
        let original = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Note.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func codable_simple() throws {
        let original = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Note.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func comparable() {
        let earlier = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)
        let later = Note(attack: 1, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(earlier < later)
        #expect(!(later < earlier))
    }

    @Test
    func duration() {
        let note = Note(attack: 0, duration: 2, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.duration == 2)
    }

    @Test
    func endPitch_glide() {
        let note = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil)

        #expect(note.endPitch == .e4)
    }

    @Test
    func endPitch_simple() {
        let note = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.endPitch == .c4)
    }

    @Test
    func equality_ignoresIdentity() {
        let n1 = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)
        let n2 = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(n1.noteID != n2.noteID)
        #expect(n1 == n2)
    }

    @Test
    func extras_extended() {
        let extras = Extras(elements: [Extra(name: "accent")])
        let note = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: extras)

        #expect(note.extras == extras)
    }

    @Test
    func extras_simple() {
        let note = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.extras == nil)
    }

    @Test
    func noteID_defaultsToFreshIdentity() {
        let n1 = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)
        let n2 = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(n1.noteID != n2.noteID)
    }

    @Test
    func noteID_explicit() {
        let noteID = NoteTable<BeatTime, Pitch>.NoteID()
        let note = Note(noteID: noteID, attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.noteID == noteID)
    }

    @Test
    func init_extended() {
        let note = Note(attack: 0,
                        duration: 1,
                        startPitch: .c4,
                        endPitch: .c4,
                        extras: Extras(elements: [Extra(name: "accent")]))

        #expect(note.extras != nil)
    }

    @Test
    func init_glide() {
        let note = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil)

        #expect(note.startPitch != note.endPitch)
    }

    @Test
    func init_simple() {
        let note = Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.startPitch == note.endPitch)
        #expect(note.extras == nil)
    }

    @Test
    func maximumPitch() {
        let note = Note(attack: 0, duration: 1, startPitch: .e4, endPitch: .c4, extras: nil)

        #expect(note.maximumPitch == .e4)
    }

    @Test
    func minimumPitch() {
        let note = Note(attack: 0, duration: 1, startPitch: .e4, endPitch: .c4, extras: nil)

        #expect(note.minimumPitch == .c4)
    }

    @Test
    func release() {
        let note = Note(attack: 1, duration: 2, startPitch: .c4, endPitch: .c4, extras: nil)

        #expect(note.release == 3)
    }

    @Test
    func startPitch() {
        let note = Note(attack: 0, duration: 1, startPitch: .e4, endPitch: .c4, extras: nil)

        #expect(note.startPitch == .e4)
    }
}
