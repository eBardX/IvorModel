// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkRetimeTests {
}

// MARK: -

extension WorkRetimeTests {
    @Test
    func retimed_keyTableMovesEachEntry() throws {
        let keyTable = try makeKeyTable([(0, 0), (2, -1)])
        let retimed = Work.retimed(keyTable) { position, isRelease in
            TimelineOperation.insert(at: 1, length: 1).mapped(position, isRelease: isRelease)
        }

        #expect(retimed.map(\.beatTime) == [0, 3])
        #expect(retimed.map(\.entryID) == keyTable.map(\.entryID))
    }

    @Test
    func retimed_meterTableKeepsTheEntryAtZeroAndThePickup() throws {
        let meterTable = try makeMeterTable([(0, "3/4"), (frac(3, 4), "2/4")], pickup: frac(1, 4))
        let retimed = Work.retimed(meterTable) { position, _ in position + 1 }

        #expect(retimed.map(\.beatTime) == [0, beatTime(frac(7, 4))])
        #expect(retimed.pickup == meterTable.pickup)
    }

    @Test
    func retimed_partMovesItsMapsAndMarks() throws {
        var part = try twoNotePart()

        part.dynamicMap.insert(time: beatTime(frac(1, 2)), dynamic: .ff)
        part.markTable.insert(time: beatTime(frac(1, 2)), mark: .caesura(nil))

        let retimed = Work.retimed(part) { position, isRelease in
            TimelineOperation.insert(at: frac(1, 2), length: frac(1, 2)).mapped(position, isRelease: isRelease)
        }

        #expect(retimed.strands[0].noteTable.map(\.attack) == [0, 1])
        #expect(retimed.strands[0].noteTable.map(\.duration) == [beats(frac(1, 2)), beats(frac(1, 2))])
        #expect(retimed.dynamicMap.map(\.time) == [1])
        #expect(retimed.markTable.map(\.time) == [1])
    }

    @Test
    func retimed_partNoteAcrossAnInsertionLengthens() throws {
        let part = try renderingPart([WrittenNote(0, 2, .c4)])
        let retimed = Work.retimed(part) { position, isRelease in
            TimelineOperation.insert(at: 1, length: 1).mapped(position, isRelease: isRelease)
        }

        #expect(retimed.strands[0].noteTable.map(\.duration) == [beats(3)])
        #expect(retimed.strands[0].noteTable.map(\.noteID) == part.strands[0].noteTable.map(\.noteID))
    }

    @Test
    func retimed_tempoMapMovesEachEntryInOrder() {
        var tempoMap = TempoMap(defaultTempo: Tempo(60))

        tempoMap.insert(beatTime: 1, tempo: Tempo(60))
        tempoMap.insert(beatTime: 1, tempo: Tempo(30))

        let retimed = Work.retimed(tempoMap) { position, _ in position * 2 }

        #expect(retimed.map(\.beatTime) == [2, 2])
        #expect(retimed.map(\.tempo) == [Tempo(60), Tempo(30)])
        #expect(retimed.defaultTempo == tempoMap.defaultTempo)
    }
}
