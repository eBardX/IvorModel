// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

//
// A beat-time work's meter table: its storage in `Work.Content`, access and editing, and how the
// whole-work transforms carry it (or don't).
//
struct WorkMeterTableTests {
}

// MARK: - Content

extension WorkMeterTableTests {
    @Test
    func content_codable_roundTripsNonEmptyTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4"), (frac(7, 4), "2+2+3/8")],
                                            pickup: frac(1, 4))
        let content = Work.Content.standardBeat([], TempoMap(), meterTable)
        let data = try JSONEncoder().encode(content)
        let decoded = try JSONDecoder().decode(Work.Content.self, from: data)

        guard case let .standardBeat(_, _, decodedTable) = decoded
        else { Issue.record("not standard beat"); return }

        #expect(decodedTable == meterTable)
        #expect(decodedTable.pickup == beats(frac(1, 4)))
    }

    @Test
    func content_decode_withoutMeterTable_fails() throws {
        let content = try Work.Content.keyboardBeat([], TempoMap(), makeMeterTable([(0, "6/8")]))
        let data = try JSONEncoder().encode(content)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object.removeValue(forKey: "meterTable") != nil)

        let stripped = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Work.Content.self, from: stripped)
        }
    }

    @Test
    func content_empty_beat_hasEmptyMeterTable() {
        for pitchNotation in [PitchNotation.absolute, .keyboard, .standard] {
            let work = Work(content: .empty(timeBasis: .beat, pitchNotation: pitchNotation))

            #expect(work.meterTable == MeterTable())
        }
    }

    @Test
    func meterTable_wallWork_isNil() {
        let work = Work(content: .empty(timeBasis: .wall, pitchNotation: .standard))

        #expect(work.meterTable == nil)
    }

    @Test
    func modifyMeterTable_editsTable() throws {
        var work = Work()

        let entryID = try work.modifyMeterTable { table in
            try? table.insert(beatTime: .zero, meter: meter("5/8"))
        }

        #expect(entryID != nil)
        #expect(work.meterTable?.map(\.meter) == [meter("5/8")])
    }

    @Test
    func modifyMeterTable_lockedWork_throws() {
        var work = Work()

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.modifyMeterTable { _ in }
        }
    }

    @Test
    func modifyMeterTable_wallWork_returnsNilWithoutCallingBody() throws {
        var work = Work(content: .empty(timeBasis: .wall, pitchNotation: .standard))
        var called = false

        let result: Void? = try work.modifyMeterTable { _ in called = true }

        #expect(result == nil)
        #expect(!called)
    }
}

// MARK: - Augment and diminish

extension WorkMeterTableTests {
    @Test
    func augment_defaultAnchor_includesMeterEntries() throws {
        //
        // The meter starts at 0 and the only note at 1. With the meter table carried, the default
        // anchor is 0 and the rest before the note scales; without it, the anchor is the note.
        //
        let work = try makeMeterWork(meterTable: makeMeterTable([(0, "4/4")]),
                                     notes: [1])
        var carried = work
        var notCarried = work

        try carried.augment(by: 2, anchor: nil as BeatTime?)
        try notCarried.augment(by: 2, anchor: nil as BeatTime?, applyTo: [])

        #expect(carried.beatTimeRange?.lowerBound == 2)
        #expect(notCarried.beatTimeRange?.lowerBound == 1)
    }

    @Test
    func augment_keepingSound_preservesWallTimes() throws {
        //
        // 3/8 at ♪ = 240 augmented by 2 is 3/4 at ♩ = 240, and sounds the same, ramp and all.
        //
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: .zero, tempo: Tempo(240, unit: .eighth))
        tempoMap.insert(beatTime: beatTime(frac(3, 2)), tempo: Tempo(180, unit: .eighth))

        let work = try makeMeterWork(meterTable: makeMeterTable([(0, "3/8")]),
                                     tempoMap: tempoMap,
                                     notes: [0, frac(1, 8), frac(3, 8), frac(3, 4), frac(9, 8), 2])
        var augmented = work

        try augmented.augment(by: 2, anchor: nil as BeatTime?, keepingSound: true)

