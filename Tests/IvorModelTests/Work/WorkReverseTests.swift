// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkReverseTests {
}

// MARK: -

extension WorkReverseTests {
    @Test
    func reverse_dropsRampExtrasWhenRampRunsPastRange() throws {
        //
        // A 60→120 ramp from 0 lasting 4 beats, with tempo entries only at 0 and 2, reversed
        // within 0–2: the ramp's start entry moves to 2, but its end, at 4, is outside the range.
        // No ramp extras can describe that, so they're dropped, and the exporter rebuilds the
        // ramp from the map.
        //
        let t60 = Tempo(60)
        let t90 = Tempo(90)
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0,
                        tempo: t60,
                        extras: Extras(elements: [Extra(name: Extra.rampStartTempo.name, values: [.double(60)]),
                                                  Extra(name: Extra.rampEndTempo.name, values: [.double(120)]),
                                                  Extra(name: Extra.rampDuration.name, values: [.double(4)])]))
        tempoMap.insert(beatTime: 2, tempo: t90)

        var work = Work(content: .standardBeat([Part<BeatTime, Pitch>(name: "Violin")], tempoMap, MeterTable()))

        try work.reverse(within: BeatTime(0)...BeatTime(2))

        let entries = Array(work.tempoMap ?? TempoMap())

