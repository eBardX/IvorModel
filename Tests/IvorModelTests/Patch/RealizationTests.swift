// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiTools

struct RealizationTests {
}

// MARK: -

extension RealizationTests {
    @Test
    func assignment_partWinsOverDefaults() throws {
        let partID = PartID()
        let organ = try Self._assignment(program: 20)
        let piano = try Self._assignment(program: 1)
        let realization = Realization(defaults: PatchTable([.vanilla: piano]),
                                      partTables: [partID: PatchTable([.vanilla: organ])])

        #expect(realization.assignment(for: .vanilla, in: partID) == organ)
        #expect(realization.assignment(for: .vanilla, in: PartID()) == piano)
    }

    @Test
    func assignment_unassigned() {
        let realization = Realization()

        #expect(realization.assignment(for: .vanilla, in: PartID()) == nil)
    }

    @Test
    func codable_encodesInPartIDOrder() throws {
        let lowID = try #require(PartID(stringValue: "P$" + String(repeating: "A", count: 22)))
        let highID = try #require(PartID(stringValue: "P$" + String(repeating: "z", count: 22)))
        let table = try PatchTable([.vanilla: Self._assignment(program: 1)])
        let realization = Realization(partTables: [highID: table, lowID: table])

        let json = try #require(String(data: JSONEncoder().encode(realization), encoding: .utf8))
        let low = try #require(json.range(of: lowID.stringValue))
        let high = try #require(json.range(of: highID.stringValue))

        #expect(low.lowerBound < high.lowerBound)
    }

    @Test
    func codable_rejectsDuplicatePart() throws {
        let partID = PartID()
        let table = try PatchTable([.vanilla: Self._assignment(program: 1)])
        let data = try JSONEncoder().encode(Realization(partTables: [partID: table]))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let pairs = try #require(object["partTables"] as? [Any])

        object["partTables"] = pairs + pairs

        let duplicated = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Realization.self, from: duplicated)
        }
    }

    @Test
    func codable_roundTrip() throws {
        let original = try Realization(name: "My studio",
                                       defaults: PatchTable([.vanilla: Self._assignment(program: 1)]),
                                       partTables: [PartID(): PatchTable(["Chocolate": Self._assignment(program: 20,
                                                                                                        channel: 4)])])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Realization.self, from: data)

        #expect(decoded == original)
    }

    @Test
    func duplicated() throws {
        let original = try Realization(name: "General MIDI",
                                       partTables: [PartID(): PatchTable([.vanilla: Self._assignment(program: 1)])])
        let copy = original.duplicated()
        let renamed = original.duplicated(name: "My studio")

        #expect(copy.realizationID != original.realizationID)
        #expect(copy.name == original.name)
        #expect(copy.partTables == original.partTables)
        #expect(renamed.name == "My studio")
    }

    @Test
    func init_defaults() {
        let realization = Realization()

        #expect(realization.name.isEmpty)
        #expect(realization.defaults.isEmpty)
        #expect(realization.partTables.isEmpty)
    }

    @Test
    func init_dropsEmptyPartTables() {
        let realization = Realization(partTables: [PartID(): PatchTable()])

        #expect(realization.partTables.isEmpty)
    }

    @Test
    func init_normalizesName() {
        #expect(Realization(name: " My \n studio ").name == "My studio")
    }

    @Test
    func name_assignmentNormalizes() {
        var realization = Realization()

        realization.name = " General \n MIDI "

        #expect(realization.name == "General MIDI")
    }

    @Test
    func subscript_getAndSet() throws {
        let partID = PartID()
        let table = try PatchTable([.vanilla: Self._assignment(program: 1)])
        var realization = Realization()

        #expect(realization[partID].isEmpty)

        realization[partID] = table

        #expect(realization[partID] == table)
        #expect(realization.partTables == [partID: table])

        realization[partID] = PatchTable()

        #expect(realization.partTables.isEmpty)
    }
}

// MARK: -

extension RealizationTests {
    fileprivate static func _assignment(program: Int,
                                        channel: Int? = nil) throws -> PatchTable.Assignment {
        let patch = try #require(Patch(.generalMIDI1(program: program)))

        return try #require(PatchTable.Assignment(patch: patch,
                                                  channel: channel))
    }
}