        try expectSameWallTimes(augmented, work)
        #expect(augmented.meterTable?.map(\.meter) == [meter("3/4")])
        #expect(augmented.tempoMap?.first?.tempo == Tempo(240, unit: .quarter))
    }

    @Test
    func augment_keepingSound_withoutTempo_doesNothing() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: .zero, tempo: Tempo(240, unit: .eighth))

        let work = try makeMeterWork(meterTable: makeMeterTable([(0, "3/8")]),
                                     tempoMap: tempoMap,
                                     notes: [0, frac(3, 8)])
        let applyTo = TransformTargets.all.subtracting(.tempo)
        var keeping = work
        var plain = work

        try keeping.augment(by: 2, anchor: nil as BeatTime?, applyTo: applyTo, keepingSound: true)
        try plain.augment(by: 2, anchor: nil as BeatTime?, applyTo: applyTo)

        #expect(keeping.tempoMap == work.tempoMap)
        #expect(keeping.tempoMap == plain.tempoMap)
        #expect(keeping.meterTable == plain.meterTable)
        #expect(keeping.beatTimeRange == plain.beatTimeRange)
    }

    @Test
    func augment_onePartOfTwo_withoutMeter_keepsTable() throws {
        var violin = Part<BeatTime, Pitch>(name: "Violin")
        var cello = Part<BeatTime, Pitch>(name: "Cello")

        violin.noteTable.insert(attack: 0, duration: .quarter, pitch: .c4)
        cello.noteTable.insert(attack: 0, duration: .quarter, pitch: .c3)

        let meterTable = try makeMeterTable([(0, "3/4"), (frac(3, 2), "2/4")])
        var work = Work(content: .standardBeat([violin, cello], TempoMap(), meterTable))

        try work.augment(by: 2,
                         anchor: nil as BeatTime?,
                         applyTo: TransformTargets.all.subtracting([.tempo, .meter]),
                         partIDs: [violin.partID])

        #expect(work.meterTable == meterTable)
        #expect(work.part(violin.partID, as: Part<BeatTime, Pitch>.self)?.noteTable.first?.duration == .half)
    }

    @Test
    func augment_withMeter_renotatesTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4"), (frac(3, 2), "2+2+3/8")],
                                            pickup: frac(1, 4))
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(1, 4), 1, 2])
        var expected = meterTable

        try expected.augment(by: frac(3, 2))
        try work.augment(by: frac(3, 2), anchor: nil as BeatTime?)

        #expect(work.meterTable == expected)
        #expect(work.meterTable?.map(\.meter) == [meter("9/8"), meter("6+6+9/16")])
        #expect(work.meterTable?.pickup == beats(frac(3, 8)))
    }

    @Test
    func augment_withMeter_invalidFactor_throwsMeterTableTransformFailure() throws {
        var work = try makeMeterWork(meterTable: makeMeterTable([(0, "3/4")]),
                                     notes: [])

        #expect(throws: Work.Error.meterTableTransformFailure(kind: .augment,
                                                              detail: MeterTable.Error.invalidAugmentationFactor(frac(1, 2)).message)) {
            try work.augment(by: frac(1, 2), anchor: nil as BeatTime?, applyTo: [.meter], partIDs: [])
        }
    }

    @Test
    func augment_withoutMeter_keepsTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(3, 4)])

        try work.augment(by: 2, anchor: nil as BeatTime?, applyTo: TransformTargets.all.subtracting(.meter))

        #expect(work.meterTable == meterTable)
        #expect(work.beatTimeRange?.lowerBound == .zero)
        #expect(work.beatTimeRange?.upperBound == beatTime(frac(7, 4)))
    }

    @Test
    func diminish_keepingSound_preservesWallTimes() throws {
        //
        // 3/4 at ♩ = 240 diminished by 2 is 3/8 at ♪ = 240.
        //
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: .zero, tempo: Tempo(240))

        let work = try makeMeterWork(meterTable: makeMeterTable([(0, "3/4")]),
                                     tempoMap: tempoMap,
                                     notes: [0, frac(1, 4), frac(3, 4), frac(7, 4)])
        var diminished = work

        try diminished.diminish(by: 2, anchor: nil as BeatTime?, keepingSound: true)

        try expectSameWallTimes(diminished, work)
        #expect(diminished.meterTable?.map(\.meter) == [meter("3/8")])
        #expect(diminished.tempoMap?.first?.tempo == Tempo(240, unit: .eighth))
    }

    @Test
    func diminish_withMeter_renotatesTable() throws {
        let meterTable = try makeMeterTable([(0, "6/8"), (frac(3, 2), "3/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(3, 8), 2])
        var expected = meterTable

        try expected.diminish(by: 3)
        try work.diminish(by: 3, anchor: nil as BeatTime?)

        #expect(work.meterTable == expected)
        #expect(work.meterTable?.map(\.meter) == [meter("6/24"), meter("3/12")])
    }

    @Test
    func diminish_withoutMeter_keepsTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(3, 4)])

        try work.diminish(by: 2, anchor: nil as BeatTime?, applyTo: [.tempo])

        #expect(work.meterTable == meterTable)
    }
}

// MARK: - Move and reverse

