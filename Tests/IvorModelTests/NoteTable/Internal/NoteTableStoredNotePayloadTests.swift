// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableStoredNotePayloadTests {
}

// MARK: -

extension NoteTableStoredNotePayloadTests {
    private typealias Payload = BeatNotes.StoredNote.Payload

    @Test
    func init_dropsAnEmptyField() {
        let payload = Payload(extras: Extras(elements: [Extra(name: "accent")]),
                              ornamentation: BeatNotes.Ornamentation())

        #expect(payload?.extras == Extras(elements: [Extra(name: "accent")]))
        #expect(payload?.ornamentation == nil)
    }

    @Test
    func init_keepsBothFields() {
        let ornamentation = BeatNotes.Ornamentation(arpeggio: BeatNotes.Arpeggio(group: 1))
        let payload = Payload(extras: Extras(elements: [Extra(name: "accent")]),
                              ornamentation: ornamentation)

        #expect(payload?.extras != nil)
        #expect(payload?.ornamentation == ornamentation)
    }

    @Test
    func init_rejectsAnEmptyPayload() {
        #expect(Payload(extras: nil, ornamentation: nil) == nil)
        #expect(Payload(extras: Extras(), ornamentation: BeatNotes.Ornamentation()) == nil)
    }
}