        #expect(entries.map(\.beatTime) == [0, 2])
        #expect(entries.allSatisfy { extraValues(.rampStartTempo, in: $0.extras) == nil })
        #expect(entries.allSatisfy { extraValues(.rampEndTempo, in: $0.extras) == nil })
        #expect(entries.allSatisfy { extraValues(.rampDuration, in: $0.extras) == nil })
    }

    @Test
    func reverse_keepsWorkExtrasInBeatWork() throws {
        //
        // `midiTimeCode` describes the whole file, so it lives on the work, where reversing the
        // tempo map can't move it away from beat zero.
        //
        let t60 = Tempo(60)
        let t120 = Tempo(120)
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 4, pitch: .c4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: t60)
        tempoMap.insert(beatTime: 4, tempo: t120)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()),
                        extras: makeTimeCodeExtras())

        try work.reverse(within: nil as ClosedRange<BeatTime>?)

        #expect(work.extras == makeTimeCodeExtras())
    }

    @Test
    func reverse_keepsWorkExtrasInWallWork() throws {
        //
        // `midiTimeCode` describes the whole file, so it lives on the work, where reversing an
        // instrument table can't move it away from time zero.
        //
        let flute = try #require(Instrument(stringValue: "Flute"))
        let piccolo = try #require(Instrument(stringValue: "Piccolo"))
        var part = Part<WallTime, Pitch>(name: "Flute")

        part.noteTable.insert(attack: 0, duration: 4, pitch: .c4)
        part.instrumentTable.insert(time: 0, instrument: flute)
        part.instrumentTable.insert(time: 2, instrument: piccolo)

        var work = Work(content: .standardWall([part]),
                        extras: makeTimeCodeExtras())

        try work.reverse(within: nil as ClosedRange<WallTime>?)

        #expect(work.extras == makeTimeCodeExtras())
    }

    @Test
    func reverse_leadingRestMovesToEnd() throws {
        //
        // A beat of rest, then notes from 1 to 3; mf at 0 crescendos to f at 2. The default
        // range covers every layer that moves, 0...3, so the whole timeline is mirrored: the
        // notes land at 0–2 with the rest after them, and the dynamics become f at 1 and mf at 3,
        // a diminuendo.
        //
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)
        part.dynamicMap.insert(time: 0, dynamic: .mf)
        part.dynamicMap.insert(time: 2, dynamic: .f)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.reverse(within: nil as ClosedRange<BeatTime>?)

        let reversed = try #require(work.part(part.partID, as: Part<BeatTime, Pitch>.self))

        #expect(reversed.timeRange == 0...2)
        #expect(reversed.dynamicMap.map(\.time) == [1, 3])
        #expect(reversed.dynamicMap.map(\.dynamic) == [.f, .mf])
        #expect(work.tempoMap?.map(\.beatTime) == [3])
    }

    @Test
    func reverse_lockedWork_throwsAndLeavesWorkUnchanged() {
        var (work, partID) = makeLockedWorkSB()
        let beatTimeRange = work.beatTimeRange

        #expect(throws: Work.Error.workIsLocked) {
            try work.reverse(within: nil as ClosedRange<BeatTime>?, partIDs: [partID])
        }

        #expect(throws: Work.Error.workIsLocked) {
            try work.reverse(within: nil as ClosedRange<BeatTime>?)
        }

        #expect(work.beatTimeRange == beatTimeRange)
        #expect(work.pitchRange?.lowerBound as? Pitch == .c4)
    }

    @Test
    func reverse_mapEntryBeforeFirstNote_doesNotThrow() throws {
        //
        // The work opens with a beat of rest: the tempo (and the part's dynamic) is set at 0,
        // the first note attacks at 1. Reversing the whole work must not reject the map
        // entries that lie outside the notes' own span.
        //
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)
        part.dynamicMap.insert(time: 0, dynamic: .mf)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.reverse(within: nil as ClosedRange<BeatTime>?)
    }

    @Test
    func reverse_movesRampExtrasToNewRampStart() throws {
        //
        // The JohnnySonic ramp extras sit on the entry where the ramp starts, and the exporter
        // trusts them over the map. A 60→120 ramp over 0–4, reversed, is a 120→60 ramp that
        // still starts at 0: the extras must stay at 0 with start and end swapped.
        //
        let t60 = Tempo(60)
        let t120 = Tempo(120)
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 4, pitch: .c4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0,
                        tempo: t60,
                        extras: Extras(elements: [Extra(name: Extra.rampStartTempo.name, values: [.double(60)]),
                                                  Extra(name: Extra.rampEndTempo.name, values: [.double(120)]),
                                                  Extra(name: Extra.rampDuration.name, values: [.double(4)])]))
        tempoMap.insert(beatTime: 4, tempo: t120)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.reverse(within: nil as ClosedRange<BeatTime>?)

        let entries = Array(work.tempoMap ?? TempoMap())

        #expect(entries.map(\.beatTime) == [0, 4])
        #expect(extraValues(.rampStartTempo, in: entries.first?.extras) == [.double(120)])
        #expect(extraValues(.rampEndTempo, in: entries.first?.extras) == [.double(60)])
        #expect(extraValues(.rampDuration, in: entries.first?.extras) == [.double(4)])
        #expect(extraValues(.rampStartTempo, in: entries.last?.extras) == nil)
    }

    @Test
    func reverse_movesRampExtrasToNewRampStart_insertsEntry() throws {
        //
        // A 60→120 ramp over 0–3, then 120 from 4, reversed within 0–4, is a 120→60 ramp over
        // 1–4. No entry lands at 1, so one is inserted there, holding the tempo already in
        // effect, to carry the extras.
        //
        let t60 = Tempo(60)
        let t120 = Tempo(120)
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0,
                        tempo: t60,
                        extras: Extras(elements: [Extra(name: Extra.rampStartTempo.name, values: [.double(60)]),
                                                  Extra(name: Extra.rampEndTempo.name, values: [.double(120)]),
                                                  Extra(name: Extra.rampDuration.name, values: [.double(3)])]))
        tempoMap.insert(beatTime: 4, tempo: t120)

        var work = Work(content: .standardBeat([Part<BeatTime, Pitch>(name: "Violin")], tempoMap, MeterTable()))

        try work.reverse(within: BeatTime(0)...BeatTime(4))

        let entries = Array(work.tempoMap ?? TempoMap())
        let inserted = entries.first { $0.beatTime == 1 }

        #expect(entries.map(\.beatTime) == [0, 1, 4])
        #expect(inserted?.tempo == work.tempoMap?[BeatTime(1)])
        #expect(extraValues(.rampStartTempo, in: inserted?.extras) == [.double(120)])
        #expect(extraValues(.rampEndTempo, in: inserted?.extras) == [.double(60)])
        #expect(extraValues(.rampDuration, in: inserted?.extras) == [.double(3)])
        #expect(entries.filter { extraValues(.rampDuration, in: $0.extras) != nil }.count == 1)
    }

    @Test
    func reverse_movesTempoTextToSectionStart() throws {
        //
        // `tempoText` labels the section that starts at its entry. Andante (60) for 0–4 then
        // Allegro (120) for 4–8, reversed, is Allegro for 0–4 then Andante for 4–8, so each
        // label must move to its section's new start. The ABC exporter writes the label at
        // beat zero into the header.
        //
        let t60 = Tempo(60)
        let t120 = Tempo(120)
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 8, pitch: .c4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0,
                        tempo: t60,
                        extras: Extras(elements: [Extra(name: Extra.tempoText.name, values: [.string("Andante")])]))
        tempoMap.insert(beatTime: 4, tempo: t60)
        tempoMap.insert(beatTime: 4,
                        tempo: t120,
                        extras: Extras(elements: [Extra(name: Extra.tempoText.name, values: [.string("Allegro")])]))
        tempoMap.insert(beatTime: 8, tempo: t120)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.reverse(within: nil as ClosedRange<BeatTime>?)

        let labels = (work.tempoMap ?? TempoMap()).compactMap { entry in
            extraValues(.tempoText, in: entry.extras).map { (entry.beatTime, entry.tempo, $0) }
        }

        #expect(labels.count == 2)
        #expect(labels.first?.0 == 0)
        #expect(labels.first?.1 == t120)
        #expect(labels.first?.2 == [.string("Allegro")])
        #expect(labels.last?.0 == 4)
        #expect(labels.last?.1 == t60)
        #expect(labels.last?.2 == [.string("Andante")])
    }

    @Test
    func reverse_movesTempoTextToSectionStart_insertsEntryAtRangeStart() throws {
        //
        // Allegro (120) labels 4–8 and nothing sits at 8, so once reversed its section starts
        // at 0, where there's no entry either. One is inserted there holding the tempo the map
        // already reads at 0, so playback doesn't change.
        //
        let t60 = Tempo(60)
        let t120 = Tempo(120)
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 8, pitch: .c4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: t60)
        tempoMap.insert(beatTime: 4, tempo: t60)
        tempoMap.insert(beatTime: 4,
                        tempo: t120,
                        extras: Extras(elements: [Extra(name: Extra.tempoText.name, values: [.string("Allegro")])]))

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.reverse(within: nil as ClosedRange<BeatTime>?)

        let reversed = try #require(work.tempoMap)
        let labeled = reversed.filter { extraValues(.tempoText, in: $0.extras) != nil }

        #expect(reversed.map(\.beatTime) == [0, 4, 4, 8])
        #expect(labeled.map(\.beatTime) == [0])
        #expect(labeled.first?.tempo == t120)
        #expect(reversed[2] == t120)
        #expect(reversed[6] == t60)
    }

    @Test
    func reverse_movesTempoTextToSectionStart_spansUnlabeledChanges() throws {
        //
        // A label holds until the next label, across unlabeled changes. Allegro labels 0–8
        // (120, then an unlabeled step to 100 at 4) and Andante labels 8–12 (60). Reversed,
        // Andante labels 0–4 and Allegro 4–12, still covering both of its tempos.
        //
        let t60 = Tempo(60)
        let t100 = Tempo(100)
        let t120 = Tempo(120)
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 12, pitch: .c4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0,
                        tempo: t120,
                        extras: Extras(elements: [Extra(name: Extra.tempoText.name, values: [.string("Allegro")])]))
        tempoMap.insert(beatTime: 4, tempo: t120)
        tempoMap.insert(beatTime: 4, tempo: t100)
        tempoMap.insert(beatTime: 8, tempo: t100)
        tempoMap.insert(beatTime: 8,
                        tempo: t60,
                        extras: Extras(elements: [Extra(name: Extra.tempoText.name, values: [.string("Andante")])]))
        tempoMap.insert(beatTime: 12, tempo: t60)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.reverse(within: nil as ClosedRange<BeatTime>?)

        let labels = (work.tempoMap ?? TempoMap()).compactMap { entry in
            extraValues(.tempoText, in: entry.extras).map { (entry.beatTime, entry.tempo, $0) }
        }

        #expect(labels.count == 2)
        #expect(labels.first?.0 == 0)
        #expect(labels.first?.1 == t60)
        #expect(labels.first?.2 == [.string("Andante")])
        #expect(labels.last?.0 == 4)
        #expect(labels.last?.1 == t100)
        #expect(labels.last?.2 == [.string("Allegro")])
    }

    @Test
    func reverse_partialSelection_carriesTempoMap() throws {
        var violin = Part<BeatTime, Pitch>(name: "Violin")
        var cello = Part<BeatTime, Pitch>(name: "Cello")

        violin.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        violin.noteTable.insert(attack: 2, duration: 1, pitch: .e4)
        cello.noteTable.insert(attack: 5, duration: 1, pitch: .g4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([violin, cello], tempoMap, MeterTable()))

        try work.reverse(within: nil as ClosedRange<BeatTime>?,
                         partIDs: [violin.partID])

        //
        // The tempo map is work-wide, so it is reversed within the targeted part’s range (0...3)
        // even though only one part was targeted; the untargeted part is left alone.
        //
        #expect(work.tempoMap?.map(\.beatTime) == [1, 3])
        #expect(work.part(cello.partID, as: Part<BeatTime, Pitch>.self)?.timeRange == 5...6)
    }

    @Test
    func reverse_wholeWorkBeat_applyToWithoutTempo_leavesTempoMapUntouched() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.reverse(within: nil as ClosedRange<BeatTime>?,
                         applyTo: [.dynamic, .instrument, .pan])

        #expect(work.tempoMap?.map(\.beatTime) == [0, 2])
    }

    @Test
    func reverse_wholeWorkBeat_mirrorsEveryPartAndTempoMap() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.reverse(within: nil as ClosedRange<BeatTime>?)

        let tempoTimes = work.tempoMap?.map(\.beatTime) ?? []

        //
        // The part spans 0...3 (a note at 0 of duration 1, and one at 2 of duration 1), so the
        // aggregate beat-time range the tempo map is reversed within is 0...3, not 0...2 — the
        // tempo entries at 0 and 2 mirror to 3 and 1 respectively:
        //
        #expect(tempoTimes.sorted() == [1, 3])
    }
}
