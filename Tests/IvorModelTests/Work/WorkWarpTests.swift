// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkWarpTests {
}

// MARK: -

extension WorkWarpTests {
    @Test
    func unwarped_absoluteWall() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(120))
        tempoMap.insert(beatTime: 4, tempo: Tempo(90))

        let timeConverter = TimeConverter(tempoMap: tempoMap)

        var table = NoteTable<WallTime, Frequency>()

        table.insert(attack: 1_000, duration: 1_000, pitch: Frequency(440))

        var dynamicMap = DynamicMap<WallTime>()

        dynamicMap.insert(time: 1_000, dynamic: .mf)

        var instrumentMap = InstrumentMap<WallTime>()

        instrumentMap.insert(time: 1_000, instrument: Instrument(stringValue: "Piano").require())

        var panMap = PanMap<WallTime>()

        panMap.insert(time: 1_000, pan: .center)

        let part = Part<WallTime, Frequency>(name: "Piano",
                                             noteTable: table,
                                             dynamicMap: dynamicMap,
                                             instrumentMap: instrumentMap,
                                             panMap: panMap)
        let work = Work(name: "Test", content: .absoluteWall([part]))

        let result = try #require(work.unwarped(using: tempoMap))

        #expect(result.name == "Test")
        #expect(result.timeBasis == .beat)
        #expect(result.tempoMap == tempoMap)

        guard case let .absoluteBeat(parts, resultTempoMap) = result.content
        else { Issue.record("Expected .absoluteBeat content."); return }

        let expectedTime = timeConverter.beatTime(at: 1_000)

        #expect(resultTempoMap == tempoMap)
        #expect(parts[0].noteTable.notes.first?.attack == expectedTime)
        #expect(parts[0].dynamicMap.entries.first?.time == expectedTime)
        #expect(parts[0].instrumentMap.entries.first?.time == expectedTime)
        #expect(parts[0].panMap.entries.first?.time == expectedTime)
    }

    @Test
    func unwarped_beatTimeContent_returnsNil() {
        let tempoMap = TempoMap()

        #expect(Work(content: .absoluteBeat([], tempoMap)).unwarped(using: tempoMap) == nil)
        #expect(Work(content: .keyboardBeat([], tempoMap)).unwarped(using: tempoMap) == nil)
        #expect(Work(content: .standardBeat([], tempoMap)).unwarped(using: tempoMap) == nil)
    }

    @Test
    func unwarped_keyboardWall() {
        var table = NoteTable<WallTime, NoteNumber>()

        table.insert(attack: 1_000, duration: 1_000, pitch: NoteNumber(uintValue: 69).require())

        let part = Part<WallTime, NoteNumber>(name: "Piano", noteTable: table)
        let work = Work(content: .keyboardWall([part]))

        #expect(work.unwarped(using: TempoMap())?.timeBasis == .beat)
    }

    @Test
    func unwarped_lockedWork_returnsUnlockedResult() throws {
        var work = Work(content: .standardWall([]))

        work.isLocked = true

        let result = try #require(work.unwarped(using: TempoMap()))

        #expect(result.isLocked == false)
    }

    @Test
    func unwarped_standardWall() {
        var table = NoteTable<WallTime, Pitch>()

        table.insert(attack: 1_000, duration: 1_000, pitch: .a4)

        let part = Part<WallTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardWall([part]))

        #expect(work.unwarped(using: TempoMap())?.timeBasis == .beat)
    }

    @Test
    func varispeeded_convertsMapTimesButNotValues() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(120))

        let timeConverter = TimeConverter(tempoMap: tempoMap)

        var table = NoteTable<BeatTime, Frequency>()

        table.insert(attack: 0, duration: 1, pitch: Frequency(440))

        var dynamicMap = DynamicMap<BeatTime>()

        dynamicMap.insert(time: 1, dynamic: .mf)

        var instrumentMap = InstrumentMap<BeatTime>()

        instrumentMap.insert(time: 1, instrument: Instrument(stringValue: "Piano").require())

        var panMap = PanMap<BeatTime>()

        panMap.insert(time: 1, pan: .center)

        let part = Part<BeatTime, Frequency>(name: "Piano",
                                             noteTable: table,
                                             dynamicMap: dynamicMap,
                                             instrumentMap: instrumentMap,
                                             panMap: panMap)
        let work = Work(content: .absoluteBeat([part], tempoMap))

        let result = try #require(work.varispeeded(normalTempo: Tempo(60)))

        guard case let .absoluteWall(parts) = result.content
        else { Issue.record("Expected .absoluteWall content."); return }

        let expectedTime = timeConverter.wallTime(at: 1)

        #expect(parts[0].dynamicMap.entries.first?.time == expectedTime)
        #expect(parts[0].dynamicMap.entries.first?.dynamic == .mf)
        #expect(parts[0].instrumentMap.entries.first?.time == expectedTime)
        #expect(parts[0].instrumentMap.entries.first?.instrument == Instrument(stringValue: "Piano").require())
        #expect(parts[0].panMap.entries.first?.time == expectedTime)
        #expect(parts[0].panMap.entries.first?.pan == .center)
    }

    @Test
    func varispeeded_lockedWork_returnsUnlockedResult() throws {
        var work = Work(content: .absoluteBeat([], TempoMap()))

        work.isLocked = true

        let result = try #require(work.varispeeded())

        #expect(result.isLocked == false)
    }

    @Test
    func varispeeded_nonAbsoluteBeatContent_returnsNil() {
        #expect(Work(content: .absoluteWall([])).varispeeded() == nil)
        #expect(Work(content: .keyboardBeat([], TempoMap())).varispeeded() == nil)
        #expect(Work(content: .keyboardWall([])).varispeeded() == nil)
        #expect(Work(content: .standardBeat([], TempoMap())).varispeeded() == nil)
        #expect(Work(content: .standardWall([])).varispeeded() == nil)
    }

    @Test
    func varispeeded_tempoAboveNormalShiftsPitchUp() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(120))

        var table = NoteTable<BeatTime, Frequency>()

        table.insert(attack: 0, duration: 1, pitch: Frequency(440))

        let part = Part<BeatTime, Frequency>(name: "Piano", noteTable: table)
        let work = Work(content: .absoluteBeat([part], tempoMap))

        let result = try #require(work.varispeeded(normalTempo: Tempo(60)))

        guard case let .absoluteWall(parts) = result.content
        else { Issue.record("Expected .absoluteWall content."); return }

        let attackPitch = parts[0].noteTable.notes.first?.startPitch

        #expect(try #require(attackPitch).numberValue > Frequency(440).numberValue)
    }

    @Test
    func varispeeded_tempoBelowNormalShiftsPitchDown() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(30))

        var table = NoteTable<BeatTime, Frequency>()

        table.insert(attack: 0, duration: 1, pitch: Frequency(440))

        let part = Part<BeatTime, Frequency>(name: "Piano", noteTable: table)
        let work = Work(content: .absoluteBeat([part], tempoMap))

        let result = try #require(work.varispeeded(normalTempo: Tempo(60)))

        guard case let .absoluteWall(parts) = result.content
        else { Issue.record("Expected .absoluteWall content."); return }

        let attackPitch = parts[0].noteTable.notes.first?.startPitch

        #expect(try #require(attackPitch).numberValue < Frequency(440).numberValue)
    }

    @Test
    func varispeeded_tempoEqualToNormalPreservesPitch() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(60))

        var table = NoteTable<BeatTime, Frequency>()

        table.insert(attack: 0, duration: 1, pitch: Frequency(440))

        let part = Part<BeatTime, Frequency>(name: "Piano", noteTable: table)
        let work = Work(content: .absoluteBeat([part], tempoMap))

        let result = try #require(work.varispeeded(normalTempo: Tempo(60)))

        guard case let .absoluteWall(parts) = result.content
        else { Issue.record("Expected .absoluteWall content."); return }

        #expect(parts[0].noteTable.notes.first?.startPitch == Frequency(440))
    }

    @Test
    func warped_absoluteBeat() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(120))

        let timeConverter = TimeConverter(tempoMap: tempoMap)

        var table = NoteTable<BeatTime, Frequency>()

        table.insert(attack: 1, duration: 1, pitch: Frequency(440))

        var dynamicMap = DynamicMap<BeatTime>()

        dynamicMap.insert(time: 1, dynamic: .mf)

        var instrumentMap = InstrumentMap<BeatTime>()

        instrumentMap.insert(time: 1, instrument: Instrument(stringValue: "Piano").require())

        var panMap = PanMap<BeatTime>()

        panMap.insert(time: 1, pan: .center)

        let part = Part<BeatTime, Frequency>(name: "Piano",
                                             noteTable: table,
                                             dynamicMap: dynamicMap,
                                             instrumentMap: instrumentMap,
                                             panMap: panMap)
        let work = Work(name: "Test", content: .absoluteBeat([part], tempoMap))

        let result = try #require(work.warped())

        #expect(result.name == "Test")
        #expect(result.timeBasis == .wall)

        guard case let .absoluteWall(parts) = result.content
        else { Issue.record("Expected .absoluteWall content."); return }

        let expectedTime = timeConverter.wallTime(at: 1)

        #expect(parts[0].noteTable.notes.first?.attack == expectedTime)
        #expect(parts[0].dynamicMap.entries.first?.time == expectedTime)
        #expect(parts[0].instrumentMap.entries.first?.time == expectedTime)
        #expect(parts[0].panMap.entries.first?.time == expectedTime)
    }

    @Test
    func warped_keyboardBeat() {
        var table = NoteTable<BeatTime, NoteNumber>()

        table.insert(attack: 1, duration: 1, pitch: NoteNumber(uintValue: 69).require())

        let part = Part<BeatTime, NoteNumber>(name: "Piano", noteTable: table)
        let work = Work(content: .keyboardBeat([part], TempoMap()))

        #expect(work.warped()?.timeBasis == .wall)
    }

    @Test
    func warped_lockedWork_returnsUnlockedResult() throws {
        var work = Work(content: .standardBeat([], TempoMap()))

        work.isLocked = true

        let result = try #require(work.warped())

        #expect(result.isLocked == false)
    }

    @Test
    func warped_standardBeat() {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 1, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))

        #expect(work.warped()?.timeBasis == .wall)
    }

    @Test
    func warped_wallTimeContent_returnsNil() {
        #expect(Work(content: .absoluteWall([])).warped() == nil)
        #expect(Work(content: .keyboardWall([])).warped() == nil)
        #expect(Work(content: .standardWall([])).warped() == nil)
    }

    @Test
    func warpedThenUnwarped_roundTrips() throws {
        // Constant tempo across two entries — keeps the beat↔wall arithmetic rational so the
        // round trip is exact, matching `TimeConverterTests.roundTrip_multiEntry`'s own
        // convention of avoiding transcendental rounding error from an actual tempo change.
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(120))
        tempoMap.insert(beatTime: 4, tempo: Tempo(120))

        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 1, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], tempoMap))

        let warped = try #require(work.warped())
        let roundTripped = try #require(warped.unwarped(using: tempoMap))

        #expect(roundTripped.content.timeBasis == .beat)

        guard case let .standardBeat(originalParts, _) = work.content,
              case let .standardBeat(roundTrippedParts, _) = roundTripped.content
        else { Issue.record("Expected .standardBeat content."); return }

        #expect(roundTrippedParts[0].noteTable.notes.first?.attack == originalParts[0].noteTable.notes.first?.attack)
        #expect(roundTrippedParts[0].noteTable.notes.first?.duration == originalParts[0].noteTable.notes.first?.duration)
    }
}
