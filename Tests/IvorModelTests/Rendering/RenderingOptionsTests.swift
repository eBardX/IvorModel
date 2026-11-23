// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct RenderingOptionsTests {
}

// MARK: -

extension RenderingOptionsTests {
    @Test
    func equality() {
        let options = RenderingOptions(fermataMode: .stretchedNotes)

        #expect(options == RenderingOptions(fermataMode: .stretchedNotes))
    }

    @Test
    func inequality() {
        #expect(RenderingOptions(fermataMode: .notRealized) != RenderingOptions())
    }

    @Test
    func init_defaultsToTempoChanges() {
        #expect(RenderingOptions().fermataMode == .tempoChanges)
    }

    @Test
    func init_storesTheFermataMode() {
        #expect(RenderingOptions(fermataMode: .notRealized).fermataMode == .notRealized)
    }
}
