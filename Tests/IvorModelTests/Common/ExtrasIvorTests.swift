// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiTools

struct ExtrasIvorTests {
}

// MARK: -

extension ExtrasIvorTests {
    @Test
    func normalizingNames_alreadyNormalized_isUnchanged() {
        let extras = Extras(elements: [Extra(name: Extra.accent.name),
                                       Extra(name: "customTag", values: [.int(1)])])

        #expect(extras.normalizingNames() == extras)
    }

    @Test
    func normalizingNames_collidingNames_keepsOne() {
        let extras = Extras(elements: [Extra(name: "Accent"),
                                       Extra(name: "accent")])

        #expect(extras.elements.count == 2)
        #expect(extras.normalizingNames().elements.map(\.name) == [Extra.accent.name])
    }

    @Test
    func normalizingNames_empty() {
        #expect(Extras().normalizingNames().isEmpty)
    }

    @Test
    func normalizingNames_keepsValues() {
        let extras = Extras(elements: [Extra(name: "MIDIChannel", values: [.int(3)]),
                                       Extra(name: "Staccato")])
        let normalized = extras.normalizingNames()

        #expect(normalized.elements.map(\.name) == [Extra.midiChannel.name, Extra.staccato.name])
        #expect(normalized.elements.map(\.values) == [[.int(3)], []])
    }

    @Test
    func normalizingNames_mergesNamesThatNormalizeAlike() {
        let extras = Extras(elements: [Extra(name: "Accent"),
                                       Extra(name: "TempoText", values: [.string("Allegro")])])
        let normalized = extras.normalizingNames()

        #expect(normalized.elements.map(\.name) == [Extra.accent.name, Extra.tempoText.name])
        #expect(normalized.elements.last?.values == [.string("Allegro")])
    }
}
