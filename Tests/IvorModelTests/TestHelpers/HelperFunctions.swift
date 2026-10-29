// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import XestiNumbers

func makeNoteTableSB(_ rawNotes: [(attack: BeatTime, duration: BeatDuration, pitch: Pitch)]) -> NoteTable<BeatTime, Pitch> {
    var ntab = NoteTable<BeatTime, Pitch>()

    for rawNote in rawNotes {
        ntab.insert(attack: rawNote.attack,
                    duration: rawNote.duration,
                    pitch: rawNote.pitch)
    }

    return ntab
}

func makeNoteTriplesSB(_ noteTable: NoteTable<BeatTime, Pitch>) -> [NoteTripleSB] {
    noteTable.notes.map {
        NoteTripleSB(attack: $0.attack,
                     duration: $0.duration,
                     pitch: $0.startPitch)
    }
}

func makeLockedWorkSB() -> (work: Work, partID: PartID) {
    var part = Part<BeatTime, Pitch>(name: "Violin")

    part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

    var work = Work(content: .standardBeat([part], TempoMap()))

    work.isLocked = true

    return (work, part.partID)
}

func makeWorkInfo() -> Work.Info {
    Work.Info(title: "Aubade",
              subtitles: ["for violin"],
              alternateTitles: ["Dawn Song"],
              parentWorkTitle: "Suite No. 1",
              dedication: "To my teacher",
              credits: Credit(name: "J. Smith", role: .composer).map { [$0] } ?? [],
              rights: RightsNotice(text: "© 2026 J. Smith", scope: .music).map { [$0] } ?? [],
              remarks: Remark(text: "Written at dawn.", label: "history").map { [$0] } ?? [])
}

// MARK: -

//
// A note’s attack, duration and start pitch, compared by value (so 2 and 2.0
// are equal) and ignoring its note ID.
//
struct NoteTripleSB: Equatable {
    let attack: BeatTime
    let duration: BeatDuration
    let pitch: Pitch
}
