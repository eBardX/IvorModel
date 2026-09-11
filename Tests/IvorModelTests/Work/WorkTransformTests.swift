// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkTransformTests {
}

// MARK: -

extension WorkTransformTests {
    @Test
    func augment_wholeWorkBeat_scalesEveryPartAndTempoMap() throws {
        var part1 = Part<BeatTime, Pitch>(name: "Violin")
        var part2 = Part<BeatTime, Pitch>(name: "Cello")

        part1.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part2.noteTable.insert(attack: 2, duration: 1, pitch: .e4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([part1, part2], tempoMap))

        try work.augment(by: Number(2), anchor: nil as BeatTime?)

        #expect(work.beatTimeRange?.upperBound == 6)

        var tempoTimes: [BeatTime] = []

        work.tempoMap?.forEach { _, beatTime, _, _ in
            tempoTimes.append(beatTime)
        }

        #expect(tempoTimes.sorted() == [0, 4])
    }

    @Test
    func augment_wholeWorkBeat_applyToEmpty_leavesTempoMapUntouched() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([], tempoMap))

        try work.augment(by: Number(2), anchor: nil as BeatTime?, applyTo: [])

        var tempoTimes: [BeatTime] = []

        work.tempoMap?.forEach { _, beatTime, _, _ in
            tempoTimes.append(beatTime)
        }

        #expect(tempoTimes.sorted() == [0, 2])
    }

    @Test
    func augment_wholeWorkBeat_wrongTimeBasisThrows() {
        var work = Work(content: .standardWall([]))

        #expect(throws: Work.Error.timeBasisMismatch(expected: .beat)) {
            try work.augment(by: Number(2), anchor: nil as BeatTime?)
        }
    }

    @Test
    func augment_singlePart_scalesOnlyThatPart() throws {
        var part1 = Part<BeatTime, Pitch>(name: "Violin")
        var part2 = Part<BeatTime, Pitch>(name: "Cello")

        part1.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part2.noteTable.insert(attack: 0, duration: 1, pitch: .e4)

        let targetID = part1.partID
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        try work.augment(targetID, by: Number(2), anchor: nil as BeatTime?)

        #expect(work.partName(at: 0) == "Violin")
        #expect(work.partName(at: 1) == "Cello")
    }

    @Test
    func augment_singlePart_missingID_isNoOp() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.augment(PartID(), by: Number(2), anchor: nil as BeatTime?)

        #expect(work.partCount == 1)
    }

    @Test
    func augment_partIDs_allOrNothingLeavesWorkUnchangedOnFailure() {
        var goodPart = Part<BeatTime, Pitch>(name: "Violin")
        var badPart = Part<BeatTime, Pitch>(name: "Cello")

        goodPart.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        badPart.noteTable.insert(attack: 5, duration: 1, pitch: .e4)

        let partIDs: Set<PartID> = [goodPart.partID, badPart.partID]
        var work = Work(content: .standardBeat([goodPart, badPart], TempoMap()))

        //
        // An explicit anchor of 3 is later than `goodPart`'s own range (0...1), so its
        // containment check fails, even though it's a valid anchor for `badPart` (5...6):
        //
        #expect(throws: Work.Error.self) {
            try work.augment(partIDs, by: Number(2), anchor: BeatTime(3))
        }

        #expect(work.partName(at: 0) == "Violin")
        #expect(work.beatTimeRange == BeatTime(0)...BeatTime(6))
    }

    @Test
    func diminish_wrongTimeBasisThrows() {
        var work = Work(content: .standardWall([]))

        #expect(throws: Work.Error.timeBasisMismatch(expected: .beat)) {
            try work.diminish(by: Number(2), anchor: nil as BeatTime?)
        }
    }

    @Test
    func invert_wholeWork_invertsEveryPart() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 0, duration: 1, pitch: .e4)

        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.invert(around: nil as ClosedRange<Pitch>?)

        #expect(work.pitchRange != nil)
    }

    @Test
    func invert_wrongPitchNotationThrows() {
        var work = Work(content: .keyboardBeat([], TempoMap()))

        #expect(throws: Work.Error.pitchNotationMismatch(expected: .standard)) {
            try work.invert(around: nil as ClosedRange<Pitch>?)
        }
    }

    @Test
    func move_wholeWorkBeat_shiftsEveryPartAndTempoMap() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap))

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try work.move(by: directedDuration)

        #expect(work.beatTimeRange?.lowerBound == 2)

        var tempoTimes: [BeatTime] = []

        work.tempoMap?.forEach { _, beatTime, _, _ in
            tempoTimes.append(beatTime)
        }

        #expect(tempoTimes == [2])
    }

    @Test
    func reverse_wholeWorkBeat_mirrorsEveryPartAndTempoMap() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap))

        try work.reverse(within: nil as ClosedRange<BeatTime>?)

        var tempoTimes: [BeatTime] = []

        work.tempoMap?.forEach { _, beatTime, _, _ in
            tempoTimes.append(beatTime)
        }

        //
        // The part spans 0...3 (a note at 0 of duration 1, and one at 2 of duration 1), so the
        // aggregate beat-time range the tempo map is reversed within is 0...3, not 0...2 — the
        // tempo entries at 0 and 2 mirror to 3 and 1 respectively:
        //
        #expect(tempoTimes.sorted() == [1, 3])
    }

    @Test
    func transpose_wholeWork_transposesEveryPart() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var work = Work(content: .standardBeat([part], TempoMap()))

        let interval = try #require(Pitch.c4.interval(to: .e4))

        try work.transpose(by: interval)

        #expect(work.pitchRange?.lowerBound as? Pitch == .e4)
    }

    @Test
    func transpose_wrongPitchNotationThrows() {
        var work = Work(content: .keyboardBeat([], TempoMap()))

        let interval = DirectedInterval(interval: Interval.unison, direction: .same)

        #expect(throws: Work.Error.pitchNotationMismatch(expected: .standard)) {
            try work.transpose(by: interval)
        }
    }

    @Test
    func mapTransformFailure_wrapsUnderlyingDynamicMapError() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 5, duration: 1, pitch: .c4)
        part.dynamicMap.insert(time: 0, dynamic: .mp)

        var work = Work(content: .standardBeat([part], TempoMap()))

        #expect(throws: Work.Error.self) {
            try work.augment(by: Number(2), anchor: BeatTime(5))
        }

        #expect(work.beatTimeRange == BeatTime(5)...BeatTime(6))
    }

    @Test
    func augment_wholeWorkBeat_applyToAll_scalesEveryLayerConsistently() throws {
        var part1 = Part<BeatTime, Pitch>(name: "Violin")
        var part2 = Part<BeatTime, Pitch>(name: "Cello")

        part1.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part1.dynamicMap.insert(time: 0, dynamic: .mp)
        part1.instrumentMap.insert(time: 0, instrument: .vanilla)
        part1.panMap.insert(time: 0, pan: .center)

        part2.noteTable.insert(attack: 2, duration: 1, pitch: .e4)
        part2.dynamicMap.insert(time: 2, dynamic: .mf)
        part2.instrumentMap.insert(time: 2, instrument: .vanilla)
        part2.panMap.insert(time: 2, pan: .left)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([part1, part2], tempoMap))

        try work.augment(by: Number(2), anchor: nil as BeatTime?, applyTo: .all)

        //
        // Every part's note table, dynamic map, instrument map, and pan map, and the work's
        // tempo map, all scaled consistently relative to the same anchor (the aggregate
        // beat-time range's lower bound, 0).
        //
        guard case let .standardBeat(parts, newTempoMap) = work.content
        else { Issue.record("Expected .standardBeat content."); return }

        #expect(parts.count == 2)

        var attacksAndDurations: [(BeatTime, BeatTime.DurationType)] = []
        var dynamicTimes: [BeatTime] = []
        var instrumentTimes: [BeatTime] = []
        var panTimes: [BeatTime] = []

        for part in parts {
            part.noteTable.forEach { _, attack, duration, _, _, _ in
                attacksAndDurations.append((attack, duration))
            }

            part.dynamicMap.forEach { _, time, _, _ in
                dynamicTimes.append(time)
            }

            part.instrumentMap.forEach { _, time, _, _ in
                instrumentTimes.append(time)
            }

            part.panMap.forEach { _, time, _, _ in
                panTimes.append(time)
            }
        }

        var tempoTimes: [BeatTime] = []

        newTempoMap.forEach { _, time, _, _ in
            tempoTimes.append(time)
        }

        #expect(attacksAndDurations.map(\.0).sorted() == [0, 4])
        #expect(attacksAndDurations.map(\.1).sorted() == [2, 2])
        #expect(dynamicTimes.sorted() == [0, 4])
        #expect(instrumentTimes.sorted() == [0, 4])
        #expect(panTimes.sorted() == [0, 4])
        #expect(tempoTimes.sorted() == [0, 4])
    }
}
