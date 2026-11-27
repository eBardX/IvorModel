// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct PartStrandTests {
}

// MARK: -

extension PartStrandTests {
    @Test
    func aggregates_spanEveryStrand() {
        let part = Self._piano()

        #expect(part.noteCount == 3)
        #expect(part.pitchRange == Pitch.c3...Pitch.g4)
        #expect(part.timeRange == beatTime(0)...beatTime(3))
        #expect(part.attackingIn(beatTime(1)...beatTime(1)).count == 2)
        #expect(part.soundingIn(beatTime(0)...beatTime(0)).count == 1)
        #expect(part.pitchIn(Pitch.c3...Pitch.c3).count == 1)
    }

    @Test
    func codable_rejectsDuplicateStrandIDs() throws {
        let strand = Strand<BeatTime, Pitch>()
        let part = Part<BeatTime, Pitch>(partID: PartID(), name: "Bad", strands: [strand, strand])

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Part<BeatTime, Pitch>.self, from: JSONEncoder().encode(part))
        }
    }

    @Test
    func codable_rejectsNoStrands() throws {
        let part = Part<BeatTime, Pitch>(partID: PartID(), name: "Bad", strands: [])

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Part<BeatTime, Pitch>.self, from: JSONEncoder().encode(part))
        }
    }

    @Test
    func codable_roundTripsStrands() throws {
        let part = Self._piano()
        let decoded = try JSONDecoder().decode(Part<BeatTime, Pitch>.self, from: JSONEncoder().encode(part))

        #expect(decoded.strandIDs == part.strandIDs)
        #expect(decoded.strands.map(\.name) == ["RH", "LH"])
        #expect(decoded.strands.map(\.noteTable.count) == [2, 1])
        #expect(decoded.strands[1].dynamicMap?.map(\.dynamic) == [.p])
    }

    @Test
    func duplicated_givesNewStrandIDs() {
        let part = Self._piano()
        let copy = part.duplicated()

        #expect(Set(copy.strandIDs).isDisjoint(with: part.strandIDs))
        #expect(copy.strands.map(\.name) == ["RH", "LH"])
        #expect(Set(copy.noteIDs).isDisjoint(with: part.noteIDs))
    }

    @Test
    func init_noteTable_makesOneUnnamedStrand() {
        let part = Part<BeatTime, Pitch>(name: "Flute")

        #expect(part.strands.count == 1)
        #expect(part.strands[0].name.isEmpty)
    }

    @Test
    func mergedNoteTable_holdsEveryNoteInTimeOrder() {
        let merged = Self._piano().mergedNoteTable

        #expect(merged.map(\.attack) == [0, 1, 1].map(beatTime))
        #expect(merged.count == 3)
    }

    @Test
    func modifyStrand_editsOnlyThatStrand() {
        var part = Self._piano()
        let leftHand = part.strandIDs[1]

        let result: Void? = part.modifyStrand(leftHand) { $0.name = "Left" }

        #expect(result != nil)
        #expect(part.strands.map(\.name) == ["RH", "Left"])
        #expect(part.modifyStrand(StrandID()) { $0.name = "None" } == nil)
    }

    @Test
    func move_carriesEveryStrandAndItsOwnMap() throws {
        var part = Self._piano()

        try part.move(by: later(2))

        #expect(part.strands[0].noteTable.map(\.attack) == [2, 3].map(beatTime))
        #expect(part.strands[1].noteTable.map(\.attack) == [3].map(beatTime))
        #expect(part.strands[1].dynamicMap?.map(\.time) == [beatTime(3)])
    }

    @Test
    func move_selectedNotes_leavesOtherStrandsAlone() throws {
        var part = Self._piano()
        let leftHandNote = try #require(part.strands[1].noteTable.first?.noteID)

        try part.move(by: later(1), noteIDs: [leftHandNote])

        #expect(part.strands[0].noteTable.map(\.attack) == [0, 1].map(beatTime))
        #expect(part.strands[1].noteTable.map(\.attack) == [2].map(beatTime))
    }

    @Test
    func resolution_usesOwnTablesOrThePart() {
        let part = Self._piano()

        #expect(part.dynamicMap(for: part.strands[0]).isEmpty)
        #expect(part.dynamicMap(for: part.strands[1]).map(\.dynamic) == [.p])
        #expect(part.instrumentTable(for: part.strands[1]).isEmpty)
    }

    @Test
    func strandLookup_findsByID() {
        let part = Self._piano()

        #expect(part.strand(part.strandIDs[1])?.name == "LH")
        #expect(part.index(ofStrandID: part.strandIDs[1]) == 1)
        #expect(part.strand(StrandID()) == nil)
    }

    @Test
    func unusedArpeggioGroup_looksAcrossStrands() throws {
        var rightHand = NoteTable<BeatTime, Pitch>()
        var leftHand = NoteTable<BeatTime, Pitch>()

        try rightHand.insert(attack: 0, duration: 1, pitch: .c4, ornamentation: .init(arpeggio: .init(group: 2)))
        try leftHand.insert(attack: 0, duration: 1, pitch: .c3, ornamentation: .init(arpeggio: .init(group: 5)))

        let part = Part(name: "Piano", strands: [Strand(noteTable: rightHand), Strand(noteTable: leftHand)])

        #expect(part.unusedArpeggioGroup == 6)
        #expect(Part<BeatTime, Pitch>(name: "Empty").unusedArpeggioGroup == 1)
    }

    // MARK: Private Type Methods

    //
    // Two strands: a right hand with two notes, and a left hand with one and a dynamic map of its
    // own, with an entry at its note.
    //
    private static func _piano() -> Part<BeatTime, Pitch> {
        var rightHand = NoteTable<BeatTime, Pitch>()
        var leftHand = NoteTable<BeatTime, Pitch>()
        var leftDynamics = DynamicMap<BeatTime>()

        rightHand.insert(attack: 0, duration: 1, pitch: .e4)
        rightHand.insert(attack: 1, duration: 1, pitch: .g4)
        leftHand.insert(attack: 1, duration: 2, pitch: .c3)
        leftDynamics.insert(time: 1, dynamic: .p)

        return Part(name: "Piano",
                    strands: [Strand(name: "RH", noteTable: rightHand),
                              Strand(name: "LH", noteTable: leftHand, dynamicMap: leftDynamics)])
    }
}
