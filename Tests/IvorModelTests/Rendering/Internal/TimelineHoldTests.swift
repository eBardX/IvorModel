// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TimelineHoldTests {
}

// MARK: -

extension TimelineHoldTests {
    @Test
    func init_storesEveryField() {
        let noteID = NoteID()
        let hold = TimelineHold(extra: frac(1, 2),
                                extraSeconds: 2,
                                isExplicit: true,
                                noteID: noteID,
                                part: 1,
                                span: frac(1, 2),
                                time: 3)

        #expect(hold.extra == frac(1, 2))
        #expect(hold.extraSeconds == 2)
        #expect(hold.isExplicit)
        #expect(hold.noteID == noteID)
        #expect(hold.part == 1)
        #expect(hold.span == frac(1, 2))
        #expect(hold.time == 3)
    }

    @Test
    func init_withoutANote() {
        let hold = TimelineHold(extra: 1, extraSeconds: 1, isExplicit: false, noteID: nil, part: 0, span: 1, time: 0)

        #expect(!hold.isExplicit)
        #expect(hold.noteID == nil)
    }
}
