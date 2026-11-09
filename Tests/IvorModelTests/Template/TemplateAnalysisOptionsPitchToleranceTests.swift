// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct TemplateAnalysisOptionsPitchToleranceTests {
}

// MARK: -

extension TemplateAnalysisOptionsPitchToleranceTests {
    @Test
    func codable() throws {
        let tolerance = Template.AnalysisOptions.PitchTolerance.cents(15)
        let data = try JSONEncoder().encode(tolerance)
        let decoded = try JSONDecoder().decode(Template.AnalysisOptions.PitchTolerance.self,
                                               from: data)

        #expect(decoded == tolerance)
    }

    @Test
    func hashable() {
        let tolerances: Set<Template.AnalysisOptions.PitchTolerance> = [.cents(10), .cents(10), .cents(20)]

        #expect(tolerances.count == 2)
    }

    @Test(arguments: [0, -5, Double.infinity, Double.nan])
    func validate_invalidCents_throws(cents: Double) {
        #expect(throws: Template.Error.invalidTolerance) {
            try Template.AnalysisOptions.PitchTolerance.cents(cents).validate()
        }
    }

    @Test
    func validate_positiveCents_succeeds() throws {
        try Template.AnalysisOptions.PitchTolerance.cents(25).validate()
    }
}
