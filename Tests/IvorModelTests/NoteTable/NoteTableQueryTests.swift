// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableQueryTests {
}

// MARK: -

extension NoteTableQueryTests {
    private typealias NoteTableSB = NoteTable<BeatTime, Pitch>

    @Test
    func attackingIn_boundaryInclusive() {
        var table = NoteTableSB()

        let loID = table.insert(attack: 0, duration: 1, pitch: .c4)
        let hiID = table.insert(attack: 2, duration: 1, pitch: .e4)

        table.insert(attack: 1, duration: 1, pitch: .g4)

        let result = table.attackingIn(0...0)
        let result2 = table.attackingIn(2...2)

        #expect(result == [loID])
        #expect(result2 == [hiID])
    }

    @Test
    func attackingIn_emptyTable() {
        let table = NoteTableSB()

        #expect(table.attackingIn(0...10).isEmpty)
    }

    @Test
    func attackingIn_matching() {
        var table = NoteTableSB()

        let matchID = table.insert(attack: 1, duration: 1, pitch: .c4)

        table.insert(attack: 5, duration: 1, pitch: .e4)

        let result = table.attackingIn(0...2)

        #expect(result == [matchID])
    }

    @Test
    func attackingIn_notMatching() {
        var table = NoteTableSB()

        table.insert(attack: 5, duration: 1, pitch: .c4)

        let result = table.attackingIn(0...2)

        #expect(result.isEmpty)
    }

    @Test
    func pitchIn_boundaryInclusive() {
        var table = NoteTableSB()

        let loID = table.insert(attack: 0, duration: 1, pitch: .c4)
        let hiID = table.insert(attack: 1, duration: 1, pitch: .g4)

        table.insert(attack: 2, duration: 1, pitch: .a4)

        let result = table.pitchIn(.c4...(.g4))

        #expect(result == [loID, hiID])
    }

    @Test
    func pitchIn_emptyTable() {
        let table = NoteTableSB()

        #expect(table.pitchIn(.c4...(.c5)).isEmpty)
    }

    @Test
    func pitchIn_matching() {
        var table = NoteTableSB()

        let matchID = table.insert(attack: 0, duration: 1, pitch: .e4)

        table.insert(attack: 1, duration: 1, pitch: .a4)

        let result = table.pitchIn(.c4...(.g4))

        #expect(result == [matchID])
    }

    @Test
    func pitchIn_notMatching() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let result = table.pitchIn(.c4...(.g4))

        #expect(result.isEmpty)
    }

    @Test
    func pitchIn_straddlingPortamentoMatches() {
        var table = NoteTableSB()

        // A portamento from below the range to above it never has either endpoint
        // inside the range, but it glides through the whole thing, so it should
        // still match.
        let straddleID = table.insert(attack: 0, duration: 1, startPitch: .c4, endPitch: .c5)

        let result = table.pitchIn(.e4...(.g4))

        #expect(result == [straddleID])
    }

    @Test
    func soundingIn_boundaryInclusive() {
        var table = NoteTableSB()

        // Attacks exactly at the range's upper bound, and releases exactly at its
        // lower bound, both still count as sounding within the range.
        let attacksAtUpperID = table.insert(attack: 6, duration: 2, pitch: .c4)
        let releasesAtLowerID = table.insert(attack: 0, duration: 2, pitch: .e4)

        let result = table.soundingIn(2...6)

        #expect(result == [attacksAtUpperID, releasesAtLowerID])
    }

    @Test
    func soundingIn_emptyTable() {
        let table = NoteTableSB()

        #expect(table.soundingIn(0...10).isEmpty)
    }

    @Test
    func soundingIn_notOverlapping() {
        var table = NoteTableSB()

        table.insert(attack: 10, duration: 1, pitch: .c4)

        let result = table.soundingIn(0...2)

        #expect(result.isEmpty)
    }

    @Test
    func soundingIn_overlapsWithoutAttackInside() {
        var table = NoteTableSB()

        // Attacks before the range, but sustains through it.
        let overlapID = table.insert(attack: 0, duration: 10, pitch: .c4)

        let result = table.soundingIn(5...6)

        #expect(result == [overlapID])
    }
}