extension WorkMeterTableTests {
    @Test
    func move_withMeter_movesTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4"), (frac(3, 2), "2/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(3, 4)])
        let shift = DirectedDuration(duration: BeatDuration.quarter, direction: .forward)
        var expected = meterTable

        expected.move(by: shift)

        try work.move(by: shift)

        #expect(work.meterTable == expected)
        #expect(work.meterTable?.first?.beatTime == .zero)
        #expect(work.meterTable?.pickup == .quarter)
        #expect(work.meterTable?.position(at: beatTime(frac(1, 4)))?.bar == 1)
        #expect(work.meterTable?.position(at: beatTime(frac(1, 4)))?.beat == 1)
    }

    @Test
    func move_withoutMeter_keepsTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0])

        try work.move(by: DirectedDuration(duration: BeatDuration.quarter, direction: .forward),
                      applyTo: [.tempo])

        #expect(work.meterTable == meterTable)
        #expect(work.beatTimeRange?.lowerBound == beatTime(frac(1, 4)))
    }

    @Test
    func reverse_withMeter_reversesTable() throws {
        //
        // Bars of 3/4 then 2/4, with the music ending 1/4 into the 2/4 bar, reverse to a 2/4
        // pickup of 1/4, then 3/4 from 1/4.
        //
        let meterTable = try makeMeterTable([(0, "3/4"), (frac(3, 4), "2/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(1, 2), frac(3, 4)])
        var expected = meterTable

        expected.reverse(within: .zero...beatTime(1))

        try work.reverse(within: .zero...beatTime(1))

        #expect(work.meterTable == expected)
        #expect(work.meterTable?.first?.meter == meter("2/4"))
        #expect(work.meterTable?.pickup == .quarter)
        #expect(work.meterTable?.meter(at: beatTime(frac(1, 4))) == meter("3/4"))
    }

    @Test
    func reverse_withoutMeter_keepsTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4"), (frac(3, 4), "2/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(3, 4)])

        try work.reverse(within: .zero...beatTime(1), applyTo: [.tempo])

        #expect(work.meterTable == meterTable)
    }
}

// MARK: - Quantize, warp and convert

extension WorkMeterTableTests {
    @Test
    func convert_pitchNotation_keepsTable() throws {
        let meterTable = try makeMeterTable([(0, "6/8")])
        let work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0])
        let converted = try #require(try work.convert(timeBasis: .beat, pitchNotation: .keyboard))

        #expect(converted.meterTable == meterTable)
    }

    @Test
    func convert_wallAndBack_startsWithEmptyTable() throws {
        let work = try makeMeterWork(meterTable: makeMeterTable([(0, "6/8")]),
                                     notes: [0])
        let wall = try #require(try work.convert(timeBasis: .wall, pitchNotation: .standard))
        let beat = try #require(try wall.convert(timeBasis: .beat, pitchNotation: .standard))

        #expect(wall.meterTable == nil)
        #expect(beat.meterTable == MeterTable())
    }

    @Test
    func quantize_leavesTableAlone() throws {
        //
        // An entry off the quantize grid stays put: meters mark notation, not sound.
        //
        let meterTable = try makeMeterTable([(0, "4/4"), (frac(1, 3), "3/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [frac(1, 3)])

        try work.quantize(to: [4], applyTo: .all)

        #expect(work.meterTable == meterTable)
        #expect(work.beatTimeRange?.lowerBound == beatTime(frac(1, 4)))
    }

    @Test
    func unwarped_startsWithEmptyTable() throws {
        let work = try makeMeterWork(meterTable: makeMeterTable([(0, "6/8")]),
                                     notes: [0])
        let wall = try #require(work.warped())
        let unwarped = try #require(wall.unwarped(using: TempoMap()))

        #expect(unwarped.meterTable == MeterTable())
    }

    @Test
    func warped_dropsTable() throws {
        let work = try makeMeterWork(meterTable: makeMeterTable([(0, "6/8")]),
                                     notes: [0])

        #expect(try #require(work.warped()).meterTable == nil)
    }
}

// MARK: - Private helpers

extension WorkMeterTableTests {
    private func expectSameWallTimes(_ lhs: Work,
                                     _ rhs: Work,
                                     sourceLocation: SourceLocation = #_sourceLocation) throws {
        let lhsTimes = try wallAttacks(of: lhs)
        let rhsTimes = try wallAttacks(of: rhs)

        #expect(lhsTimes.count == rhsTimes.count, sourceLocation: sourceLocation)

        //
        // Wall times are kept in microseconds, so allow for a rounding step either way.
        //
        for (lhsTime, rhsTime) in zip(lhsTimes, rhsTimes) {
            #expect(abs(lhsTime - rhsTime) < 2e-6, "\(lhsTimes) ≠ \(rhsTimes)", sourceLocation: sourceLocation)
        }
    }

    private func makeMeterWork(meterTable: MeterTable,
                               tempoMap: TempoMap = TempoMap(),
                               notes attacks: [Number]) throws -> Work {
        var part = Part<BeatTime, Pitch>(name: "Piano")

        for attack in attacks {
            part.noteTable.insert(attack: beatTime(attack), duration: beats(frac(1, 8)), pitch: .c4)
        }

        return Work(content: .standardBeat([part], tempoMap, meterTable))
    }

    private func wallAttacks(of work: Work) throws -> [Double] {
        guard case let .standardBeat(parts, tempoMap, _) = work.content
        else { throw Work.Error.timeBasisMismatch(expected: .beat) }

        let converter = TimeConverter(tempoMap: tempoMap)

        return try #require(parts.first).noteTable.map { converter.wallTime(at: $0.attack).doubleValue }
    }
}
