// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateToneTests {
}

// MARK: -

extension TemplateToneTests {
    @Test
    func codable() throws {
        let original = Template.Tone(value: Pitch.c4, startsTie: true, endsTie: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Template.Tone<Pitch>.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func comparable_byValueFirst() {
        #expect(Template.Tone(value: Pitch.c4, startsTie: true, endsTie: true)
                < Template.Tone(value: Pitch.d4, startsTie: false, endsTie: false))
    }

    @Test
    func comparable_notLessThanSelf() {
        let tone = Template.Tone(value: Pitch.c4, startsTie: true, endsTie: false)

        #expect(!(tone < tone)) // swiftlint:disable:this identical_operands
    }

    @Test
    func comparable_sameValue_byTieFlags() {
        let neither = Template.Tone(value: Pitch.c4, startsTie: false, endsTie: false)
        let ends = Template.Tone(value: Pitch.c4, startsTie: false, endsTie: true)
        let starts = Template.Tone(value: Pitch.c4, startsTie: true, endsTie: false)
        let both = Template.Tone(value: Pitch.c4, startsTie: true, endsTie: true)

        #expect(neither < ends)
        #expect(ends < starts)
        #expect(starts < both)
    }

    @Test
    func hashable() {
        let tones: Set = [Template.Tone(value: Pitch.c4, startsTie: false, endsTie: false),
                          Template.Tone(value: Pitch.c4, startsTie: false, endsTie: false),
                          Template.Tone(value: Pitch.c4, startsTie: true, endsTie: false)]

        #expect(tones.count == 2)
    }

    @Test
    func init_storesValues() {
        let tone = Template.Tone(value: 7, startsTie: true, endsTie: false)

        #expect(tone.endsTie == false)
        #expect(tone.startsTie == true)
        #expect(tone.value == 7)
    }
}
