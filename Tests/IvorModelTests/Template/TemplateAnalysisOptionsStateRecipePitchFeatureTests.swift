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
struct TemplateAnalysisOptionsStateRecipePitchFeatureTests {
}

// MARK: -

extension TemplateAnalysisOptionsStateRecipePitchFeatureTests {
    @Test(arguments: [Template.AnalysisOptions.StateRecipe.PitchFeature.absolute, .interval, .omitted, .pitchClass])
    func codable(feature: Template.AnalysisOptions.StateRecipe.PitchFeature) throws {
        let data = try JSONEncoder().encode(feature)
        let decoded = try JSONDecoder().decode(Template.AnalysisOptions.StateRecipe.PitchFeature.self,
                                               from: data)

        #expect(decoded == feature)
    }

    @Test
    func hashable_casesAreDistinct() {
        let features: Set<Template.AnalysisOptions.StateRecipe.PitchFeature> = [.absolute, .interval, .omitted, .pitchClass, .omitted]

        #expect(features.count == 4)
    }
}
