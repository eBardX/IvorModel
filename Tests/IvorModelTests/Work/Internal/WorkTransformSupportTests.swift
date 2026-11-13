// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkTransformSupportTests {
}

// MARK: -

extension WorkTransformSupportTests {
    @Test
    func carried_failure_throwsTempoMapTransformFailure() {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 3, tempo: .default)

        do {
            _ = try Work.carried(tempoMap: tempoMap,
                                 applyTo: .all,
                                 kind: .augment) { (map: inout TempoMap) throws(TempoMap.Error) in
                try map.augment(by: Number(numerator: 1, denominator: 2))
            }

            Issue.record("Expected an error")
        } catch {
            guard case .tempoMapTransformFailure(kind: .augment, detail: _) = error
            else { Issue.record("Unexpected error: \(error)"); return }
        }
    }

    @Test
    func carried_meterTable_failure_throwsMeterTableTransformFailure() throws {
        let meterTable = try makeMeterTable([(0, "3/4")])

        do {
            _ = try Work.carried(meterTable: meterTable,
                                 applyTo: .all,
                                 kind: .augment) { (table: inout MeterTable) throws(MeterTable.Error) in
                try table.augment(by: frac(1, 2))
            }

            Issue.record("Expected an error")
        } catch {
            guard case .meterTableTransformFailure(kind: .augment, detail: _) = error
            else { Issue.record("Unexpected error: \(error)"); return }
        }
    }

    @Test
    func carried_meterTable_withMeter_appliesTransform() throws {
        let meterTable = try makeMeterTable([(0, "3/4")])
        let result = try Work.carried(meterTable: meterTable,
                                      applyTo: [.meter],
                                      kind: .augment) { (table: inout MeterTable) throws(MeterTable.Error) in
            try table.augment(by: 2)
        }

        #expect(result.map(\.meter) == [meter("3/2")])
    }

    @Test
    func carried_meterTable_withoutMeter_leavesTableUnchanged() throws {
        let meterTable = try makeMeterTable([(0, "3/4")])
        let result = try Work.carried(meterTable: meterTable,
                                      applyTo: [.tempo, .dynamic],
                                      kind: .augment) { (table: inout MeterTable) throws(MeterTable.Error) in
            try table.augment(by: 2)
        }

        #expect(result == meterTable)
    }

    @Test
    func carried_withoutTempo_leavesMapUnchanged() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 3, tempo: .default)

        let result = try Work.carried(tempoMap: tempoMap,
                                      applyTo: [.dynamic, .pan],
                                      kind: .augment) { (map: inout TempoMap) throws(TempoMap.Error) in
            try map.augment(by: 2, anchor: 0)
        }

        #expect(result.map(\.beatTime) == [3])
    }

    @Test
    func carried_withTempo_appliesTransform() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 3, tempo: .default)

        let result = try Work.carried(tempoMap: tempoMap,
                                      applyTo: [.tempo],
                                      kind: .augment) { (map: inout TempoMap) throws(TempoMap.Error) in
            try map.augment(by: 2, anchor: 0)
        }

        #expect(result.map(\.beatTime) == [6])
    }

    @Test
    func scaleRampDurations_leavesEntriesWithoutRamp() {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 4, tempo: .default, extras: makeChannelExtras(1))

        Work.scaleRampDurations(in: &tempoMap, by: 2)

        #expect(tempoMap.map(\.extras) == [nil, makeChannelExtras(1)])
    }

    @Test
    func scaleRampDurations_scalesRampDuration() {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0,
                        tempo: .default,
                        extras: Extras(elements: [Extra(name: Extra.rampDuration.name, values: [.double(4)])]))

        Work.scaleRampDurations(in: &tempoMap, by: 0.5)

        #expect(extraValues(.rampDuration, in: tempoMap.first?.extras) == [.double(2)])
    }

    @Test
    func selected_filtersByPartID() {
        let part1 = Part<BeatTime, Pitch>(name: "One")
        let part2 = Part<BeatTime, Pitch>(name: "Two")

        let result = Work.selected([part1, part2], partIDs: [part2.partID])

        #expect(result.map(\.partID) == [part2.partID])
    }

    @Test
    func selected_nil_returnsEveryPart() {
        let parts = [Part<BeatTime, Pitch>(name: "One"), Part<BeatTime, Pitch>(name: "Two")]

        #expect(Work.selected(parts, partIDs: nil).map(\.partID) == parts.map(\.partID))
    }

    @Test
    func selected_unknownIDs_returnsNoParts() {
        let parts = [Part<BeatTime, Pitch>(name: "One")]

        #expect(Work.selected(parts, partIDs: [PartID()]).isEmpty)
    }

    @Test
    func transformed_failure_wrapsErrorWithPartID() {
        let part = Part<BeatTime, Pitch>(name: "One")

        do {
            _ = try Work.transformed(parts: [part],
                                     partIDs: nil,
                                     kind: .move) { (_: inout Part<BeatTime, Pitch>) throws(Part<BeatTime, Pitch>.Error) in
                throw .panMapFailure(.invalidAnchor)
            }

            Issue.record("Expected an error")
        } catch {
            #expect(error == .panMapTransformFailure(kind: .move,
                                                     partID: part.partID,
                                                     detail: PanMap<BeatTime>.Error.invalidAnchor.message))
        }
    }

    @Test
    func transformed_nil_transformsEveryPart() throws {
        let parts = [Part<BeatTime, Pitch>(name: "One"), Part<BeatTime, Pitch>(name: "Two")]

        let result = try Work.transformed(parts: parts,
                                          partIDs: nil,
                                          kind: .move) { (part: inout Part<BeatTime, Pitch>) throws(Part<BeatTime, Pitch>.Error) in
            part.name = "Changed"
        }

        #expect(result.map(\.name) == ["Changed", "Changed"])
    }

    @Test
    func transformed_selected_leavesOthersInPlace() throws {
        let parts = [Part<BeatTime, Pitch>(name: "One"), Part<BeatTime, Pitch>(name: "Two")]

        let result = try Work.transformed(parts: parts,
                                          partIDs: [parts[1].partID],
                                          kind: .move) { (part: inout Part<BeatTime, Pitch>) throws(Part<BeatTime, Pitch>.Error) in
            part.name = "Changed"
        }

        #expect(result.map(\.name) == ["One", "Changed"])
        #expect(result.map(\.partID) == parts.map(\.partID))
    }

    @Test
    func wrapped_dynamicMapFailure() {
        let partID = PartID()
        let underlying = DynamicMap<BeatTime>.Error.invalidAnchor

        let error = Work.wrapped(error: Part<BeatTime, Pitch>.Error.dynamicMapFailure(underlying),
                                 kind: .reverse,
                                 partID: partID)

        #expect(error == .dynamicMapTransformFailure(kind: .reverse, partID: partID, detail: underlying.message))
    }

    @Test
    func wrapped_instrumentTableFailure() {
        let partID = PartID()
        let underlying = InstrumentTable<BeatTime>.Error.invalidAnchor

        let error = Work.wrapped(error: Part<BeatTime, Pitch>.Error.instrumentTableFailure(underlying),
                                 kind: .reverse,
                                 partID: partID)

        #expect(error == .instrumentTableTransformFailure(kind: .reverse, partID: partID, detail: underlying.message))
    }

    @Test
    func wrapped_noteTableFailure() {
        let partID = PartID()
        let underlying = NoteTable<BeatTime, Pitch>.Error.invalidAnchor

        let error = Work.wrapped(error: Part<BeatTime, Pitch>.Error.noteTableFailure(underlying),
                                 kind: .invert,
                                 partID: partID)

        #expect(error == .transformFailure(kind: .invert, partID: partID, detail: underlying.message))
    }

    @Test
    func wrapped_panMapFailure() {
        let partID = PartID()
        let underlying = PanMap<BeatTime>.Error.invalidAnchor

        let error = Work.wrapped(error: Part<BeatTime, Pitch>.Error.panMapFailure(underlying),
                                 kind: .move,
                                 partID: partID)

        #expect(error == .panMapTransformFailure(kind: .move, partID: partID, detail: underlying.message))
    }
}
