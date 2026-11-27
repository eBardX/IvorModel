// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkBodyTests {
}

// MARK: -

extension WorkBodyTests {
    @Test
    func beatBody_conformsToBeatTimeBodyOnly() {
        let content = Work.Content.keyboardBeat([], TempoMap(), MeterTable(), KeyTable())

        #expect(content.body is any Work.BeatTimeBody)
        #expect(!(content.body is any Work.WallTimeBody))
    }

    @Test
    func beatBody_readsItsTables() throws {
        let meterTable = try makeMeterTable([(0, "3/4")])
        let keyTable = try makeKeyTable([(0, 2)])
        let content = Work.Content.standardBeat([], TempoMap(), meterTable, keyTable)
        let body = try #require(content.body as? any Work.BeatTimeBody)

        #expect(body.meterTable == meterTable)
        #expect(body.keyTable == keyTable)
    }

    @Test
    func beatTimeRange_spansTheNotes() throws {
        var notes = NoteTable<BeatTime, Pitch>()

        notes.insert(attack: 1, duration: 2, pitch: .c4)

        let content = Work.Content.standardBeat([Part(name: "Flute", noteTable: notes)],
                                                TempoMap(),
                                                MeterTable(),
                                                KeyTable())
        let body = try #require(content.body as? any Work.BeatTimeBody)

        #expect(body.beatTimeRange == beatTime(1)...beatTime(3))
    }

    @Test
    func cases_matchTheFactories() {
        let checks: [(Work.Content, String)] = [(.absoluteBeat([], TempoMap(), MeterTable(), KeyTable()), "absoluteBeat"),
                                                (.absoluteWall([]), "absoluteWall"),
                                                (.keyboardBeat([], TempoMap(), MeterTable(), KeyTable()), "keyboardBeat"),
                                                (.keyboardWall([]), "keyboardWall"),
                                                (.standardBeat([], TempoMap(), MeterTable(), KeyTable()), "standardBeat"),
                                                (.standardWall([]), "standardWall")]

        for (content, name) in checks {
            #expect(Self._caseName(content.cases) == name)
        }
    }

    @Test
    func cases_keepTheParts() {
        let part = Part<WallTime, NoteNumber>(name: "Organ")
        let content = Work.Content.keyboardWall([part])

        guard case let .keyboardWall(parts) = content.cases
        else { Issue.record("Expected keyboard wall content"); return }

        #expect(parts.map(\.partID) == [part.partID])
    }

    @Test
    func empty_givesTheMatchingBody() {
        for timeBasis in [TimeBasis.beat, .wall] {
            for pitchNotation in [PitchNotation.absolute, .keyboard, .standard] {
                let content = Work.Content.empty(timeBasis: timeBasis,
                                                 pitchNotation: pitchNotation)

                #expect(content.timeBasis == timeBasis)
                #expect(content.pitchNotation == pitchNotation)
                #expect(content.body.partCount == 0)
            }
        }
    }

    @Test
    func existential_readsCountsAndNames() {
        var notes = NoteTable<BeatTime, Frequency>()

        notes.insert(attack: 0, duration: 1, pitch: Frequency(440))
        notes.insert(attack: 1, duration: 1, pitch: Frequency(220))

        let violin = Part<BeatTime, Frequency>(name: "Violin", noteTable: notes)
        let cello = Part<BeatTime, Frequency>(name: "Cello")
        let body: any Work.Body = Work.BeatBody(parts: [violin, cello])

        #expect(body.partCount == 2)
        #expect(body.noteCount == 2)
        #expect(body.partIDs == [violin.partID, cello.partID])
        #expect(body.partName(at: 1) == "Cello")
        #expect(body.pitchNotation == .absolute)
        #expect(body.timeBasis == .beat)
    }

    @Test
    func pitchNotation_followsThePitchType() {
        #expect(Work.WallBody<Frequency>.pitchNotation == .absolute)
        #expect(Work.WallBody<NoteNumber>.pitchNotation == .keyboard)
        #expect(Work.WallBody<Pitch>.pitchNotation == .standard)
        #expect(Work.BeatBody<Pitch>.timeBasis == .beat)
        #expect(Work.WallBody<Pitch>.timeBasis == .wall)
    }

    @Test
    func wallBody_conformsToWallTimeBodyOnly() throws {
        var notes = NoteTable<WallTime, Pitch>()

        notes.insert(attack: wallTime(500), duration: wallDuration(1_000), pitch: .c4)

        let content = Work.Content.standardWall([Part(name: "Flute", noteTable: notes)])
        let body = try #require(content.body as? any Work.WallTimeBody)

        #expect(!(content.body is any Work.BeatTimeBody))
        #expect(body.wallTimeRange == wallTime(500)...wallTime(1_500))
    }

    @Test
    func work_editsTheBodyInPlace() throws {
        var work = Work(content: .standardWall([]))
        let first = try work.addPart(name: "Flute")
        let second = try work.addPart(name: "Oboe")

        try work.shiftPart(second, to: 0)

        #expect(work.content.body.partIDs == [second, first])
        #expect(work.content.body is Work.WallBody<Pitch>)
    }

    // MARK: Private Type Methods

    private static func _caseName(_ cases: Work.Content.Cases) -> String {
        switch cases {
        case .absoluteBeat:
            "absoluteBeat"

        case .absoluteWall:
            "absoluteWall"

        case .keyboardBeat:
            "keyboardBeat"

        case .keyboardWall:
            "keyboardWall"

        case .standardBeat:
            "standardBeat"

        case .standardWall:
            "standardWall"
        }
    }
}
