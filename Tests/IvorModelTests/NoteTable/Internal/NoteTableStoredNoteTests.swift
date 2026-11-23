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
        let note = StoredNote(attack: 2, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(note.attack == 2)
    }

    @Test
    func codable_extended() throws {
        let original = StoredNote(attack: 0,
                                  duration: 1,
                                  startPitch: .c4,
                                  endPitch: .c4,
                                  extras: Extras(elements: [Extra(name: "accent")]),
                                  ornamentation: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StoredNote.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func codable_glide() throws {
        let original = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil, ornamentation: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StoredNote.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func codable_ornamentationAfterAnExtrasSlot() throws {
        let ornamentation = try trillOrnamentation(written: .d4)
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: ornamentation)
        let head = try [encodedJSON(0 as BeatTime), encodedJSON(1 as BeatDuration), encodedJSON(Pitch.c4), encodedJSON(Pitch.c4)]

        #expect(try encodedJSON(note) == "[" + head.joined(separator: ",") + ",null," + encodedJSON(ornamentation) + "]")
    }

    @Test
    func codable_rejectsAPartnerOnTheWrongSide() throws {
        let head = try [encodedJSON(0 as BeatTime), encodedJSON(1 as BeatDuration), encodedJSON(Pitch.e4)]
        let trillJSON = try encodedJSON(trillOrnamentation(written: .d4))
        let json = try "[" + head.joined(separator: ",") + "," + encodedJSON(Pitch.e4) + ",null," + trillJSON + "]"

        #expect(throws: DecodingError.self) {
            try decodeJSON(StoredNote.self, json)
        }
    }

    @Test
    func codable_roundTrip_ornamentation() throws {
        let ornamentation = try trillOrnamentation(written: .d4)
        let notes = [StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: ornamentation),
                     StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil, ornamentation: ornamentation),
                     StoredNote(attack: 0,
                                duration: 1,
                                startPitch: .c4,
                                endPitch: .c4,
                                extras: Extras(elements: [Extra(name: "accent")]),
                                ornamentation: ornamentation)]

        for note in notes {
            let decoded = try codingRoundTrip(note)

            #expect(decoded == note)
            #expect(decoded.ornamentation == ornamentation)
        }
    }

    @Test
    func codable_simple() throws {
        let original = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StoredNote.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func comparable() {
        let earlier = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)
        let later = StoredNote(attack: 1, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(earlier < later)
        #expect(!(later < earlier))
    }

    @Test
    func duration() {
        let note = StoredNote(attack: 0, duration: 2, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(note.duration == 2)
    }

    @Test
    func endPitch_glide() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil, ornamentation: nil)

        #expect(note.endPitch == .e4)
    }

    @Test
    func endPitch_simple() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(note.endPitch == .c4)
    }

    @Test
    func equality_ignoresIdentity() {
        let n1 = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)
        let n2 = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(n1.noteID != n2.noteID)
        #expect(n1 == n2)
    }

    @Test
    func equality_includesOrnamentationButOrderingDoesNot() throws {
        let plain = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)
        let ornamented = try StoredNote(attack: 0,
                                        duration: 1,
                                        startPitch: .c4,
                                        endPitch: .c4,
                                        extras: nil,
                                        ornamentation: trillOrnamentation(written: nil))

        #expect(plain != ornamented)
        #expect(!(plain < ornamented))
        #expect(!(ornamented < plain))
    }

    @Test
    func extras_extended() {
        let extras = Extras(elements: [Extra(name: "accent")])
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: extras, ornamentation: nil)

        #expect(note.extras == extras)
    }

    @Test
    func extras_simple() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(note.extras == nil)
    }

    @Test
    func init_emptyOrnamentationStaysSimple() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: Extras(), ornamentation: BeatNotes.Ornamentation())

        guard case .simple = note
        else { Issue.record("Expected a simple note"); return }

        #expect(note.ornamentation == nil)
        #expect(note.extras == nil)
    }

    @Test
    func init_extended() {
        let note = StoredNote(attack: 0,
                              duration: 1,
                              startPitch: .c4,
                              endPitch: .c4,
                              extras: Extras(elements: [Extra(name: "accent")]),
                              ornamentation: nil)

        #expect(note.extras != nil)
    }

    @Test
    func init_glide() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil, ornamentation: nil)

        #expect(note.startPitch != note.endPitch)
    }

    @Test
    func init_ornamentationOnlyIsExtended() throws {
        let ornamentation = try trillOrnamentation(written: nil)
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil, ornamentation: ornamentation)

        guard case .extended = note
        else { Issue.record("Expected an extended note"); return }

        #expect(note.ornamentation == ornamentation)
        #expect(note.extras == nil)
        #expect(note.endPitch == .e4)
    }

    @Test
    func init_simple() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(note.startPitch == note.endPitch)
        #expect(note.extras == nil)
    }

    @Test
    func maximumPitch() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .e4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(note.maximumPitch == .e4)
    }

    @Test
    func minimumPitch() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .e4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(note.minimumPitch == .c4)
    }

    @Test
    func noteID_defaultsToFreshIdentity() {
        let n1 = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)
        let n2 = StoredNote(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(n1.noteID != n2.noteID)
    }

    @Test
    func noteID_explicit() {
        let noteID = NoteID()
        let note = StoredNote(noteID: noteID, attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(note.noteID == noteID)
    }

    @Test
    func release() {
        let note = StoredNote(attack: 1, duration: 2, startPitch: .c4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(note.release == 3)
    }

    @Test
    func startPitch() {
        let note = StoredNote(attack: 0, duration: 1, startPitch: .e4, endPitch: .c4, extras: nil, ornamentation: nil)

        #expect(note.startPitch == .e4)
    }
}
