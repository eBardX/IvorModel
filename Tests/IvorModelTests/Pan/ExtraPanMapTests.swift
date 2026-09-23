// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiTools

struct ExtraPanMapTests {
}

// MARK: -

extension ExtraPanMapTests {
    @Test
    func midiPan() {
        #expect(Extra.midiPan.name == "midiPan")
        #expect(Extra.midiPan.values.isEmpty)
    }
}
