// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

// swiftlint:disable:next type_name
struct TemplateAnalysisOptionsStateRecipeDurationFeatureTests {
}

// MARK: -

extension TemplateAnalysisOptionsStateRecipeDurationFeatureTests {
    @Test(arguments: [Template.AnalysisOptions.StateRecipe.DurationFeature.absolute, .omitted, .relative])
    func codable(feature: Template.AnalysisOptions.StateRecipe.DurationFeature) throws {
        let data = try JSONEncoder().encode(feature)
        let decoded = try JSONDecoder().decode(Template.AnalysisOptions.StateRecipe.DurationFeature.self,
                                               from: data)

        #expect(decoded == feature)
    }

    @Test
    func hashable_casesAreDistinct() {
        let features: Set<Template.AnalysisOptions.StateRecipe.DurationFeature> = [.absolute, .omitted, .relative, .absolute]

        #expect(features.count == 3)
    }
}
