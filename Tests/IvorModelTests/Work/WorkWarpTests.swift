// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorSMPTE
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

        var instrumentTable = InstrumentTable<WallTime>()

        instrumentTable.insert(time: 1_000, instrument: Instrument(stringValue: "Piano").require())

        var panMap = PanMap<WallTime>()

        panMap.insert(time: 1_000, pan: .center)

        let part = Part<WallTime, Frequency>(name: "Piano",
                                             noteTable: table,
                                             dynamicMap: dynamicMap,
                                             instrumentTable: instrumentTable,
                                             panMap: panMap)
        let work = Work(name: "Test", content: .absoluteWall([part]))

        let result = try #require(work.unwarped(using: tempoMap))

        #expect(result.name == "Test")
        #expect(result.timeBasis == .beat)
        #expect(result.tempoMap == tempoMap)

        guard case let .absoluteBeat(parts, resultTempoMap, _) = result.content
        else { Issue.record("Expected .absoluteBeat content."); return }

        let expectedTime = timeConverter.beatTime(at: 1_000)

        #expect(resultTempoMap == tempoMap)
        #expect(parts[0].noteTable.notes.first?.attack == expectedTime)
        #expect(parts[0].dynamicMap.entries.first?.time == expectedTime)
        #expect(parts[0].instrumentTable.entries.first?.time == expectedTime)
        #expect(parts[0].panMap.entries.first?.time == expectedTime)
    }

    @Test
    func unwarped_beatTimeContent_returnsNil() {
        let tempoMap = TempoMap()

        #expect(try Work(content: .absoluteBeat([], tempoMap, MeterTable())).unwarped(using: tempoMap) == nil)
        #expect(try Work(content: .keyboardBeat([], tempoMap, MeterTable())).unwarped(using: tempoMap) == nil)
        #expect(try Work(content: .standardBeat([], tempoMap, MeterTable())).unwarped(using: tempoMap) == nil)
    }

    @Test
    func unwarped_convertsPedalTimes() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(120))

        let timeConverter = TimeConverter(tempoMap: tempoMap)

        var sustain = PedalTable<WallTime>()

        sustain.insert(time: 1_000, level: .up)
        sustain.insert(time: 1_000, level: .down)

        let part = Part<WallTime, Frequency>(name: "Piano", pedals: [.sustain: sustain])
        let work = Work(content: .absoluteWall([part]))

        let result = try #require(work.unwarped(using: tempoMap))

        guard case let .absoluteBeat(parts, _, _) = result.content
        else { Issue.record("Expected .absoluteBeat content."); return }

        let expectedTime = timeConverter.beatTime(at: 1_000)

        #expect(parts[0].pedals[.sustain]?.map(\.time) == [expectedTime, expectedTime])
        #expect(parts[0].pedals[.sustain]?.map(\.level) == [.up, .down])
    }

    @Test
    func unwarped_keepsExtras() throws {
        let part = Part<WallTime, Pitch>(name: "Violin", extras: makeChannelExtras(3))
        let work = Work(content: .standardWall([part]),
                        extras: makeTimeCodeExtras())

        let result = try #require(work.unwarped(using: TempoMap()))

        #expect(result.extras == work.extras)
        #expect(result.part(part.partID, as: Part<BeatTime, Pitch>.self)?.extras == part.extras)
    }

    @Test
    func unwarped_keepsInfo() throws {
        let part = Part<WallTime, Pitch>(name: "Violin")
        let work = Work(content: .standardWall([part]),
                        info: makeWorkInfo())

        let result = try #require(work.unwarped(using: TempoMap()))

        guard case .standardBeat = result.content
        else { Issue.record("Expected .standardBeat content."); return }

        #expect(result.info == work.info)
    }

    @Test
    func unwarped_keepsSMPTEStartTime() throws {
        let startTime = try #require(SMPTETime(string: "01:00:00:00", frameRate: .fps24))
        let work = Work(content: .standardWall([]),
                        smpteStartTime: startTime)

        #expect(work.unwarped(using: TempoMap())?.smpteStartTime == startTime)
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

        var instrumentTable = InstrumentTable<BeatTime>()

        instrumentTable.insert(time: 1, instrument: Instrument(stringValue: "Piano").require())

        var panMap = PanMap<BeatTime>()

        panMap.insert(time: 1, pan: .center)

        let part = Part<BeatTime, Frequency>(name: "Piano",
                                             noteTable: table,
                                             dynamicMap: dynamicMap,
                                             instrumentTable: instrumentTable,
                                             panMap: panMap)
        let work = Work(content: .absoluteBeat([part], tempoMap, MeterTable()))

        let result = try #require(try work.varispeeded(normalTempo: Tempo(60)))

        guard case let .absoluteWall(parts) = result.content
        else { Issue.record("Expected .absoluteWall content."); return }

        let expectedTime = timeConverter.wallTime(at: 1)

        #expect(parts[0].dynamicMap.entries.first?.time == expectedTime)
        #expect(parts[0].dynamicMap.entries.first?.dynamic == .mf)
        #expect(parts[0].instrumentTable.entries.first?.time == expectedTime)
        #expect(parts[0].instrumentTable.entries.first?.instrument == Instrument(stringValue: "Piano").require())
        #expect(parts[0].panMap.entries.first?.time == expectedTime)
        #expect(parts[0].panMap.entries.first?.pan == .center)
    }

    @Test
    func varispeeded_convertsPedalTimes() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(120))

        let timeConverter = TimeConverter(tempoMap: tempoMap)

        var table = NoteTable<BeatTime, Frequency>()

        table.insert(attack: 0, duration: 1, pitch: Frequency(440))

        var sustain = PedalTable<BeatTime>()

        sustain.insert(time: 1, level: .down)
        sustain.insert(time: 2, level: .up)
        sustain.insert(time: 2, level: .down)

        let part = Part<BeatTime, Frequency>(name: "Piano",
                                             noteTable: table,
                                             pedals: [.sustain: sustain])
        let work = Work(content: .absoluteBeat([part], tempoMap, MeterTable()))

        let result = try #require(try work.varispeeded(normalTempo: Tempo(60)))

        guard case let .absoluteWall(parts) = result.content
        else { Issue.record("Expected .absoluteWall content."); return }

        #expect(parts[0].pedals[.sustain]?.map(\.time) == [1, 2, 2].map { timeConverter.wallTime(at: BeatTime($0)) })
        #expect(parts[0].pedals[.sustain]?.map(\.level) == [.down, .up, .down])
    }

    @Test
    func varispeeded_keepsExtras() throws {
        let part = Part<BeatTime, Frequency>(name: "Violin", extras: makeChannelExtras(3))
        let work = Work(content: .absoluteBeat([part], TempoMap(), MeterTable()),
                        extras: makeTimeCodeExtras())

        let result = try #require(try work.varispeeded())

        #expect(result.extras == work.extras)
        #expect(result.part(part.partID, as: Part<WallTime, Frequency>.self)?.extras == part.extras)
    }

    @Test
    func varispeeded_keepsInfo() throws {
        let part = Part<BeatTime, Frequency>(name: "Violin")
        let work = Work(content: .absoluteBeat([part], TempoMap(), MeterTable()),
                        info: makeWorkInfo())

        let result = try #require(try work.varispeeded())

        guard case .absoluteWall = result.content
        else { Issue.record("Expected .absoluteWall content."); return }

        #expect(result.info == work.info)
    }

    @Test
    func varispeeded_keepsSMPTEStartTime() throws {
        let startTime = try #require(SMPTETime(string: "01:00:00:00", frameRate: .fps24))
        let work = Work(content: .absoluteBeat([], TempoMap(), MeterTable()),
                        smpteStartTime: startTime)

        #expect(try work.varispeeded()?.smpteStartTime == startTime)
    }

    @Test
    func varispeeded_lockedWork_returnsUnlockedResult() throws {
        var work = Work(content: .absoluteBeat([], TempoMap(), MeterTable()))

        work.isLocked = true

        let result = try #require(try work.varispeeded())

        #expect(result.isLocked == false)
    }

    @Test
    func varispeeded_nonAbsoluteBeatContent_returnsNil() throws {
        #expect(try Work(content: .absoluteWall([])).varispeeded() == nil)
        #expect(try Work(content: .keyboardBeat([], TempoMap(), MeterTable())).varispeeded() == nil)
        #expect(try Work(content: .keyboardWall([])).varispeeded() == nil)
        #expect(try Work(content: .standardBeat([], TempoMap(), MeterTable())).varispeeded() == nil)
        #expect(try Work(content: .standardWall([])).varispeeded() == nil)
    }

    @Test
    func varispeeded_pitchOutOfRange_throwsTransformFailure() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(1))

        var table = NoteTable<BeatTime, Frequency>()

        try table.insert(attack: 0, duration: 1, pitch: #require(Frequency(uintValue: 1)))

        let part = Part<BeatTime, Frequency>(name: "Piano", noteTable: table)
        let work = Work(content: .absoluteBeat([part], tempoMap, MeterTable()))

        do {
            _ = try work.varispeeded(normalTempo: Tempo(60))

            Issue.record("Expected varispeeded(normalTempo:) to throw.")
        } catch {
            guard case let .transformFailure(kind, partID, detail) = error
            else { Issue.record("Expected .transformFailure, got \(error)."); return }

            #expect(kind == .varispeed)
            #expect(partID == part.partID)
            #expect(detail.contains("varispeed"))
        }
    }

    @Test
    func varispeeded_tempoAboveNormalShiftsPitchUp() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: Tempo(120))

        var table = NoteTable<BeatTime, Frequency>()

        table.insert(attack: 0, duration: 1, pitch: Frequency(440))

        let part = Part<BeatTime, Frequency>(name: "Piano", noteTable: table)
        let work = Work(content: .absoluteBeat([part], tempoMap, MeterTable()))

        let result = try #require(try work.varispeeded(normalTempo: Tempo(60)))

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
        let work = Work(content: .absoluteBeat([part], tempoMap, MeterTable()))

        let result = try #require(try work.varispeeded(normalTempo: Tempo(60)))

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
        let work = Work(content: .absoluteBeat([part], tempoMap, MeterTable()))

        let result = try #require(try work.varispeeded(normalTempo: Tempo(60)))

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

        var instrumentTable = InstrumentTable<BeatTime>()

        instrumentTable.insert(time: 1, instrument: Instrument(stringValue: "Piano").require())

        var panMap = PanMap<BeatTime>()

        panMap.insert(time: 1, pan: .center)

        let part = Part<BeatTime, Frequency>(name: "Piano",
                                             noteTable: table,
                                             dynamicMap: dynamicMap,
                                             instrumentTable: instrumentTable,
                                             panMap: panMap)
        let work = Work(name: "Test", content: .absoluteBeat([part], tempoMap, MeterTable()))

        let result = try #require(work.warped())

        #expect(result.name == "Test")
        #expect(result.timeBasis == .wall)

        guard case let .absoluteWall(parts) = result.content
        else { Issue.record("Expected .absoluteWall content."); return }

        let expectedTime = timeConverter.wallTime(at: 1)

        #expect(parts[0].noteTable.notes.first?.attack == expectedTime)
        #expect(parts[0].dynamicMap.entries.first?.time == expectedTime)
        #expect(parts[0].instrumentTable.entries.first?.time == expectedTime)
        #expect(parts[0].panMap.entries.first?.time == expectedTime)
    }

    @Test
    func warped_keepsInfo() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        let work = Work(content: .standardBeat([part], TempoMap(), MeterTable()),
                        info: makeWorkInfo())

        let result = try #require(work.warped())

        guard case .standardWall = result.content
        else { Issue.record("Expected .standardWall content."); return }

        #expect(result.info == work.info)
    }

    @Test
    func warped_keepsSMPTEStartTime() throws {
        let startTime = try #require(SMPTETime(string: "01:00:00:00", frameRate: .fps24))
        let work = Work(content: .standardBeat([], TempoMap(), MeterTable()),
                        smpteStartTime: startTime)

        #expect(work.warped()?.smpteStartTime == startTime)
    }

    @Test
    func warped_keyboardBeat() {
        var table = NoteTable<BeatTime, NoteNumber>()

        table.insert(attack: 1, duration: 1, pitch: NoteNumber(uintValue: 69).require())

        let part = Part<BeatTime, NoteNumber>(name: "Piano", noteTable: table)
        let work = Work(content: .keyboardBeat([part], TempoMap(), MeterTable()))

        #expect(work.warped()?.timeBasis == .wall)
    }

    @Test
    func warped_lockedWork_returnsUnlockedResult() throws {
        var work = Work(content: .standardBeat([], TempoMap(), MeterTable()))

        work.isLocked = true

        let result = try #require(work.warped())

        #expect(result.isLocked == false)
    }

    @Test
    func warped_standardBeat() {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 1, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap(), MeterTable()))

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
        let work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        let warped = try #require(work.warped())
        let roundTripped = try #require(warped.unwarped(using: tempoMap))

        #expect(roundTripped.content.timeBasis == .beat)

        guard case let .standardBeat(originalParts, _, _) = work.content,
              case let .standardBeat(roundTrippedParts, _, _) = roundTripped.content
        else { Issue.record("Expected .standardBeat content."); return }

        #expect(roundTrippedParts[0].noteTable.notes.first?.attack == originalParts[0].noteTable.notes.first?.attack)
        #expect(roundTrippedParts[0].noteTable.notes.first?.duration == originalParts[0].noteTable.notes.first?.duration)
    }
}
