// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkTaggedNoteEventTests {
}

// MARK: -

extension WorkTaggedNoteEventTests {
    @Test
    func equality() {
        let partID = PartID()
        let noteEvent = NoteEvent<BeatTime, Pitch>(pitches: [.c4], duration: 1)
        let tagged1 = Work.TaggedNoteEvent(partID: partID, attack: BeatTime(0), noteEvent: noteEvent)
        let tagged2 = Work.TaggedNoteEvent(partID: partID, attack: BeatTime(0), noteEvent: noteEvent)
        let tagged3 = Work.TaggedNoteEvent(partID: PartID(), attack: BeatTime(0), noteEvent: noteEvent)

        #expect(tagged1 == tagged2)
        #expect(tagged1 != tagged3)
    }

    @Test
    func init_storesFields() {
        let partID = PartID()
        let noteEvent = NoteEvent<BeatTime, Pitch>(pitches: [.c4], duration: 1)
        let tagged = Work.TaggedNoteEvent(partID: partID, attack: BeatTime(2), noteEvent: noteEvent)

        #expect(tagged.partID == partID)
        #expect(tagged.attack == BeatTime(2))
        #expect(tagged.noteEvent == noteEvent)
    }
}
