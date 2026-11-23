// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
import Testing

struct NoteTablePitchSetTests {
}

// MARK: -

extension NoteTablePitchSetTests {
    @Test
    func isPitchSet_duplicates() {
        #expect(!BeatNotes.isPitchSet([.c4, .c4]))
    }

    @Test
    func isPitchSet_empty() {
        #expect(!BeatNotes.isPitchSet([]))
    }

    @Test
    func isPitchSet_single() {
        #expect(BeatNotes.isPitchSet([.c4]))
    }

    @Test
    func isPitchSet_sortedAscending() {
        #expect(BeatNotes.isPitchSet([.c4, .e4, .g4]))
    }

    @Test
    func isPitchSet_unsorted() {
        #expect(!BeatNotes.isPitchSet([.e4, .c4]))
    }

    @Test
    func pitchSet_empty() {
        #expect(BeatNotes.pitchSet([]).isEmpty)
    }

    @Test
    func pitchSet_isAlwaysAPitchSetWhenNonEmpty() {
        #expect(BeatNotes.isPitchSet(BeatNotes.pitchSet([.g4, .c4, .g4, .e4])))
    }

    @Test
    func pitchSet_sortsAndRemovesDuplicates() {
        #expect(BeatNotes.pitchSet([.g4, .c4, .g4, .e4]) == [.c4, .e4, .g4])
    }
}
