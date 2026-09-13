// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct NoteTableNoteIDTests {
}

// MARK: -

extension NoteTableNoteIDTests {
    @Test
    func init_generated() {
        let id1 = NoteID()
        let id2 = NoteID()

        #expect(id1 != id2)
        #expect(id1.stringValue.hasPrefix("N$"))
        #expect(id1.stringValue.count == 24)
    }

    @Test
    func init_invalid() {
        #expect(NoteID(stringValue: "") == nil)
        #expect(NoteID(stringValue: "invalid") == nil)
        #expect(NoteID(stringValue: "E$" + String(repeating: "A", count: 22)) == nil)
        #expect(NoteID(stringValue: "N$" + String(repeating: "A", count: 21)) == nil)
    }

    @Test
    func init_valid() {
        let validString = "N$" + String(repeating: "A", count: 22)

        #expect(NoteID(stringValue: validString) != nil)
    }

    @Test
    func isValid() {
        let validString = "N$" + String(repeating: "A", count: 22)

        #expect(NoteID.isValid(validString))
        #expect(!NoteID.isValid("invalid"))
        #expect(!NoteID.isValid("N$short"))
    }
}
