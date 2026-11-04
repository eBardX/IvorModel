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
    func augment_entryIDsRestrictsAffectedEntries() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))

        let entryID1 = map.insert(time: 0, instrument: .vanilla).entryID

        map.insert(time: 4, instrument: guitar)

        try map.augment(by: Number(2), entryIDs: [entryID1])

        var times: [BeatTime] = []

        for entry in map {
            times.append(entry.time)
        }

        #expect(times.sorted() == [0, 4])
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
    func augment_invalidFactor() {
        var map = InstrumentMapSB()

        #expect(throws: InstrumentMapSB.Error.self) {
            try map.augment(by: Number(0))
        }
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

        for entry in map {
            if entry.entryID == entryID10 {
                time10 = entry.time
            }

            if entry.entryID == entryID14 {
                time14 = entry.time
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
    func augment_scalesTimes() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))
        let piano = try #require(Instrument(stringValue: "Piano"))

        map.insert(time: 1, instrument: guitar)
        map.insert(time: 3, instrument: piano)

        try map.augment(by: Number(2))

        var times: [BeatTime] = []

        for entry in map {
            times.append(entry.time)
        }

        #expect(times.sorted() == [1, 5])
    }

    @Test
    func augment_validAnchorDoesNotThrow() throws {
        var map = InstrumentMapSB()

        map.insert(time: 2, instrument: .vanilla)

        try map.augment(by: Number(2), anchor: 2)

        var times: [BeatTime] = []

        for entry in map {
            times.append(entry.time)
        }

        #expect(times == [2])
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

        for entry in map {
            times.append(entry.time)
        }

        #expect(times.sorted() == [2, 4])
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

        for entry in map {
            times.append(entry.time)
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

        for entry in map {
            times.append(entry.time)
        }

        #expect(times == [2])
    }

    @Test
    func quantize_entryIDsRestrictsAffectedEntries() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))

        let entryID1 = map.insert(time: 0.49, instrument: .vanilla).entryID
        let entryID2 = map.insert(time: 4.49, instrument: guitar).entryID

        let quantizer = try BeatQuantizer(factors: [1])

        map.quantize(using: quantizer, entryIDs: [entryID1])

        var timesByID: [EntryID: BeatTime] = [:]

        for entry in map {
            timesByID[entry.entryID] = entry.time
        }

        #expect(timesByID[entryID1] == 0)
        #expect(timesByID[entryID2] == BeatTime(4.49))
    }

    @Test
    func quantize_snapsTimesToGrid() throws {
        var map = InstrumentMapSB()

        map.insert(time: 0.49, instrument: .vanilla)

        let guitar = try #require(Instrument(stringValue: "Guitar"))

        map.insert(time: 3.6, instrument: guitar)

        let quantizer = try BeatQuantizer(factors: [1])

        map.quantize(using: quantizer)

        var times: [BeatTime] = []

        for entry in map {
            times.append(entry.time)
        }

        #expect(times.sorted() == [0, 4])
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

        for entry in map {
            if entry.entryID == phraseID1 || entry.entryID == phraseID2 {
                phraseTimes.append(entry.time)
            }
        }

        //
        // Mirrored around its own bounds (10...12), not the whole map's (0...20), so
        // the phrase lands back within its own span rather than somewhere else
        // entirely. Guitar holds for all of 10...12, so it starts there; piano's stretch
        // ends where the range does, so it has no length and mirrors to 10 as well, ahead of
        // guitar:
        //
        #expect(phraseTimes == [10, 10])
        #expect(map[BeatTime(10)] == guitar)

        var allTimes: [BeatTime] = []

        for entry in map {
            allTimes.append(entry.time)
        }

        //
        // The entries outside the selection are untouched:
        //
        #expect(allTimes == [0, 10, 10, 20])
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
    func reverse_leadingStretchKeepsPrecedingUnselectedInstrument() throws {
        //
        // Flute from 0, then piccolo from 4 and oboe from 6, with only the last two reversed
        // within 2…8. The stretch 2–4 is still flute, from the unselected entry, so flute (not
        // the default) begins the stretch it mirrors to, 6–8.
        //
        var map = InstrumentMapSB()
        let flute = try #require(Instrument(stringValue: "Flute"))
        let oboe = try #require(Instrument(stringValue: "Oboe"))
        let piccolo = try #require(Instrument(stringValue: "Piccolo"))

        map.insert(time: 0, instrument: flute)

        let piccoloID = map.insert(time: 4, instrument: piccolo).entryID
        let oboeID = map.insert(time: 6, instrument: oboe).entryID

        try map.reverse(within: BeatTime(2)...8,
                        entryIDs: [piccoloID, oboeID])

        #expect(map.map(\.time) == [0, 2, 4, 6])
        #expect(map.map(\.instrument) == [flute, oboe, piccolo, flute])
    }

    @Test
    func reverse_movesEachEntryToItsStretchStart() throws {
        //
        // Each entry's instrument holds until the next entry. Flute for 0–4, then piccolo for
        // 4–8, reversed within 0…8, is piccolo for 0–4, then flute for 4–8.
        //
        var map = InstrumentMapSB()
        let flute = try #require(Instrument(stringValue: "Flute"))
        let piccolo = try #require(Instrument(stringValue: "Piccolo"))

        map.insert(time: 0, instrument: flute)
        map.insert(time: 4, instrument: piccolo)

        try map.reverse(within: BeatTime(0)...8)

        #expect(map.map(\.time) == [0, 4])
        #expect(map.map(\.instrument) == [piccolo, flute])
    }

    @Test
    func reverse_movesLeadingStretchToRangeEnd() throws {
        //
        // Before the first entry, the default instrument is in effect. Vanilla for 0–2, flute
        // for 2–4, then piccolo for 4–8, reversed within 0…8, is piccolo for 0–4, flute for
        // 4–6, then vanilla for 6–8. A new entry begins the vanilla stretch.
        //
        var map = InstrumentMapSB()
        let flute = try #require(Instrument(stringValue: "Flute"))
        let piccolo = try #require(Instrument(stringValue: "Piccolo"))

        map.insert(time: 2, instrument: flute)
        map.insert(time: 4, instrument: piccolo)

        try map.reverse(within: BeatTime(0)...8)

        #expect(map.map(\.time) == [0, 4, 6])
        #expect(map.map(\.instrument) == [piccolo, flute, .vanilla])
    }

    @Test
    func reverse_swapsEntriesThatShareATime() throws {
        //
        // Flute then piccolo at 4 is an instant switch: piccolo holds from 4. Reversed within
        // 0…8, piccolo holds for 0–4, and the flute stretch that had no length lands at 4,
        // ahead of oboe, which takes over from it.
        //
        var map = InstrumentMapSB()
        let flute = try #require(Instrument(stringValue: "Flute"))
        let oboe = try #require(Instrument(stringValue: "Oboe"))
        let piccolo = try #require(Instrument(stringValue: "Piccolo"))

        map.insert(time: 0, instrument: oboe)
        map.insert(time: 4, instrument: flute)
        map.insert(time: 4, instrument: piccolo)

        try map.reverse(within: BeatTime(0)...8)

        #expect(map.map(\.time) == [0, 4, 4])
        #expect(map.map(\.instrument) == [piccolo, flute, oboe])
        #expect(map[BeatTime(4)] == oboe)
    }

    @Test
    func reverse_validAnchorDoesNotThrow() throws {
        var map = InstrumentMapSB()
        let guitar = try #require(Instrument(stringValue: "Guitar"))

        map.insert(time: 0, instrument: .vanilla)
        map.insert(time: 2, instrument: guitar)

        try map.reverse(within: BeatTime(0)...2)

        //
        // Vanilla holds for all of 0…2, so it starts at 0. Guitar's stretch ends where the
        // range does, so it has no length and mirrors to 0 as well, ahead of vanilla:
        //
        #expect(map.map(\.time) == [0, 0])
        #expect(map[BeatTime(0)] == .vanilla)
    }
}
