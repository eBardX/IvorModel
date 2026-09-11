// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PanMapTransformTests {
}

// MARK: -

extension PanMapTransformTests {
    private typealias PanMapSB = PanMap<BeatTime>

    @Test
    func augment_invalidFactor() {
        var map = PanMapSB()

        #expect(throws: PanMapSB.Error.self) {
            try map.augment(by: Number(0))
        }
    }

    @Test
    func augment_scalesTimes() throws {
        var map = PanMapSB()

        map.insert(time: 1, pan: .left)
        map.insert(time: 3, pan: .right)

        try map.augment(by: Number(2))

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [1, 5])
    }

    @Test
    func diminish_invalidFactor() {
        var map = PanMapSB()

        #expect(throws: PanMapSB.Error.self) {
            try map.diminish(by: Number(0))
        }
    }

    @Test
    func diminish_scalesTimes() throws {
        var map = PanMapSB()

        map.insert(time: 2, pan: .left)
        map.insert(time: 6, pan: .right)

        try map.diminish(by: Number(2))

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [2, 4])
    }

    @Test
    func move_shiftsTimes() throws {
        var map = PanMapSB()

        map.insert(time: 0, pan: .center)

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
        var map = PanMapSB()

        map.insert(time: 0, pan: .left)
        map.insert(time: 2, pan: .right)

        try map.reverse()

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [0, 2])
    }

    @Test
    func augment_invalidAnchorThrows() {
        var map = PanMapSB()

        map.insert(time: 2, pan: .center)

        #expect(throws: PanMapSB.Error.invalidAnchor) {
            try map.augment(by: Number(2), anchor: 3)
        }
    }

    @Test
    func augment_validAnchorDoesNotThrow() throws {
        var map = PanMapSB()

        map.insert(time: 2, pan: .center)

        try map.augment(by: Number(2), anchor: 2)

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times == [2])
    }

    @Test
    func augment_entryIDsRestrictsAffectedEntries() throws {
        var map = PanMapSB()

        let entryID1 = map.insert(time: 0, pan: .center).entryID

        map.insert(time: 4, pan: .left)

        try map.augment(by: Number(2), entryIDs: [entryID1])

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [0, 4])
    }

    @Test
    func augment_nilAnchorWithEntryIDsUsesSelectedRange() throws {
        var map = PanMapSB()

        map.insert(time: 0, pan: .center)

        let entryID10 = map.insert(time: 10, pan: .left).entryID
        let entryID14 = map.insert(time: 14, pan: .right).entryID

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
    func reverse_invalidAnchorThrows() {
        var map = PanMapSB()

        map.insert(time: 0, pan: .left)
        map.insert(time: 2, pan: .right)

        #expect(throws: PanMapSB.Error.invalidAnchor) {
            try map.reverse(within: BeatTime(1)...3)
        }
    }

    @Test
    func reverse_validAnchorDoesNotThrow() throws {
        var map = PanMapSB()

        map.insert(time: 0, pan: .left)
        map.insert(time: 2, pan: .right)

        try map.reverse(within: BeatTime(0)...2)

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [0, 2])
    }

    @Test
    func reverse_entryIDsSelectionIsSelfContained() throws {
        var map = PanMapSB()

        map.insert(time: 0, pan: .center)

        let phraseID1 = map.insert(time: 10, pan: .left).entryID
        let phraseID2 = map.insert(time: 12, pan: .right).entryID

        map.insert(time: 20, pan: .center)

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
        var map = PanMapSB()

        let entryID1 = map.insert(time: 0, pan: .center).entryID

        map.insert(time: 4, pan: .left)

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try map.move(by: directedDuration, entryIDs: [entryID1])

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [2, 4])
    }
}
