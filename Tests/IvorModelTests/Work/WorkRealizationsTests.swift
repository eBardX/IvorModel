// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct WorkRealizationsTests {
}

// MARK: -

extension WorkRealizationsTests {
    @Test
    func codable_rejectsDuplicatePartIDs() throws {
        let part = Part<WallTime, Pitch>(name: "Cello")
        let data = try JSONEncoder().encode(Work(content: .standardWall([part, part])))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Work.self, from: data)
        }
    }

    @Test
    func codable_rejectsEmptyRealizations() throws {
        let data = try JSONEncoder().encode(Work())
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        object["realizations"] = [Any]()

        let emptied = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Work.self, from: emptied)
        }
    }

    @Test
    func codable_rejectsTableForUnknownPart() throws {
        let part = Part<WallTime, Pitch>(name: "Cello")
        let realization = try Realization(partTables: [part.partID: Self._table()])
        let withPart = try JSONEncoder().encode(Work(content: .standardWall([part]),
                                                     realizations: [realization]))
        var object = try #require(JSONSerialization.jsonObject(with: withPart) as? [String: Any])
        let emptyContent = try JSONEncoder().encode(Work.Content.standardWall([]))

        object["content"] = try JSONSerialization.jsonObject(with: emptyContent)

        let orphaned = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Work.self, from: orphaned)
        }
    }

    @Test
    func codable_roundTripsPartIDsAndRealizations() throws {
        let part = Part<WallTime, Pitch>(name: "Cello")
        let realization = try Realization(name: "My studio",
                                          partTables: [part.partID: Self._table()])
        let work = Work(content: .standardWall([part]),
                        realizations: [Realization(name: "General MIDI"), realization])
        let decoded = try JSONDecoder().decode(Work.self, from: JSONEncoder().encode(work))

        #expect(decoded.partIDs == [part.partID])
        #expect(decoded.realizations == work.realizations)
    }

    @Test
    func convert_keepsPartIDsAndRealizations() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        let realization = try Realization(partTables: [part.partID: Self._table()])
        let work = Work(content: .standardBeat([part], TempoMap()),
                        realizations: [realization])

        let result = try #require(try work.convert(timeBasis: .wall,
                                                   pitchNotation: .standard))

        #expect(result.partIDs == [part.partID])
        #expect(result.realizations == [realization])
    }

    @Test
    func duplicatePart_copiesTables() throws {
        var work = Work(content: .standardWall([]))
        let partID = try work.addPart(name: "Cello")
        let table = try Self._table()
        let realizationID = try #require(work.realizations.first?.realizationID)

        work.modifyRealization(realizationID) { $0[partID] = table }

        let duplicateID = try #require(try work.duplicatePart(partID))

        #expect(work.realizations.first?[duplicateID] == table)
    }

    @Test
    func duplicated_keepsRealizations() {
        let work = Work(realizations: [Realization(name: "General MIDI"), Realization(name: "My studio")])

        #expect(work.duplicated().realizations == work.realizations)
    }

    @Test
    func init_defaultRealization() {
        let work = Work()

        #expect(work.realizations.count == 1)
        #expect(work.realizations.first?.name == Work.defaultRealizationName)
    }

    @Test
    func init_dropsTablesForUnknownParts() throws {
        let work = try Work(realizations: [Realization(partTables: [PartID(): Self._table()])])

        #expect(work.realizations.first?.partTables.isEmpty == true)
    }

    @Test
    func modifyRealization_dropsTablesForUnknownParts() throws {
        var work = Work()
        let realizationID = try #require(work.realizations.first?.realizationID)
        let table = try Self._table()

        let result = work.modifyRealization(realizationID) { realization in
            realization[PartID()] = table
            realization.name = "My studio"

            return true
        }

        #expect(result == true)
        #expect(work.realizations.first?.name == "My studio")
        #expect(work.realizations.first?.partTables.isEmpty == true)
    }

    @Test
    func modifyRealization_lockedWork() throws {
        var work = Work()
        let realizationID = try #require(work.realizations.first?.realizationID)

        work.isLocked = true

        work.modifyRealization(realizationID) { $0.name = "My studio" }

        #expect(work.realizations.first?.name == "My studio")
    }

    @Test
    func modifyRealization_unknownID() {
        var work = Work()

        #expect(work.modifyRealization(RealizationID()) { _ in true } == nil)
    }

    @Test
    func realization_lookup() throws {
        let work = Work()
        let realizationID = try #require(work.realizations.first?.realizationID)

        #expect(work.realization(realizationID) == work.realizations.first)
        #expect(work.realization(RealizationID()) == nil)
    }

    @Test
    func removePart_dropsTables() throws {
        var work = Work(content: .standardWall([]))
        let partID = try work.addPart(name: "Cello")
        let realizationID = try #require(work.realizations.first?.realizationID)
        let table = try Self._table()

        work.modifyRealization(realizationID) { $0[partID] = table }

        try work.removePart(partID)

        #expect(work.realizations.first?.partTables.isEmpty == true)
    }

    @Test
    func replaceContent_dropsTablesForRemovedParts() throws {
        let part = Part<WallTime, Pitch>(name: "Cello")
        var work = try Work(content: .standardWall([part]),
                            realizations: [Realization(partTables: [part.partID: Self._table()])])

        try work.replaceContent(with: .standardWall([]))

        #expect(work.realizations.first?.partTables.isEmpty == true)
    }

    @Test
    func replaceRealizations() throws {
        var work = Work()
        let realizations = [Realization(name: "General MIDI"), Realization(name: "My studio")]

        try work.replaceRealizations(with: realizations)

        #expect(work.realizations == realizations)
    }

    @Test
    func replaceRealizations_duplicateID_throws() {
        var work = Work()
        let realization = Realization()

        #expect(throws: Work.Error.duplicateRealizationID(realization.realizationID)) {
            try work.replaceRealizations(with: [realization, realization])
        }
    }

    @Test
    func replaceRealizations_empty_throws() {
        var work = Work()

        #expect(throws: Work.Error.noRealizations) {
            try work.replaceRealizations(with: [])
        }
    }

    @Test
    func replaceRealizations_lockedWork() throws {
        var work = Work()
        let realizations = [Realization(name: "My studio")]

        work.isLocked = true

        try work.replaceRealizations(with: realizations)

        #expect(work.realizations == realizations)
    }

    @Test
    func warped_keepsPartIDsAndRealizations() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        let realization = try Realization(partTables: [part.partID: Self._table()])
        let work = Work(content: .standardBeat([part], TempoMap()),
                        realizations: [realization])

        let result = try #require(work.warped())

        #expect(result.partIDs == [part.partID])
        #expect(result.realizations == [realization])
    }
}

// MARK: -

extension WorkRealizationsTests {
    fileprivate static func _table() throws -> PatchTable {
        let patch = try #require(Patch(.generalMIDI1(program: 20)))
        let assignment = try #require(PatchTable.Assignment(patch: patch))

        return PatchTable([.vanilla: assignment])
    }
}
