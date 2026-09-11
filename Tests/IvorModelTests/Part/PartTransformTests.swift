// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct PartTransformTests {
}

// MARK: -

extension PartTransformTests {
    private typealias PartSB = Part<BeatTime, Pitch>

    @Test
    func augment_scalesNoteTableAndAllMapsByDefault() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .d4)
        part.dynamicMap.insert(time: 0, dynamic: .mp)
        part.dynamicMap.insert(time: 2, dynamic: .ff)
        part.instrumentMap.insert(time: 0, instrument: .vanilla)
        part.panMap.insert(time: 0, pan: .center)
        part.panMap.insert(time: 2, pan: .right)

        try part.augment(by: Number(2))

        #expect(part.noteTable.timeRange?.upperBound == 6)

        var dynamicTimes: [BeatTime] = []

        part.dynamicMap.forEach { _, time, _, _ in
            dynamicTimes.append(time)
        }

        #expect(dynamicTimes.sorted() == [0, 4])

        var panTimes: [BeatTime] = []

        part.panMap.forEach { _, time, _, _ in
            panTimes.append(time)
        }

        #expect(panTimes.sorted() == [0, 4])
    }

    @Test
    func augment_applyToExcludesAMap() throws {
        var part = PartSB(name: "Test")

        part.dynamicMap.insert(time: 0, dynamic: .mp)
        part.dynamicMap.insert(time: 2, dynamic: .ff)
        part.instrumentMap.insert(time: 0, instrument: .vanilla)

        let violin = try #require(Instrument(stringValue: "Violin"))

        part.instrumentMap.insert(time: 2, instrument: violin)

        try part.augment(by: Number(2), applyTo: MapTargets.all.subtracting(.dynamic))

        //
        // Excluded from `applyTo`, so untouched:
        //
        var dynamicTimes: [BeatTime] = []

        part.dynamicMap.forEach { _, time, _, _ in
            dynamicTimes.append(time)
        }

        #expect(dynamicTimes.sorted() == [0, 2])

        //
        // Included, so scaled:
        //
        var instrumentTimes: [BeatTime] = []

        part.instrumentMap.forEach { _, time, _, _ in
            instrumentTimes.append(time)
        }

        #expect(instrumentTimes.sorted() == [0, 4])
    }

    @Test
    func augment_noteIDsRestrictsCarriedMapEntries() throws {
        var part = PartSB(name: "Test")

        let noteID1 = part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        part.noteTable.insert(attack: 10, duration: 1, pitch: .d4)

        let entryIDEarly = part.dynamicMap.insert(time: 0, dynamic: .mp).entryID
        let entryIDLate = part.dynamicMap.insert(time: 10, dynamic: .ff).entryID

        try part.augment(by: Number(2), noteIDs: [noteID1])

        var earlyTime: BeatTime?
        var lateTime: BeatTime?

        part.dynamicMap.forEach { entryID, time, _, _ in
            if entryID == entryIDEarly {
                earlyTime = time
            }

            if entryID == entryIDLate {
                lateTime = time
            }
        }

        //
        // Only the entry within note 1's own range (0...1) is carried along; the one
        // outside it is untouched, even though `applyTo` still selects the map:
        //
        #expect(earlyTime == 0)
        #expect(lateTime == 10)
    }

    @Test
    func augment_scatteredNoteIDsCoarselyDerivesEntryIDs() throws {
        var part = PartSB(name: "Test")

        //
        // A scattered, non-contiguous selection — notes at 0 and 20, skipping one at
        // 10 in between:
        //
        let noteID1 = part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        part.noteTable.insert(attack: 10, duration: 1, pitch: .d4)

        let noteID3 = part.noteTable.insert(attack: 20, duration: 1, pitch: .e4)

        let entryIDLow = part.dynamicMap.insert(time: 0, dynamic: .mp).entryID
        let entryIDMiddle = part.dynamicMap.insert(time: 10, dynamic: .mf).entryID

        try part.augment(by: Number(2), noteIDs: [noteID1, noteID3])

        var lowTime: BeatTime?
        var middleTime: BeatTime?

        part.dynamicMap.forEach { entryID, time, _, _ in
            if entryID == entryIDLow {
                lowTime = time
            }

            if entryID == entryIDMiddle {
                middleTime = time
            }
        }

        //
        // The known coarseness (§7b): the derived range is the selection's own
        // bounding box (0...21), so the untouched note's own map entry at 10 — inside
        // that box even though the note itself wasn't selected — is carried along
        // and scaled together with the selected boundary entry at 0, rather than
        // being excluded just because its own note wasn't part of the selection:
        //
        #expect(lowTime == 0)
        #expect(middleTime == 20)
    }

    @Test
    func augment_explicitEntryIDsBypassesPartDerivation() throws {
        var part = PartSB(name: "Test")

        let entryID1 = part.dynamicMap.insert(time: 0, dynamic: .mp).entryID

        part.dynamicMap.insert(time: 4, dynamic: .ff)

        //
        // Calling the map's own Phase 2 method directly, with an explicit `entryIDs`,
        // rather than going through `Part`'s `noteIDs`-driven derivation:
        //
        try part.dynamicMap.augment(by: Number(2), entryIDs: [entryID1])

        var times: [BeatTime] = []

        part.dynamicMap.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [0, 4])
    }

    @Test
    func augment_noteTableFailureWraps() {
        var part = PartSB(name: "Test")

        #expect(throws: PartSB.Error.noteTableFailure(.invalidAugmentationFactor(Number(0)))) {
            try part.augment(by: Number(0))
        }
    }

    @Test
    func augment_mapFailureWrapsAndLeavesPartUnchanged() {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 5, duration: 1, pitch: .c4)
        part.dynamicMap.insert(time: 0, dynamic: .mp)

        //
        // Valid anchor for the note table's own range (5...6), but later than the
        // dynamic map's own range (0...0), so the map's own containment check fails:
        //
        #expect(throws: PartSB.Error.dynamicMapFailure(.invalidAnchor)) {
            try part.augment(by: Number(2), anchor: 5)
        }

        //
        // All-or-nothing: the note table is left exactly as it was, even though its
        // own augment would have succeeded on its own:
        //
        #expect(part.noteTable.timeRange == BeatTime(5)...BeatTime(6))
    }

    @Test
    func diminish_scalesNoteTableAndDefaultMaps() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 2, pitch: .c4)
        part.noteTable.insert(attack: 4, duration: 2, pitch: .d4)
        part.dynamicMap.insert(time: 0, dynamic: .mp)
        part.dynamicMap.insert(time: 4, dynamic: .ff)

        try part.diminish(by: Number(2))

        var dynamicTimes: [BeatTime] = []

        part.dynamicMap.forEach { _, time, _, _ in
            dynamicTimes.append(time)
        }

        #expect(dynamicTimes.sorted() == [0, 2])
    }

    @Test
    func invert_neverTouchesMaps() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.dynamicMap.insert(time: 0, dynamic: .mp)

        try part.invert()

        var dynamicTimes: [BeatTime] = []

        part.dynamicMap.forEach { _, time, _, _ in
            dynamicTimes.append(time)
        }

        #expect(dynamicTimes == [0])
    }

    @Test
    func move_shiftsNoteTableAndDefaultMaps() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.dynamicMap.insert(time: 0, dynamic: .mp)

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try part.move(by: directedDuration)

        #expect(part.noteTable.timeRange?.lowerBound == 2)

        var dynamicTimes: [BeatTime] = []

        part.dynamicMap.forEach { _, time, _, _ in
            dynamicTimes.append(time)
        }

        #expect(dynamicTimes == [2])
    }

    @Test
    func move_noteIDsRestrictsCarriedMapEntries() throws {
        var part = PartSB(name: "Test")

        let noteID1 = part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        part.noteTable.insert(attack: 10, duration: 1, pitch: .d4)

        let entryIDEarly = part.dynamicMap.insert(time: 0, dynamic: .mp).entryID
        let entryIDLate = part.dynamicMap.insert(time: 10, dynamic: .ff).entryID

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try part.move(by: directedDuration, noteIDs: [noteID1])

        var earlyTime: BeatTime?
        var lateTime: BeatTime?

        part.dynamicMap.forEach { entryID, time, _, _ in
            if entryID == entryIDEarly {
                earlyTime = time
            }

            if entryID == entryIDLate {
                lateTime = time
            }
        }

        #expect(earlyTime == 2)
        #expect(lateTime == 10)
    }

    @Test
    func reverse_mirrorsNoteTableAndDefaultMaps() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .d4)
        part.dynamicMap.insert(time: 0, dynamic: .mp)
        part.dynamicMap.insert(time: 2, dynamic: .ff)

        try part.reverse()

        var dynamicTimes: [BeatTime] = []

        part.dynamicMap.forEach { _, time, _, _ in
            dynamicTimes.append(time)
        }

        #expect(dynamicTimes.sorted() == [0, 2])
    }

    @Test
    func transpose_neverTouchesMaps() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.instrumentMap.insert(time: 0, instrument: .vanilla)

        let interval = try #require(Pitch.c4.interval(to: .e4))

        try part.transpose(by: interval)

        var instrumentTimes: [BeatTime] = []

        part.instrumentMap.forEach { _, time, _, _ in
            instrumentTimes.append(time)
        }

        #expect(instrumentTimes == [0])
        #expect(part.noteTable.pitchRange?.lowerBound == .e4)
    }

    @Test
    func quantize_toFactorsSnapsNoteTable() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: BeatTime(0.49), duration: 1, pitch: .c4)

        try part.quantize(to: [1])

        #expect(part.noteTable.timeRange?.lowerBound == 0)
    }

    @Test
    func quantize_toFactorsNoteTableFailureWraps() {
        var part = PartSB(name: "Test")

        #expect(throws: PartSB.Error.noteTableFailure(.emptyQuantizationFactors)) {
            try part.quantize(to: [])
        }
        #expect(throws: PartSB.Error.noteTableFailure(.invalidQuantizationFactor(0))) {
            try part.quantize(to: [0])
        }
    }

    @Test
    func quantize_toFactorsNoteIDsRestrictsAffectedNotes() throws {
        var part = PartSB(name: "Test")

        let noteID1 = part.noteTable.insert(attack: BeatTime(0.49), duration: 1, pitch: .c4)
        let noteID2 = part.noteTable.insert(attack: BeatTime(4.49), duration: 1, pitch: .d4)

        try part.quantize(to: [1], noteIDs: [noteID1])

        var attacksByID: [PartSB.NoteID: BeatTime] = [:]

        part.noteTable.forEach { noteID, attack, _, _, _, _ in
            attacksByID[noteID] = attack
        }

        #expect(attacksByID[noteID1] == 0)
        #expect(attacksByID[noteID2] == BeatTime(4.49))
    }

    @Test
    func quantize_toQuantizerNeverThrows() throws {
        var part = PartSB(name: "Test")
        let quantizer = try BeatQuantizer(factors: [1])

        part.noteTable.insert(attack: BeatTime(0.49), duration: 1, pitch: .c4)

        part.quantize(to: quantizer)

        #expect(part.noteTable.timeRange?.lowerBound == 0)
    }
}
