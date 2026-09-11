// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct DynamicMapTransformTests {
}

// MARK: -

extension DynamicMapTransformTests {
    private typealias DynamicMapSB = DynamicMap<BeatTime>

    @Test
    func augment_invalidFactor() {
        var map = DynamicMapSB()

        #expect(throws: DynamicMapSB.Error.self) {
            try map.augment(by: Number(0))
        }
    }

    @Test
    func augment_scalesTimes() throws {
        var map = DynamicMapSB()

        map.insert(time: 1, dynamic: .mp)
        map.insert(time: 3, dynamic: .ff)

        try map.augment(by: Number(2))

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [1, 5])
    }

    @Test
    func diminish_invalidFactor() {
        var map = DynamicMapSB()

        #expect(throws: DynamicMapSB.Error.self) {
            try map.diminish(by: Number(0))
        }
    }

    @Test
    func diminish_scalesTimes() throws {
        var map = DynamicMapSB()

        map.insert(time: 2, dynamic: .mp)
        map.insert(time: 6, dynamic: .ff)

        try map.diminish(by: Number(2))

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [2, 4])
    }

    @Test
    func move_shiftsTimes() throws {
        var map = DynamicMapSB()

        map.insert(time: 0, dynamic: .mp)

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
        var map = DynamicMapSB()

        map.insert(time: 0, dynamic: .mp)
        map.insert(time: 2, dynamic: .ff)

        try map.reverse()

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [0, 2])
    }

    @Test
    func augment_invalidAnchorThrows() {
        var map = DynamicMapSB()

        map.insert(time: 2, dynamic: .mp)

        #expect(throws: DynamicMapSB.Error.invalidAnchor) {
            try map.augment(by: Number(2), anchor: 3)
        }
    }

    @Test
    func augment_validAnchorDoesNotThrow() throws {
        var map = DynamicMapSB()

        map.insert(time: 2, dynamic: .mp)

        try map.augment(by: Number(2), anchor: 2)

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times == [2])
    }

    @Test
    func augment_entryIDsRestrictsAffectedEntries() throws {
        var map = DynamicMapSB()

        let entryID1 = map.insert(time: 0, dynamic: .mp).entryID

        map.insert(time: 4, dynamic: .mf)

        try map.augment(by: Number(2), entryIDs: [entryID1])

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [0, 4])
    }

    @Test
    func augment_nilAnchorWithEntryIDsUsesSelectedRange() throws {
        var map = DynamicMapSB()

        map.insert(time: 0, dynamic: .mp)

        let entryID10 = map.insert(time: 10, dynamic: .mf).entryID
        let entryID14 = map.insert(time: 14, dynamic: .ff).entryID

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
        var map = DynamicMapSB()

        map.insert(time: 0, dynamic: .mp)
        map.insert(time: 2, dynamic: .ff)

        #expect(throws: DynamicMapSB.Error.invalidAnchor) {
            try map.reverse(within: BeatTime(1)...3)
        }
    }

    @Test
    func reverse_validAnchorDoesNotThrow() throws {
        var map = DynamicMapSB()

        map.insert(time: 0, dynamic: .mp)
        map.insert(time: 2, dynamic: .ff)

        try map.reverse(within: BeatTime(0)...2)

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [0, 2])
    }

    @Test
    func reverse_entryIDsSelectionIsSelfContained() throws {
        var map = DynamicMapSB()

        map.insert(time: 0, dynamic: .mp)

        let phraseID1 = map.insert(time: 10, dynamic: .mf).entryID
        let phraseID2 = map.insert(time: 12, dynamic: .ff).entryID

        map.insert(time: 20, dynamic: .p)

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
        var map = DynamicMapSB()

        let entryID1 = map.insert(time: 0, dynamic: .mp).entryID

        map.insert(time: 4, dynamic: .mf)

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try map.move(by: directedDuration, entryIDs: [entryID1])

        var times: [BeatTime] = []

        map.forEach { _, time, _, _ in
            times.append(time)
        }

        #expect(times.sorted() == [2, 4])
    }
}
