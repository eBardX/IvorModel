// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing

struct TemplateAnalysisOptionsDurationToleranceTests {
}

// MARK: -

extension TemplateAnalysisOptionsDurationToleranceTests {
    @Test
    func codable() throws {
        let tolerances: [Template.AnalysisOptions.DurationTolerance] = [.proportional(0.1), .step(wallDuration(20))]

        for tolerance in tolerances {
            let data = try JSONEncoder().encode(tolerance)
            let decoded = try JSONDecoder().decode(Template.AnalysisOptions.DurationTolerance.self,
                                                   from: data)

            #expect(decoded == tolerance)
        }
    }

    @Test
    func hashable() {
        let tolerances: Set<Template.AnalysisOptions.DurationTolerance> = [.proportional(0.1),
                                                                           .proportional(0.1),
                                                                           .proportional(0.2),
                                                                           .step(wallDuration(20))]

        #expect(tolerances.count == 3)
    }

    @Test(arguments: [0, -0.1, Double.infinity, Double.nan])
    func validate_proportional_invalidFraction_throws(fraction: Double) {
        #expect(throws: Template.Error.invalidTolerance) {
            try Template.AnalysisOptions.DurationTolerance.proportional(fraction).validate()
        }
    }

    @Test
    func validate_proportional_positive_succeeds() throws {
        try Template.AnalysisOptions.DurationTolerance.proportional(0.05).validate()
    }

    @Test
    func validate_step_nonZero_succeeds() throws {
        try Template.AnalysisOptions.DurationTolerance.step(wallDuration(10)).validate()
    }

    @Test
    func validate_step_zero_throws() {
        #expect(throws: Template.Error.invalidTolerance) {
            try Template.AnalysisOptions.DurationTolerance.step(.zero).validate()
        }
    }
}
