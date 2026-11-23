// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct NoteTableRetimedTests {
}

// MARK: -

extension NoteTableRetimedTests {
    @Test
    func retimed_keepsThePitchTypeAndTakesTheNewTimeType() {
        #expect(BeatNotes.Retimed<WallTime>.self == NoteTable<WallTime, Pitch>.self)
        #expect(NoteTable<WallTime, NoteNumber>.Retimed<BeatTime>.self == NoteTable<BeatTime, NoteNumber>.self)
    }
}
