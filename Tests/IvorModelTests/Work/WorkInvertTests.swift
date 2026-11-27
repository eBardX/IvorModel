// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkInvertTests {
}

// MARK: -

extension WorkInvertTests {
    @Test
    func invert_absolute_removesKeys() throws {
        var part = Part<BeatTime, Frequency>(name: "Sine")

        part.strands[0].noteTable.insert(attack: 0, duration: 1, pitch: 440)
        part.strands[0].noteTable.insert(attack: 1, duration: 1, pitch: 660)

        let content = try Work.Content.absoluteBeat([part], TempoMap(), MeterTable(), makeKeyTable([(0, 2)]))
        var removed = Work(content: content)
        var kept = Work(content: content)

        let range: ClosedRange<Frequency> = 440...660

        try removed.invert(around: range)
        try kept.invert(around: range, movesKeys: false)

        #expect(removed.keyTable?.isEmpty == true)
        #expect(kept.keyTable?.map(\.key) == [key(2)])
    }

    @Test
    func invert_keyboard_invertsKeys() throws {
        var part = Part<BeatTime, NoteNumber>(name: "Piano")

        part.strands[0].noteTable.insert(attack: 0, duration: 1, pitch: 60)
        part.strands[0].noteTable.insert(attack: 1, duration: 1, pitch: 67)

        var work = try Work(content: .keyboardBeat([part], TempoMap(), MeterTable(), makeKeyTable([(0, 1)])))
        let range: ClosedRange<NoteNumber> = 60...67

        try work.invert(around: range)

        #expect(work.keyTable?.map(\.key) == [key(-4)])
    }

    @Test
    func invert_lockedWork_throwsAndLeavesWorkUnchanged() {
        var (work, partID) = makeLockedWorkSB()
        let beatTimeRange = work.beatTimeRange

        #expect(throws: Work.Error.workIsLocked) {
            try work.invert(around: nil as ClosedRange<Pitch>?, partIDs: [partID])
        }

        #expect(throws: Work.Error.workIsLocked) {
            try work.invert(around: nil as ClosedRange<Pitch>?)
        }

        #expect(work.beatTimeRange == beatTimeRange)
        #expect(work.pitchRange?.lowerBound as? Pitch == .c4)
    }

    @Test
    func invert_standard_flagOffKeepsKeys() throws {
        var work = try makeKeyWork(makeKeyTable([(0, 1)]))

        try work.invert(around: Pitch.c4...Pitch.g4, movesKeys: false)

        #expect(work.keyTable?.map(\.key) == [key(1)])
    }

    @Test
    func invert_standard_invertsKeysAndMapsMode() throws {
        var table = KeyTable()

        try table.insert(beatTime: 0, key: key(1, .major), extras: sampleExtras("kept"))

        var work = makeKeyWork(table, pitches: [.c4, .g4])

        try work.invert(around: Pitch.c4...Pitch.g4)

        #expect(work.keyTable?.first?.key == key(-4, .phrygian))
        #expect(work.keyTable?.first?.extras == sampleExtras("kept"))
    }

    @Test
    func invert_standard_somePartsWithFlag() throws {
        var bass = Part<BeatTime, Pitch>(name: "Bass")
        var treble = Part<BeatTime, Pitch>(name: "Treble")

        bass.strands[0].noteTable.insert(attack: 0, duration: 1, pitch: .c3)
        treble.strands[0].noteTable.insert(attack: 0, duration: 1, pitch: .g4)

        let content = try Work.Content.standardBeat([bass, treble], TempoMap(), MeterTable(), makeKeyTable([(0, 0)]))
        var moved = Work(content: content)
        var kept = Work(content: content)

        try moved.invert(around: Pitch.c4...Pitch.g4, partIDs: [treble.partID])
        try kept.invert(around: Pitch.c4...Pitch.g4, movesKeys: false, partIDs: [treble.partID])

        #expect(moved.keyTable?.map(\.key) == [key(-3)])
        #expect(kept.keyTable?.map(\.key) == [key(0)])
    }

    @Test
    func invert_wholeWork_invertsEveryPart() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.strands[0].noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.strands[0].noteTable.insert(attack: 0, duration: 1, pitch: .e4)

        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        try work.invert(around: nil as ClosedRange<Pitch>?)

        #expect(work.pitchRange != nil)
    }

    @Test
    func invert_wrongPitchNotationThrows() {
        var work = Work(content: .keyboardBeat([], TempoMap(), MeterTable(), KeyTable()))

        #expect(throws: Work.Error.pitchNotationMismatch(expected: .standard)) {
            try work.invert(around: nil as ClosedRange<Pitch>?)
        }
    }
}
