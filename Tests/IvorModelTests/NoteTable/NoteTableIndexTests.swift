// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct NoteTableIndexTests {
}

// MARK: -

extension NoteTableIndexTests {
    @Test
    func comparable() {
        #expect(NoteTable<BeatTime, Pitch>.Index(0) < NoteTable<BeatTime, Pitch>.Index(1))
        #expect(!(NoteTable<BeatTime, Pitch>.Index(1) < NoteTable<BeatTime, Pitch>.Index(0)))
    }

    @Test
    func comparable_notLessThanSelf() {
        #expect(!(NoteTable<BeatTime, Pitch>.Index(2) < NoteTable<BeatTime, Pitch>.Index(2))) // swiftlint:disable:this identical_operands
    }

    @Test
    func equality() {
        #expect(NoteTable<BeatTime, Pitch>.Index(3) == NoteTable<BeatTime, Pitch>.Index(3)) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let indices: Set = [NoteTable<BeatTime, Pitch>.Index(0),
                            NoteTable<BeatTime, Pitch>.Index(0),
                            NoteTable<BeatTime, Pitch>.Index(1)]

        #expect(indices.count == 2)
    }

    @Test
    func inequality() {
        #expect(NoteTable<BeatTime, Pitch>.Index(3) != NoteTable<BeatTime, Pitch>.Index(4))
    }

    @Test
    func init_storesOffset() {
        #expect(NoteTable<BeatTime, Pitch>.Index(5).offset == 5)
    }
}
