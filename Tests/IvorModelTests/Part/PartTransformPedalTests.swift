// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct PartTransformPedalTests {
}

// MARK: -

extension PartTransformPedalTests {
    private typealias PartSB = Part<BeatTime, Pitch>

    @Test
    func augment_applyToExcludesPedals() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0, level: .on)
        sustain.insert(time: 2, level: .off)

        part.pedals[.sustain] = sustain

        try part.augment(by: Number(2), applyTo: TransformTargets.all.subtracting(.pedal))

        #expect(part.pedals[.sustain]?.map(\.time) == [0, 2])
    }

    @Test
    func augment_carriesEveryPedalTable() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0, level: .on)
        sustain.insert(time: 2, level: .off)

        part.pedals[.sustain] = sustain

        var soft = PedalTable<BeatTime>()

        soft.insert(time: 1, level: .on)

        part.pedals[.soft] = soft

        try part.augment(by: Number(2))

        #expect(part.pedals[.sustain]?.map(\.time) == [0, 4])
        #expect(part.pedals[.soft]?.map(\.time) == [2])
    }

    @Test
    func augment_pedalRangeWidensDefaultAnchor() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 2, duration: 1, pitch: .c4)

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0, level: .on)
        sustain.insert(time: 2, level: .off)

        part.pedals[.sustain] = sustain

        try part.augment(by: Number(2))

        //
        // The pedal entry at 0 is part of what's augmented, so the default anchor is 0, not the
        // note's attack at 2:
        //
        #expect(part.noteTable.timeRange?.lowerBound == 4)
        #expect(part.pedals[.sustain]?.map(\.time) == [0, 4])
    }

    @Test
    func diminish_carriesPedals() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 4, pitch: .c4)

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0, level: .on)
        sustain.insert(time: 2, level: .off)

        part.pedals[.sustain] = sustain

        try part.diminish(by: Number(2))

        #expect(part.pedals[.sustain]?.map(\.time) == [0, 1])
    }

    @Test
    func move_applyToExcludesPedals() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0, level: .on)
        sustain.insert(time: 2, level: .off)

        part.pedals[.sustain] = sustain

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try part.move(by: directedDuration, applyTo: TransformTargets.all.subtracting(.pedal))

        #expect(part.pedals[.sustain]?.map(\.time) == [0, 2])
    }

    @Test
    func move_carriesPedals() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0, level: .on)
        sustain.insert(time: 2, level: .off)

        part.pedals[.sustain] = sustain

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try part.move(by: directedDuration)

        #expect(part.pedals[.sustain]?.map(\.time) == [2, 4])
    }

    @Test
    func move_noteIDsCarriesPressEnd() throws {
        var part = PartSB(name: "Test")

        let noteID = part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        part.noteTable.insert(attack: 10, duration: 1, pitch: .d4)

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0, level: .on)
        sustain.insert(time: 2, level: .off)

        part.pedals[.sustain] = sustain

        let directedDuration = try #require(BeatTime(0).duration(to: 4))

        try part.move(by: directedDuration, noteIDs: [noteID])

        //
        // The selected note spans 0...1. The pedal goes down at 0, inside it, and is still down
        // at 1, so the release at 2 moves with the selection:
        //
        #expect(part.pedals[.sustain]?.map(\.time) == [4, 6])
    }

    @Test
    func move_noteIDsLeavesNextPressWhenPedalIsUp() throws {
        var part = PartSB(name: "Test")

        let noteID = part.noteTable.insert(attack: 0, duration: 2, pitch: .c4)

        part.noteTable.insert(attack: 10, duration: 1, pitch: .d4)

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0, level: .on)
        sustain.insert(time: 1, level: .off)
        sustain.insert(time: 5, level: .on)

        part.pedals[.sustain] = sustain

        let directedDuration = try #require(BeatTime(0).duration(to: 4))

        try part.move(by: directedDuration, noteIDs: [noteID])

        //
        // The selected note spans 0...2, and the pedal is already up by 2, so the next press at
        // 5 stays where it is:
        //
        #expect(part.pedals[.sustain]?.map(\.time) == [4, 5, 5])
        #expect(part.pedals[.sustain]?.map(\.level) == [.on, .off, .on])
    }

    @Test
    func quantize_toQuantizerCarriesPedals() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0.9, level: .on)
        sustain.insert(time: 2.2, level: .off)

        part.pedals[.sustain] = sustain

        try part.quantize(to: BeatQuantizer(factors: [1]))

        #expect(part.pedals[.sustain]?.map(\.time) == [1, 2])

        var excluded = PartSB(name: "Test")

        excluded.pedals[.sustain] = sustain
        try excluded.quantize(to: BeatQuantizer(factors: [1]),
                              applyTo: TransformTargets.all.subtracting(.pedal))

        #expect(excluded.pedals[.sustain]?.map(\.time) == [0.9, 2.2])
    }

    @Test
    func reverse_carriesPedals() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 8, pitch: .c4)

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0, level: .on)
        sustain.insert(time: 3, level: .off)
        sustain.insert(time: 3, level: .on)
        sustain.insert(time: 8, level: .off)

        part.pedals[.sustain] = sustain

        try part.reverse(within: BeatTime(0)...8)

        #expect(part.pedals[.sustain]?.map(\.time) == [0, 0, 5, 5])
        #expect(part.pedals[.sustain]?.map(\.level) == [.off, .on, .off, .on])
    }

    @Test
    func transpose_neverTouchesPedals() throws {
        var part = PartSB(name: "Test")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 0, level: .on)
        sustain.insert(time: 2, level: .off)

        part.pedals[.sustain] = sustain

        let interval = try #require(Pitch.c4.interval(to: .e4))

        try part.transpose(by: interval)
        try part.invert()

        #expect(part.pedals[.sustain]?.map(\.time) == [0, 2])
    }
}
