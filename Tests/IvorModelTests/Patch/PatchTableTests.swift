// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiTools

struct PatchTableTests {
}

// MARK: -

extension PatchTableTests {
    @Test
    func codable_encodesInInstrumentOrder() throws {
        var table = PatchTable()

        table["Zither"] = try Self._assignment(program: 2)
        table["Alto"] = try Self._assignment(program: 1)

        let json = try #require(String(data: JSONEncoder().encode(table), encoding: .utf8))
        let alto = try #require(json.range(of: "Alto"))
        let zither = try #require(json.range(of: "Zither"))

        #expect(alto.lowerBound < zither.lowerBound)
    }

    @Test
    func codable_rejectsDuplicateInstrument() {
        let entry = #"["Vanilla",{"patch":{"generalMIDI1":{"program":1}}}]"#

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PatchTable.self, from: Data("[\(entry),\(entry)]".utf8))
        }
    }

    @Test
    func codable_roundTrip() throws {
        let original = try PatchTable([.vanilla: Self._assignment(program: 1),
                                       "Chocolate": Self._assignment(program: 20, channel: 4)])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PatchTable.self, from: data)

        #expect(decoded == original)
    }

    @Test
    func init_empty() {
        let table = PatchTable()

        #expect(table.instruments.isEmpty)
        #expect(table.isEmpty)
    }

    @Test
    func instruments_sorted() throws {
        let table = try PatchTable(["Zither": Self._assignment(program: 2),
                                    "Alto": Self._assignment(program: 1)])

        #expect(table.instruments == ["Alto", "Zither"])
    }

    @Test
    func subscript_setsAndRemoves() throws {
        var table = PatchTable()
        let organ = try Self._assignment(program: 20)

        table[.vanilla] = organ

        #expect(table[.vanilla] == organ)
        #expect(table.count == 1)

        table[.vanilla] = nil

        #expect(table[.vanilla] == nil)
        #expect(table.isEmpty)
    }
}

// MARK: -

extension PatchTableTests {
    fileprivate static func _assignment(program: Int,
                                        channel: Int? = nil) throws -> PatchTable.Assignment {
        let patch = try #require(Patch(.generalMIDI1(program: program)))

        return try #require(PatchTable.Assignment(patch: patch,
                                                  channel: channel))
    }
}
