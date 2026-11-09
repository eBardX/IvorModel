// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct TemplateGenerationOptionsMixingTests {
}

// MARK: -

extension TemplateGenerationOptionsMixingTests {
    @Test
    func codable() throws {
        let mixings: [StandardBeatOptions.Mixing] = [.blend(with: 0, weight: 0.3),
                                                     .morph(to: 2, over: 16, curve: .logistic(steepness: 4))]

        for mixing in mixings {
            let data = try JSONEncoder().encode(mixing)
            let decoded = try JSONDecoder().decode(StandardBeatOptions.Mixing.self,
                                                   from: data)

            #expect(decoded == mixing)
        }
    }

    @Test
    func hashable() {
        let mixings: Set<StandardBeatOptions.Mixing> = [.blend(with: 0, weight: 0.3),
                                                        .blend(with: 0, weight: 0.3),
                                                        .morph(to: 0, over: 4, curve: .linear)]

        #expect(mixings.count == 2)
    }

    @Test(arguments: [0, 1, -0.5, Double.nan])
    func validate_blend_invalidWeight_throws(weight: Double) {
        #expect(throws: Template.Error.invalidMixing) {
            try StandardBeatOptions.Mixing.blend(with: 1, weight: weight).validate(maximumOrder: 2)
        }
    }

    @Test
    func validate_blend_orderOutOfRange_throws() {
        #expect(throws: Template.Error.invalidOrder(2)) {
            try StandardBeatOptions.Mixing.blend(with: 3, weight: 0.5).validate(maximumOrder: 2)
        }
    }

    @Test
    func validate_blend_valid_succeeds() throws {
        try StandardBeatOptions.Mixing.blend(with: 0, weight: 0.5).validate(maximumOrder: 2)
    }

    @Test
    func validate_morph_invalidCurve_throws() {
        #expect(throws: Template.Error.invalidMixing) {
            try StandardBeatOptions.Mixing.morph(to: 1, over: 4, curve: .power(0)).validate(maximumOrder: 2)
        }
    }

    @Test
    func validate_morph_nonPositiveSteps_throws() {
        #expect(throws: Template.Error.invalidMixing) {
            try StandardBeatOptions.Mixing.morph(to: 1, over: 0, curve: .linear).validate(maximumOrder: 2)
        }
    }

    @Test
    func validate_morph_orderOutOfRange_throws() {
        #expect(throws: Template.Error.invalidOrder(2)) {
            try StandardBeatOptions.Mixing.morph(to: -1, over: 4, curve: .linear).validate(maximumOrder: 2)
        }
    }

    @Test
    func validate_morph_valid_succeeds() throws {
        try StandardBeatOptions.Mixing.morph(to: 2, over: 8, curve: .cosine).validate(maximumOrder: 2)
    }
}
