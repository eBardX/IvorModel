// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateStatePitchValueTests {
}

// MARK: -

extension TemplateStatePitchValueTests {
    @Test
    func codable() throws {
        let values: [StandardBeatState.PitchValue] = [.absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)]),
                                                      .interval(bass: DirectedInterval(interval: .major3, direction: .ascending),
                                                                shape: [Template.Tone(value: DirectedInterval(interval: .perfect5,
                                                                                                              direction: .ascending),
                                                                                      startsTie: false,
                                                                                      endsTie: true)]),
                                                      .pitchClass([Template.Tone(value: .e, startsTie: true, endsTie: false)])]

        for value in values {
            let data = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(StandardBeatState.PitchValue.self,
                                                   from: data)

            #expect(decoded == value)
        }
    }

    @Test
    func comparable_absolute_lexicographic() {
        let lower = StandardBeatState.PitchValue.absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)])
        let chord = StandardBeatState.PitchValue.absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false),
                                                           Template.Tone(value: .e4, startsTie: false, endsTie: false)])
        let higher = StandardBeatState.PitchValue.absolute([Template.Tone(value: .d4, startsTie: false, endsTie: false)])

        #expect(lower < chord)
        #expect(chord < higher)
        #expect(!(higher < lower))
    }

    @Test
    func comparable_byKind() {
        let absolute = StandardBeatState.PitchValue.absolute([Template.Tone(value: .b9, startsTie: false, endsTie: false)])
        let interval = StandardBeatState.PitchValue.interval(bass: DirectedInterval(interval: .perfect1, direction: .same),
                                                             shape: [])
        let pitchClass = StandardBeatState.PitchValue.pitchClass([Template.Tone(value: .c, startsTie: false, endsTie: false)])

        #expect(absolute < interval)
        #expect(interval < pitchClass)
        #expect(!(pitchClass < absolute))
    }

    @Test
    func comparable_interval_bassFirst() {
        let bass1 = DirectedInterval(interval: Interval.major2, direction: .ascending)
        let bass2 = DirectedInterval(interval: Interval.major3, direction: .ascending)
        let shape = [Template.Tone(value: DirectedInterval(interval: Interval.perfect5, direction: .ascending),
                                   startsTie: false,
                                   endsTie: false)]
        let value1 = StandardBeatState.PitchValue.interval(bass: bass1, shape: [])
        let value2 = StandardBeatState.PitchValue.interval(bass: bass2, shape: shape)

        #expect((value1 < value2) == (bass1 < bass2))
        #expect((value2 < value1) == (bass2 < bass1))
    }

    @Test
    func comparable_interval_sameBass_byShape() {
        let bass = DirectedInterval(interval: Interval.major3, direction: .ascending)
        let tone = Template.Tone(value: DirectedInterval(interval: Interval.perfect5, direction: .ascending),
                                 startsTie: false,
                                 endsTie: false)

        #expect(StandardBeatState.PitchValue.interval(bass: bass, shape: []) < .interval(bass: bass, shape: [tone]))
    }

    @Test
    func comparable_pitchClass_lexicographic() {
        let lower = StandardBeatState.PitchValue.pitchClass([Template.Tone(value: .c, startsTie: false, endsTie: false)])
        let higher = StandardBeatState.PitchValue.pitchClass([Template.Tone(value: .d, startsTie: false, endsTie: false)])

        #expect(lower < higher)
        #expect(!(higher < lower))
    }

    @Test
    func hashable() {
        let values: Set<StandardBeatState.PitchValue> = [.absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)]),
                                                         .absolute([Template.Tone(value: .c4, startsTie: false, endsTie: false)]),
                                                         .pitchClass([Template.Tone(value: .c, startsTie: false, endsTie: false)])]

        #expect(values.count == 2)
    }
}
