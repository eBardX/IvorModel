// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiNumbers

struct NoteTableTremoloRateTests {
}

// MARK: -

extension NoteTableTremoloRateTests {
    @Test
    func tremoloRate_mapsStrokesToARate() throws {
        let rate: BeatNotes.TremoloRate = { notesPerSecond(Number($0.uintValue) * 4) }

        #expect(try rate(#require(TremoloStrokes(uintValue: 2))) == notesPerSecond(8))
    }

    @Test
    func tremoloRate_mayHaveNoRate() throws {
        let rate: BeatNotes.TremoloRate = { _ in nil }

        #expect(try rate(#require(TremoloStrokes(uintValue: 1))) == nil)
    }
}
