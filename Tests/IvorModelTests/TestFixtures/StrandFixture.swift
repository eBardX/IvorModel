// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import XestiNumbers
import XestiTools

//
// A work for the strand and note operations: a piano and a flute.
//
// - Piano, right hand ("RH"): E4 at 0, rolled in group 1, and G4 at 1. It uses the part's
//   dynamic map (p at 0) and instrument table (oboe at 0).
// - Piano, left hand ("LH"): C3 at 0, rolled in group 1 with the E4, with its own dynamic map
//   (f at 0).
// - Piano: a sustain press from 0 to 2, and a pan entry at 0.
// - Flute: C5 at 0, rolled in group 1, and D5 at 2.
//
enum StrandFixture {

    // MARK: Internal Type Methods

    static func fluteID(_ work: Work) -> PartID {
        work.partIDs[1]
    }

    static func flute(_ work: Work) -> Part<BeatTime, Pitch> {
        // swiftlint:disable:next force_unwrapping
        work.part(fluteID(work), as: Part<BeatTime, Pitch>.self)!
    }

    static func hands(_ work: Work) -> (StrandID, StrandID) {
        let strandIDs = piano(work).strandIDs

        return (strandIDs[0], strandIDs[1])
    }

    static func piano(_ work: Work) -> Part<BeatTime, Pitch> {
        // swiftlint:disable:next force_unwrapping
        work.part(pianoID(work), as: Part<BeatTime, Pitch>.self)!
    }

    static func pianoID(_ work: Work) -> PartID {
        work.partIDs[0]
    }

    static func work() -> Work {
        let roll = NoteTable<BeatTime, Pitch>.Ornamentation(arpeggio: .init(group: 1))
        var rightHand = NoteTable<BeatTime, Pitch>()
        var leftHand = NoteTable<BeatTime, Pitch>()
        var fluteNotes = NoteTable<BeatTime, Pitch>()
        var partDynamics = DynamicMap<BeatTime>()
        var leftDynamics = DynamicMap<BeatTime>()
        var instruments = InstrumentTable<BeatTime>()
        var sustain = PedalTable<BeatTime>()

        // swiftlint:disable force_try
        try! rightHand.insert(attack: 0, duration: 1, pitch: .e4, ornamentation: roll)
        rightHand.insert(attack: 1, duration: 1, pitch: .g4)
        try! leftHand.insert(attack: 0, duration: 1, pitch: .c3, ornamentation: roll)
        try! fluteNotes.insert(attack: 0, duration: 2, pitch: .c5, ornamentation: roll)
        fluteNotes.insert(attack: 2, duration: 1, pitch: .d5)
        // swiftlint:enable force_try
        partDynamics.insert(time: 0, dynamic: .p)
        leftDynamics.insert(time: 0, dynamic: .f)
        instruments.insert(time: 0, instrument: Fixtures.oboe)
        sustain.insert(time: 0, level: .down)
        sustain.insert(time: 2, level: .up)

        var piano = Part(name: "Piano",
                         strands: [Strand(name: "RH", noteTable: rightHand),
                                   Strand(name: "LH", noteTable: leftHand, dynamicMap: leftDynamics)],
                         dynamicMap: partDynamics,
                         instrumentTable: instruments)

        piano.pedals[.sustain] = sustain
        piano.panMap.insert(time: 0, pan: .center)

        return Work(content: .standardBeat([piano, Part(name: "Flute", noteTable: fluteNotes)],
                                           TempoMap(),
                                           MeterTable(),
                                           KeyTable()))
    }
}
