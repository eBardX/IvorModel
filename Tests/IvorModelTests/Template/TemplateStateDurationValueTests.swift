// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateStateDurationValueTests {
}

// MARK: -

extension TemplateStateDurationValueTests {
    @Test
    func codable() throws {
        let values: [StandardBeatState.DurationValue] = [.absolute(beats(2)), .relative(Number(numerator: 3, denominator: 2))]

        for value in values {
            let data = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(StandardBeatState.DurationValue.self,
                                                   from: data)

            #expect(decoded == value)
        }
    }

    @Test
    func comparable_absoluteBeforeRelative() {
        #expect(StandardBeatState.DurationValue.absolute(beats(8)) < .relative(Number(numerator: 1, denominator: 2)))
        #expect(!(StandardBeatState.DurationValue.relative(Number(numerator: 1, denominator: 2)) < .absolute(beats(8))))
    }

    @Test
    func comparable_absoluteByDuration() {
        #expect(StandardBeatState.DurationValue.absolute(beats(1)) < .absolute(beats(2)))
        #expect(!(StandardBeatState.DurationValue.absolute(beats(2)) < .absolute(beats(2))))
    }

    @Test
    func comparable_relativeByRatio() {
        #expect(StandardBeatState.DurationValue.relative(1) < .relative(2))
        #expect(!(StandardBeatState.DurationValue.relative(2) < .relative(1)))
    }

    @Test
    func hashable() {
        let values: Set<StandardBeatState.DurationValue> = [.absolute(beats(1)), .absolute(beats(1)), .relative(1)]

        #expect(values.count == 2)
    }
}
