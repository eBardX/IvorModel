// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct RenderingOptionsFermataModeTests {
}

// MARK: -

extension RenderingOptionsFermataModeTests {
    @Test
    func allCasesAreDistinct() {
        let modes: [RenderingOptions.FermataMode] = [.notRealized, .stretchedNotes, .tempoChanges]

        for (index, mode) in modes.enumerated() {
            for other in modes[(index + 1)...] {
                #expect(mode != other)
            }
        }
    }

    @Test
    func equality() {
        #expect(RenderingOptions.FermataMode.stretchedNotes == .stretchedNotes)
    }
}
