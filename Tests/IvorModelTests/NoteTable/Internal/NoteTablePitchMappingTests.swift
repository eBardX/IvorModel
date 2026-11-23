// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
import Testing

struct NoteTablePitchMappingTests {
}

// MARK: -

extension NoteTablePitchMappingTests {
    @Test
    func pitchMapping_canThrow() {
        let mapping: BeatNotes.PitchMapping = { _ in throw ConversionFailure() }

        #expect(throws: ConversionFailure.self) {
            try mapping(.c4)
        }
    }

    @Test
    func pitchMapping_mapsAPitchToTheSameType() throws {
        let mapping: BeatNotes.PitchMapping = swapCAndG

        #expect(try mapping(.c4) == .g4)
        #expect(try mapping(.e4) == .e4)
    }
}
