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
    func transform_failure_wrapsErrorWithPartID() throws {
        let part = Part<BeatTime, Pitch>(name: "One")
        var body = try Self._body([part])

        do {
            try Work.transform(&body,
                               resolution: Work.Scope.all.resolved(in: body),
                               kind: .move) { (_: inout Part<BeatTime, Pitch>, _) throws(Part<BeatTime, Pitch>.Error) in
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
    func transform_all_transformsEveryPartWhole() throws {
        var body = try Self._body([Part(name: "One"), Part(name: "Two")])
        var selections: [Work.PartSelection] = []

        try Work.transform(&body,
                           resolution: Work.Scope.all.resolved(in: body),
                           kind: .move) { (part: inout Part<BeatTime, Pitch>, selection) throws(Part<BeatTime, Pitch>.Error) in
            part.name = "Changed"
            selections.append(selection)
        }

        #expect(body.parts.map(\.name) == ["Changed", "Changed"])
        #expect(selections == [.whole, .whole])
    }

    @Test
    func transform_someParts_leavesOthersInPlace() throws {
        let parts = [Part<BeatTime, Pitch>(name: "One"), Part<BeatTime, Pitch>(name: "Two")]
        var body = try Self._body(parts)

        try Work.transform(&body,
                           resolution: Work.Scope(parts: [parts[1].partID]).resolved(in: body),
                           kind: .move) { (part: inout Part<BeatTime, Pitch>, _) throws(Part<BeatTime, Pitch>.Error) in
            part.name = "Changed"
        }

        #expect(body.parts.map(\.name) == ["One", "Changed"])
        #expect(body.parts.map(\.partID) == parts.map(\.partID))
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

    // MARK: Private Type Methods

    private static func _body(_ parts: [Part<BeatTime, Pitch>]) throws -> Work.BeatBody<Pitch> {
        let work = Work(content: .standardBeat(parts, TempoMap(), MeterTable(), KeyTable()))

        return try #require(work.content.body as? Work.BeatBody<Pitch>)
    }
}
