// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning

func makeNoteTableSB(_ rawNotes: [(attack: BeatTime, duration: BeatDuration, pitch: Pitch)]) -> NoteTable<BeatTime, Pitch> {
    var ntab = NoteTable<BeatTime, Pitch>()

    for rawNote in rawNotes {
        ntab = ntab.inserting(attack: rawNote.attack,
                              duration: rawNote.duration,
                              pitch: rawNote.pitch)
    }

    return ntab
}
