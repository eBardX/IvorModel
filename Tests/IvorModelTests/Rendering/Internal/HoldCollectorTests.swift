// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct HoldCollectorTests {
}

// MARK: -

extension HoldCollectorTests {
    @Test
    func init_aCaesuraPausesTwoSecondsByDefault() throws {
        var part = try twoNotePart()

        part.markTable.insert(time: beatTime(frac(1, 2)), mark: .caesura(nil))

        let collector = HoldCollector(parts: [part], workRules: nil, clock: beatRenderingClock())
        let pause = try #require(collector.pauses.first)

        #expect(collector.holds.isEmpty)
        #expect(pause.time == frac(1, 2))
        #expect(pause.seconds == 2)
        #expect(isClose(pause.length, frac(1, 2)))
    }

    @Test
    func init_aCaesuraTakesItsExecution() throws {
        var part = try twoNotePart()

        part.markTable.insert(time: 1, mark: .caesura(CaesuraExecution(pause: .added(positiveBeats(1, 8)))))
        part.markTable.insert(time: 2, mark: .caesura(CaesuraExecution(pause: .seconds(positiveSeconds(3)))))

        let pauses = HoldCollector(parts: [part], workRules: nil, clock: beatRenderingClock()).pauses

        #expect(pauses.map(\.time) == [1, 2])
        #expect(pauses[0].length == frac(1, 8))
        #expect(isClose(pauses[0].seconds, frac(1, 2)))
        #expect(isClose(pauses[1].length, frac(3, 4)))
        #expect(pauses[1].seconds == 3)
    }

    @Test
    func init_aCaesuraTakesTheRules() throws {
        var part = try twoNotePart()

        part.markTable.insert(time: 1, mark: .caesura(nil))

        let pauses = HoldCollector(parts: [part],
                                   workRules: InterpretationRules(caesura: positiveSeconds(1)),
                                   clock: beatRenderingClock()).pauses

        #expect(pauses.map(\.seconds) == [1])
    }

    @Test
    func init_aFermataMarkHoldsWithNoNote() throws {
        var part = try twoNotePart()

        part.markTable.insert(time: 1, mark: quarterFermataMark(2))

        let collector = HoldCollector(parts: [part], workRules: nil, clock: beatRenderingClock())
        let hold = try #require(collector.holds.first)

        #expect(hold.noteID == nil)
        #expect(hold.span == frac(1, 2))
        #expect(hold.time == 1)
        #expect(collector.fermataTimes == [1])
    }

    @Test
    func init_aFermataNotPlayedHoldsNothingButIsCounted() throws {
        let part = try twoNotePart(Fermata(execution: FermataExecution(isPlayed: false)))
        let collector = HoldCollector(parts: [part], workRules: nil, clock: beatRenderingClock())

        #expect(collector.holds.isEmpty)
        #expect(collector.pauses.isEmpty)
        #expect(collector.fermataTimes == [0])
    }

    @Test
    func init_anExplicitAddedHold() throws {
        let part = try twoNotePart(Fermata(execution: FermataExecution(hold: .added(positiveBeats(1, 4)))))
        let hold = try #require(HoldCollector(parts: [part], workRules: nil, clock: beatRenderingClock()).holds.first)

        #expect(hold.extra == frac(1, 4))
        #expect(isClose(hold.extraSeconds, 1))
        #expect(hold.isExplicit)
    }

    @Test
    func init_anExplicitHoldInSeconds() throws {
        let part = try twoNotePart(Fermata(execution: FermataExecution(hold: .seconds(positiveSeconds(1)))))
        let hold = try #require(HoldCollector(parts: [part], workRules: nil, clock: beatRenderingClock()).holds.first)

        #expect(isClose(hold.extra, frac(1, 4)))
        #expect(hold.extraSeconds == 1)
    }

    @Test
    func init_aNoteFermataStretchesItsSpanByDefault() throws {
        let part = try twoNotePart(Fermata())
        let collector = HoldCollector(parts: [part], workRules: nil, clock: beatRenderingClock())
        let hold = try #require(collector.holds.first)

        //
        // A normal fermata doubles the C4's half note: half a whole note, 2 seconds, longer.
        //
        #expect(hold.extra == frac(1, 2))
        #expect(isClose(hold.extraSeconds, 2))
        #expect(!hold.isExplicit)
        #expect(hold.noteID == part.noteTable.first?.noteID)
        #expect(hold.part == 0)
        #expect(hold.span == frac(1, 2))
        #expect(hold.time == 0)
        #expect(collector.pauses.isEmpty)
    }

    @Test
    func init_eachShapeHasItsOwnDefaultStretch() throws {
        let part = try twoNotePart(Fermata(shape: .long))
        let hold = try #require(HoldCollector(parts: [part], workRules: nil, clock: beatRenderingClock()).holds.first)

        #expect(hold.extra == 1)
    }

    @Test
    func init_fermataTimesAreCountedOnceInOrder() throws {
        var first = try twoNotePart(Fermata())
        let second = try twoNotePart(Fermata())

        first.markTable.insert(time: 2, mark: quarterFermataMark(1))

        let collector = HoldCollector(parts: [first, second], workRules: nil, clock: beatRenderingClock())

        #expect(collector.fermataTimes == [0, 2])
        #expect(collector.holds.map(\.part) == [0, 0, 1])
    }

    @Test
    func init_pauseAfterFromTheExecution() throws {
        let part = try twoNotePart(Fermata(execution: FermataExecution(pauseAfter: .added(positiveBeats(1, 4)))))
        let pauses = HoldCollector(parts: [part], workRules: nil, clock: beatRenderingClock()).pauses

        #expect(pauses.map(\.time) == [frac(1, 2)])
        #expect(pauses.map(\.length) == [frac(1, 4)])
        #expect(isClose(pauses[0].seconds, 1))
    }

    @Test
    func init_pauseAfterFromTheRules() throws {
        let part = try twoNotePart(Fermata())
        let pauses = HoldCollector(parts: [part],
                                   workRules: InterpretationRules(fermata: FermataRules(pauseAfter: positiveSeconds(2))),
                                   clock: beatRenderingClock()).pauses

        #expect(pauses.map(\.seconds) == [2])
        #expect(isClose(pauses[0].length, frac(1, 2)))
    }

    @Test
    func init_theRulesSetTheHoldForAShape() throws {
        let part = try renderingPart([WrittenNote(0, frac(1, 2), .c4, BeatNotes.Ornamentation(fermata: Fermata()))],
                                     rules: InterpretationRules(fermata: FermataRules(holds: [.normal: .stretch(fermataStretch(3))])))
        let hold = try #require(HoldCollector(parts: [part], workRules: nil, clock: beatRenderingClock()).holds.first)

        #expect(hold.extra == 1)
        #expect(!hold.isExplicit)
    }
}
