// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct InstrumentMapTransformTests {
}

// MARK: -

extension InstrumentMapTransformTests {
    private typealias InstrumentMapSB = InstrumentMap<BeatTime>

    @Test
    func augment_invalidFactor() {
        var map = InstrumentMapSB()

        #expect(throws: InstrumentMapSB.Error.self) {
            try map.augment(by: Number(0))
        }
    }

    @Test
    func augment_scalesTimes() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))
        let piano = try #require(Instrument(stringValue: "Piano"))

        map.insert(time: 1, instrument: guitar)
        map.insert(time: 3, instrument: piano)

        try map.augment(by: Number(2))

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [1, 5])
    }

    @Test
    func diminish_invalidFactor() {
        var map = InstrumentMapSB()

        #expect(throws: InstrumentMapSB.Error.self) {
            try map.diminish(by: Number(0))
        }
    }

    @Test
    func diminish_scalesTimes() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))
        let piano = try #require(Instrument(stringValue: "Piano"))

        map.insert(time: 2, instrument: guitar)
        map.insert(time: 6, instrument: piano)

        try map.diminish(by: Number(2))

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [2, 4])
    }

    @Test
    func move_shiftsTimes() throws {
        var map = InstrumentMapSB()

        map.insert(time: 0, instrument: .vanilla)

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try map.move(by: directedDuration)

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times == [2])
    }

    @Test
    func reverse_mirrorsTimes() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))

        map.insert(time: 0, instrument: .vanilla)
        map.insert(time: 2, instrument: guitar)

        try map.reverse()

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [0, 2])
    }

    @Test
    func augment_invalidAnchorThrows() {
        var map = InstrumentMapSB()

        map.insert(time: 2, instrument: .vanilla)

        #expect(throws: InstrumentMapSB.Error.invalidAnchor) {
            try map.augment(by: Number(2), anchor: 3)
        }
    }

    @Test
    func augment_validAnchorDoesNotThrow() throws {
        var map = InstrumentMapSB()

        map.insert(time: 2, instrument: .vanilla)

        try map.augment(by: Number(2), anchor: 2)

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times == [2])
    }

    @Test
    func augment_entryIDsRestrictsAffectedEntries() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))

        let entryID1 = map.insert(time: 0, instrument: .vanilla).entryID

        map.insert(time: 4, instrument: guitar)

        try map.augment(by: Number(2), entryIDs: [entryID1])

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [0, 4])
    }

    @Test
    func augment_nilAnchorWithEntryIDsUsesSelectedRange() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))
        let piano = try #require(Instrument(stringValue: "Piano"))

        map.insert(time: 0, instrument: .vanilla)

        let entryID10 = map.insert(time: 10, instrument: guitar).entryID
        let entryID14 = map.insert(time: 14, instrument: piano).entryID

        try map.augment(by: Number(2), entryIDs: [entryID10, entryID14])

        var time10: BeatTime?
        var time14: BeatTime?

        map.forEach { entryID, time, _, _ in
            if entryID == entryID10 {
                time10 = time
            }

            if entryID == entryID14 {
                time14 = time
            }
        }

        //
        // Anchored to the selected entries' own low bound (10), not the whole map's
        // (0), so the selected entry at 10 stays put while the one at 14 stretches
        // relative to it:
        //
        #expect(time10 == 10)
        #expect(time14 == 18)
    }

    @Test
    func reverse_invalidAnchorThrows() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))

        map.insert(time: 0, instrument: .vanilla)
        map.insert(time: 2, instrument: guitar)

        #expect(throws: InstrumentMapSB.Error.invalidAnchor) {
            try map.reverse(within: BeatTime(1)...3)
        }
    }

    @Test
    func reverse_validAnchorDoesNotThrow() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))

        map.insert(time: 0, instrument: .vanilla)
        map.insert(time: 2, instrument: guitar)

        try map.reverse(within: BeatTime(0)...2)

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [0, 2])
    }

    @Test
    func reverse_entryIDsSelectionIsSelfContained() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))
        let piano = try #require(Instrument(stringValue: "Piano"))

        map.insert(time: 0, instrument: .vanilla)

        let phraseID1 = map.insert(time: 10, instrument: guitar).entryID
        let phraseID2 = map.insert(time: 12, instrument: piano).entryID

        map.insert(time: 20, instrument: .vanilla)

        try map.reverse(entryIDs: [phraseID1, phraseID2])

        var phraseTimes: [BeatTime] = []

        map.forEach { entryID, time, _, _ in
            if entryID == phraseID1 || entryID == phraseID2 {
                phraseTimes.append(time)
            }
        }

        //
        // Mirrored around its own bounds (10...12), not the whole map's (0...20), so
        // the phrase lands back within its own span rather than somewhere else
        // entirely:
        //
        #expect(phraseTimes.sorted() == [10, 12])

        var allTimes: [BeatTime] = []

        map.forEach { _, time, _, _ in
            allTimes.append(time)
        }

        //
        // The entries outside the selection are untouched:
        //
        #expect(allTimes.sorted() == [0, 10, 12, 20])
    }

    @Test
    func move_entryIDsRestrictsAffectedEntries() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))

        let entryID1 = map.insert(time: 0, instrument: .vanilla).entryID

        map.insert(time: 4, instrument: guitar)

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try map.move(by: directedDuration, entryIDs: [entryID1])

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [2, 4])
    }
}
