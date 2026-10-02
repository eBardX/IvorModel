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

func makeLockedWorkSB() -> (work: Work, partID: PartID) {
    var part = Part<BeatTime, Pitch>(name: "Violin")

    part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

    var work = Work(content: .standardBeat([part], TempoMap()))

    work.isLocked = true

    return (work, part.partID)
}

func makePartMetadata<T: TimeProtocol, P: PitchProtocol>(_ type: Part<T, P>.Type) -> Part<T, P>.Metadata {
    Part<T, P>.Metadata(abbreviation: "Vln.",
                        remarks: Remark(text: "Muted throughout.").map { [$0] } ?? [])
}

func makeWorkMetadata() -> Work.Metadata {
    Work.Metadata(title: "Aubade",
                  subtitles: ["for violin"],
                  alternateTitles: ["Dawn Song"],
                  parentWorkTitle: "Suite No. 1",
                  credits: Credit(name: "J. Smith", role: .composer).map { [$0] } ?? [],
                  rights: RightsNotice(text: "© 2026 J. Smith", scope: .music).map { [$0] } ?? [],
                  remarks: Remark(text: "Written at dawn.", label: "history").map { [$0] } ?? [])
}
