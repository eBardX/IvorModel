// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct StrandTests {
}

// MARK: -

extension StrandTests {
    @Test
    func codable_leavesOutTablesItDoesNotHave() throws {
        let strand = Strand<BeatTime, Pitch>(name: "RH")
        let object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(strand)) as? [String: Any])

        #expect(object["instrumentTable"] == nil)
        #expect(object["dynamicMap"] == nil)
        #expect(object["extras"] == nil)
    }

    @Test
    func codable_roundTripsEverything() throws {
        var notes = NoteTable<BeatTime, Pitch>()
        var dynamics = DynamicMap<BeatTime>()
        var instruments = InstrumentTable<BeatTime>()

        notes.insert(attack: 0, duration: 1, pitch: .c4)
        dynamics.insert(time: 0, dynamic: .f)
        instruments.insert(time: 0, instrument: Fixtures.oboe)

        let strand = Strand(name: "Great",
                            noteTable: notes,
                            instrumentTable: instruments,
                            dynamicMap: dynamics,
                            extras: sampleExtras("strand"))
        let decoded = try JSONDecoder().decode(Strand<BeatTime, Pitch>.self, from: JSONEncoder().encode(strand))

        #expect(decoded.strandID == strand.strandID)
        #expect(decoded.name == "Great")
        #expect(decoded.noteTable.count == 1)
        #expect(decoded.instrumentTable?.map(\.instrument) == [Fixtures.oboe])
        #expect(decoded.dynamicMap?.map(\.dynamic) == [.f])
        #expect(decoded.extras == sampleExtras("strand"))
    }

    @Test
    func duplicated_givesNewIdentities() {
        var notes = NoteTable<BeatTime, Pitch>()

        notes.insert(attack: 0, duration: 1, pitch: .c4)

        let strand = Strand(name: "LH", noteTable: notes, dynamicMap: DynamicMap())
        let copy = strand.duplicated()

        #expect(copy.strandID != strand.strandID)
        #expect(copy.name == "LH")
        #expect(copy.dynamicMap != nil)
        #expect(Set(copy.noteTable.map(\.noteID)).isDisjoint(with: strand.noteTable.map(\.noteID)))
    }

    @Test
    func init_defaults() {
        let strand = Strand<WallTime, NoteNumber>()

        #expect(strand.name.isEmpty)
        #expect(strand.noteTable.isEmpty)
        #expect(strand.instrumentTable == nil)
        #expect(strand.dynamicMap == nil)
        #expect(strand.extras == nil)
    }

    @Test
    func init_normalizesNameAndExtras() {
        var strand = Strand<BeatTime, Pitch>(name: "  Right\nHand ", extras: Extras(elements: []))

        #expect(strand.name == "Right Hand")
        #expect(strand.extras == nil)

        strand.name = " Pedals "
        strand.extras = Extras(elements: [])

        #expect(strand.name == "Pedals")
        #expect(strand.extras == nil)
    }
}
