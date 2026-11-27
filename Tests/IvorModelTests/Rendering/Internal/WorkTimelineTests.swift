// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkTimelineTests {
}

// MARK: -

extension WorkTimelineTests {
    @Test
    func applyingTimeline_aCaesuraInStretchedNotesInsertsTime() throws {
        var part = try twoNotePart()

        part.markTable.insert(time: beatTime(frac(1, 2)), mark: .caesura(nil))

        let result = renderingWork([part]).applyingTimeline(mode: .stretchedNotes)
        let parts = standardBeatParts(of: result.work)

        #expect(parts.first?.strands[0].noteTable.map(\.attack) == [0, 1])
        #expect(result.fermataTimes.isEmpty)
    }

    @Test
    func applyingTimeline_aWallWorkInsertsTime() throws {
        var table = NoteTable<WallTime, Pitch>()

        try table.insert(attack: wallTime(0), duration: wallDuration(2_000), pitch: .c4, ornamentation: .init(fermata: Fermata()))
        table.insert(attack: wallTime(2_000), duration: wallDuration(2_000), pitch: .d4)

        let result = Work(content: .standardWall([Part(name: "W", noteTable: table)])).applyingTimeline(mode: .tempoChanges)

        guard case let .standardWall(parts) = result.work.content.cases
        else { Issue.record("Expected standard wall content"); return }

        let notes = try #require(parts.first).strands[0].noteTable

        #expect(notes.map(\.attack) == [wallTime(0), wallTime(4_000)])
        #expect(result.fermataTimes == [.wall(wallTime(0))])
    }

    @Test
    func applyingTimeline_notRealizedConsumesTheSignsButKeepsTheTimes() throws {
        var part = try twoNotePart(Fermata())

        part.markTable.insert(time: 1, mark: .caesura(nil))

        let result = renderingWork([part]).applyingTimeline(mode: .notRealized)
        let parts = standardBeatParts(of: result.work)

        #expect(parts.first?.strands[0].noteTable.map(\.attack) == [0, beatTime(frac(1, 2))])
        #expect(parts.first?.strands[0].noteTable.allSatisfy { $0.ornamentation?.fermata == nil } == true)
        #expect(parts.first?.markTable.isEmpty == true)
        #expect(result.work.tempoMap?.isEmpty == true)
        #expect(result.fermataTimes == [.beat(0)])
    }

    @Test
    func applyingTimeline_stretchedNotesMovesEverythingLater() throws {
        let result = try renderingWork([twoNotePart(Fermata())]).applyingTimeline(mode: .stretchedNotes)
        let parts = standardBeatParts(of: result.work)

        #expect(parts.first?.strands[0].noteTable.map(\.attack) == [0, 1])
        #expect(parts.first?.strands[0].noteTable.map(\.duration) == [beats(1), beats(frac(1, 2))])
        #expect(result.work.tempoMap?.isEmpty == true)
        #expect(result.fermataTimes == [.beat(0)])
    }

    @Test
    func applyingTimeline_tempoChangesSlowsTheSpan() throws {
        let result = try renderingWork([twoNotePart(Fermata())]).applyingTimeline(mode: .tempoChanges)
        let parts = standardBeatParts(of: result.work)

        #expect(parts.first?.strands[0].noteTable.map(\.attack) == [0, beatTime(frac(1, 2))])
        #expect(result.work.tempoMap.map { $0.map(\.tempo) } == [Tempo(60), Tempo(30), Tempo(30), Tempo(60)])
    }

    @Test
    func applyingTimeline_unlocksTheWork() throws {
        var work = try renderingWork([twoNotePart()])

        work.isLocked = true

        #expect(!work.applyingTimeline(mode: .notRealized).work.isLocked)
    }
}
