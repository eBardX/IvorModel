// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct TemplateMorphCurveTests {
}

// MARK: -

extension TemplateMorphCurveTests {
    @Test(arguments: [Template.MorphCurve.cosine, .linear, .logistic(steepness: 6), .power(2)])
    func codable(curve: Template.MorphCurve) throws {
        let data = try JSONEncoder().encode(curve)
        let decoded = try JSONDecoder().decode(Template.MorphCurve.self,
                                               from: data)

        #expect(decoded == curve)
    }

    @Test
    func hashable() {
        let curves: Set<Template.MorphCurve> = [.cosine, .linear, .power(2), .power(2), .power(3)]

        #expect(curves.count == 4)
    }

    @Test
    func isValid_cosineAndLinear() {
        #expect(Template.MorphCurve.cosine.isValid)
        #expect(Template.MorphCurve.linear.isValid)
    }

    @Test(arguments: [0, -1, Double.infinity, Double.nan])
    func isValid_logistic_invalidSteepness(steepness: Double) {
        #expect(!Template.MorphCurve.logistic(steepness: steepness).isValid)
    }

    @Test
    func isValid_logistic_positiveSteepness() {
        #expect(Template.MorphCurve.logistic(steepness: 4).isValid)
    }

    @Test(arguments: [0, -2, Double.infinity, Double.nan])
    func isValid_power_invalidExponent(power: Double) {
        #expect(!Template.MorphCurve.power(power).isValid)
    }

    @Test
    func isValid_power_positiveExponent() {
        #expect(Template.MorphCurve.power(0.5).isValid)
    }
}
