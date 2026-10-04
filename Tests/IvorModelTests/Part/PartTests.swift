// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct PartTests {
}

// MARK: -

extension PartTests {
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
        #expect(decoded.instrumentMap.isEmpty)
        #expect(decoded.panMap.isEmpty)
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
    func duplicated() {
        let original = Part<BeatTime, Pitch>(name: "Piano")
        let duplicate = original.duplicated()

        #expect(duplicate.partID != original.partID)
        #expect(duplicate.name == original.name)
        #expect(duplicate.dynamicMap.isEmpty == original.dynamicMap.isEmpty)
        #expect(duplicate.instrumentMap.isEmpty == original.instrumentMap.isEmpty)
        #expect(duplicate.panMap.isEmpty == original.panMap.isEmpty)
    }

    @Test
    func init_defaults() {
        let part = Part<BeatTime, Pitch>(name: "Piano")

        #expect(part.name == "Piano")
        #expect(part.timeRange == nil)
        #expect(part.dynamicMap.isEmpty)
        #expect(part.instrumentMap.isEmpty)
        #expect(part.panMap.isEmpty)
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
    func name_assignmentNormalizes() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.name = " Viola \n da  gamba "

        #expect(part.name == "Viola da gamba")
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
