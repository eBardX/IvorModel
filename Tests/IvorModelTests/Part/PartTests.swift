// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct PartTests {
}

// MARK: -

extension PartTests {
    private typealias PartSB = Part<BeatTime, Pitch>

    @Test
    func attackingIn_matching() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        let matchID = part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)

        part.noteTable.insert(attack: 5, duration: 1, pitch: .e4)

        let result = part.attackingIn(0...2)

        #expect(result == [matchID])
    }

    @Test
    func attackingIn_notMatching() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 5, duration: 1, pitch: .c4)

        let result = part.attackingIn(0...2)

        #expect(result.isEmpty)
    }

    @Test
    func codable() throws {
        let original = Part<BeatTime, Pitch>(name: "Violin")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Part<BeatTime, Pitch>.self, from: data)

        #expect(decoded.name == original.name)
        #expect(decoded.timeRange == nil)
        #expect(decoded.dynamicMap.isEmpty)
        #expect(decoded.instrumentTable.isEmpty)
        #expect(decoded.panMap.isEmpty)
    }

    @Test
    func codable_extrasRoundTrip() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin", extras: makeChannelExtras(3))
        let decoded = try JSONDecoder().decode(Part<BeatTime, Pitch>.self, from: JSONEncoder().encode(part))

        #expect(decoded.extras == part.extras)
    }

    @Test
    func codable_keepsPartID() throws {
        let original = Part<BeatTime, Pitch>(name: "Violin")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Part<BeatTime, Pitch>.self, from: data)

        #expect(decoded.partID == original.partID)
    }

    @Test
    func codable_missingPedalsKeyThrows() throws {
        let data = try JSONEncoder().encode(Part<BeatTime, Pitch>(name: "Violin"))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        object["pedals"] = nil

        let stripped = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Part<BeatTime, Pitch>.self, from: stripped)
        }
    }

    @Test
    func codable_noExtrasOmitsKey() throws {
        let data = try JSONEncoder().encode(Part<BeatTime, Pitch>(name: "Violin"))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["extras"] == nil)
        #expect(try JSONDecoder().decode(Part<BeatTime, Pitch>.self, from: data).extras == nil)
    }

    @Test
    func codable_noPedalsEncodesEmptyObject() throws {
        let data = try JSONEncoder().encode(Part<BeatTime, Pitch>(name: "Violin"))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let pedals = try #require(object["pedals"] as? [String: Any])

        #expect(pedals.isEmpty)
    }

    @Test
    func codable_normalizesName() throws {
        let data = try JSONEncoder().encode(Part<BeatTime, Pitch>(name: "Violin"))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        object["name"] = " Violin \n 1 "

        let decoded = try JSONDecoder().decode(Part<BeatTime, Pitch>.self,
                                               from: JSONSerialization.data(withJSONObject: object))

        #expect(decoded.name == "Violin 1")
    }

    @Test
    func codable_omitsEmptyMarksAndNilRules() throws {
        let data = try JSONEncoder().encode(PartSB(name: "Empty"))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["markTable"] == nil)
        #expect(object["interpretationRules"] == nil)

        let decoded = try JSONDecoder().decode(PartSB.self, from: data)

        #expect(decoded.markTable.isEmpty)
        #expect(decoded.interpretationRules == nil)
    }

    @Test
    func codable_pedalsRoundTrip() throws {
        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 1, level: .down)
        sustain.insert(time: 3, level: .up)
        sustain.insert(time: 3, level: .down)

        let part = Part<BeatTime, Pitch>(name: "Piano", pedals: [.sustain: sustain])
        let decoded = try JSONDecoder().decode(Part<BeatTime, Pitch>.self, from: JSONEncoder().encode(part))

        #expect(Array(decoded.pedals.keys) == [.sustain])
        #expect(decoded.pedals[.sustain]?.map(\.time) == [1, 3, 3])
        #expect(decoded.pedals[.sustain]?.map(\.level) == [.down, .up, .down])
    }

    @Test
    func codable_roundTrip() throws {
        var original = markedPart()

        original.interpretationRules = markedPartRules()

        let decoded = try codingRoundTrip(original)

        #expect(decoded.markTable.map(\.time) == original.markTable.map(\.time))
        #expect(decoded.markTable.map(\.mark) == original.markTable.map(\.mark))
        #expect(decoded.interpretationRules == markedPartRules())
    }

    @Test
    func duplicated() {
        let original = Part<BeatTime, Pitch>(name: "Piano")
        let duplicate = original.duplicated()

        #expect(duplicate.partID != original.partID)
        #expect(duplicate.name == original.name)
        #expect(duplicate.dynamicMap.isEmpty == original.dynamicMap.isEmpty)
        #expect(duplicate.instrumentTable.isEmpty == original.instrumentTable.isEmpty)
        #expect(duplicate.panMap.isEmpty == original.panMap.isEmpty)
    }

    @Test
    func duplicated_givesNotesFreshIDs() throws {
        var noteTable = NoteTable<BeatTime, Pitch>()

        noteTable.insert(attack: 0, duration: 1, pitch: .c4, extras: sampleExtras("first"))
        noteTable.insert(attack: 1, duration: 1, startPitch: .d4, endPitch: .e4)
        try noteTable.insert(attack: 2, duration: 1, pitch: .g4, ornamentation: fullOrnamentation())

        let original = Part<BeatTime, Pitch>(name: "Piano", noteTable: noteTable)
        let copy = original.duplicated()

        #expect(Set(copy.noteTable.map(\.noteID)).isDisjoint(with: original.noteTable.map(\.noteID)))
        #expect(copy.noteTable.count == original.noteTable.count)

        for (copied, kept) in zip(copy.noteTable, original.noteTable) {
            #expect(copied.attack == kept.attack)
            #expect(copied.duration == kept.duration)
            #expect(copied.startPitch == kept.startPitch)
            #expect(copied.endPitch == kept.endPitch)
            #expect(copied.extras == kept.extras)
            #expect(copied.ornamentation == kept.ornamentation)
        }
    }

    @Test
    func duplicated_keepsExtras() {
        let part = Part<BeatTime, Pitch>(name: "Violin", extras: makeChannelExtras(3))

        #expect(part.duplicated().extras == part.extras)
    }

    @Test
    func duplicated_keepsMarksAndRules() {
        var original = markedPart()

        original.interpretationRules = markedPartRules()

        let copy = original.duplicated()

        #expect(copy.partID != original.partID)
        #expect(copy.markTable.map(\.mark) == original.markTable.map(\.mark))
        #expect(copy.interpretationRules == markedPartRules())
    }

    @Test
    func duplicated_keepsPedals() {
        var soft = PedalTable<BeatTime>()

        soft.insert(time: 2, level: .down)

        let part = Part<BeatTime, Pitch>(name: "Piano", pedals: [.soft: soft])

        #expect(part.duplicated().pedals[.soft]?.map(\.time) == [2])
    }

    @Test
    func extras_emptyAssignmentBecomesNil() {
        var part = Part<BeatTime, Pitch>(name: "Violin", extras: makeChannelExtras(3))

        part.extras = Extras()

        #expect(part.extras == nil)
    }

    @Test
    func init_defaults() {
        let part = Part<BeatTime, Pitch>(name: "Piano")

        #expect(part.name == "Piano")
        #expect(part.timeRange == nil)
        #expect(part.dynamicMap.isEmpty)
        #expect(part.instrumentTable.isEmpty)
        #expect(part.panMap.isEmpty)
        #expect(part.pedals.isEmpty)
    }

    @Test
    func init_dropsEmptyPedalTables() {
        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0, level: .down)

        let part = Part<BeatTime, Pitch>(name: "Piano",
                                         pedals: [.sostenuto: PedalTable(), .sustain: sustain])

        #expect(Array(part.pedals.keys) == [.sustain])
    }

    @Test
    func init_emptyExtrasBecomeNil() {
        #expect(Part<BeatTime, Pitch>(name: "Violin", extras: Extras()).extras == nil)
    }

    @Test
    func init_extras() {
        #expect(Part<BeatTime, Pitch>(name: "Violin", extras: makeChannelExtras(3)).extras == makeChannelExtras(3))
    }

    @Test
    func init_generatesUniquePartID() {
        let part1 = Part<BeatTime, Pitch>(name: "Piano")
        let part2 = Part<BeatTime, Pitch>(name: "Piano")

        #expect(part1.partID != part2.partID)
    }

    @Test
    func init_name() {
        let part = Part<BeatTime, Pitch>(name: "Cello")

        #expect(part.name == "Cello")
    }

    @Test
    func init_normalizesName() {
        #expect(Part<BeatTime, Pitch>(name: "  Violin\t 1 ").name == "Violin 1")
        #expect(Part<BeatTime, Pitch>(name: "   ").name.isEmpty)
    }

    @Test
    func interpretationRules_emptyIsStoredAsNil() {
        var part = PartSB(name: "Test", interpretationRules: InterpretationRules())

        #expect(part.interpretationRules == nil)

        part.interpretationRules = InterpretationRules(grace: GraceRules())

        #expect(part.interpretationRules == nil)
    }

    @Test
    func name_assignmentNormalizes() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.name = " Viola \n da  gamba "

        #expect(part.name == "Viola da gamba")
    }

    @Test
    func pedals_assignmentDropsEmptyTables() {
        var part = Part<BeatTime, Pitch>(name: "Piano")

        part.pedals[.legato] = PedalTable()

        #expect(part.pedals.isEmpty)

        part.pedals[.legato, default: PedalTable()].insert(time: 1, level: .down)

        #expect(part.pedals[.legato]?.count == 1)

        if let entryID = part.pedals[.legato]?.first?.entryID {
            part.pedals[.legato]?.remove(entryID: entryID)
        }

        #expect(part.pedals.isEmpty)
    }

    @Test
    func pitchIn_matching() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        let matchID = part.noteTable.insert(attack: 0, duration: 1, pitch: .e4)

        part.noteTable.insert(attack: 1, duration: 1, pitch: .a4)

        let result = part.pitchIn(.c4...(.g4))

        #expect(result == [matchID])
    }

    @Test
    func pitchIn_notMatching() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .a4)

        let result = part.pitchIn(.c4...(.g4))

        #expect(result.isEmpty)
    }

    @Test
    func soundingIn_matching() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        // Attacks before the range, but sustains through it.
        let overlapID = part.noteTable.insert(attack: 0, duration: 10, pitch: .c4)

        let result = part.soundingIn(5...6)

        #expect(result == [overlapID])
    }

    @Test
    func soundingIn_notMatching() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 10, duration: 1, pitch: .c4)

        let result = part.soundingIn(0...2)

        #expect(result.isEmpty)
    }

    @Test
    func timeRange_empty() {
        let part = Part<BeatTime, Pitch>(name: "Flute")

        #expect(part.timeRange == nil)
    }
}
