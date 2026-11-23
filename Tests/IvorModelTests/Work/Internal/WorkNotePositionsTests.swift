// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct WorkNotePositionsTests {
}

// MARK: -

extension WorkNotePositionsTests {
    @Test
    func init_storesEveryPosition() {
        let positions = Work.NotePositions(after: 5..<6, before: 0..<1, end: 2, partner: 3..<5, start: 1)

        #expect(positions.after == 5..<6)
        #expect(positions.before == 0..<1)
        #expect(positions.end == 2)
        #expect(positions.partner == 3..<5)
        #expect(positions.start == 1)
    }

    @Test
    func positions_areMutable() {
        var positions = Work.NotePositions(after: 0..<0, before: 0..<0, end: 0, partner: 0..<0, start: 0)

        positions.before = 0..<2
        positions.start = 2
        positions.end = 3

        #expect(positions.before == 0..<2)
        #expect(positions.end == 3)
        #expect(positions.start == 2)
    }
}
