// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TemplateAnalysisSummaryTests {
}

// MARK: -

extension TemplateAnalysisSummaryTests {
    @Test
    func adding_sumsCountsAndConcatenatesSkippedVariants() {
        let variant1 = Template.Variant(isInverted: true, isRetrograde: false, timeFactor: nil, transposition: nil)
        let variant2 = Template.Variant(isInverted: false, isRetrograde: true, timeFactor: nil, transposition: nil)
        let summary1 = Template.AnalysisSummary(sequenceCount: 2, mergedCount: 1, skippedVariants: [variant1])
        let summary2 = Template.AnalysisSummary(sequenceCount: 3, mergedCount: 4, skippedVariants: [variant2])

        let result = summary1.adding(summary2)

        #expect(result.mergedCount == 5)
        #expect(result.sequenceCount == 5)
        #expect(result.skippedVariants == [variant1, variant2])
    }

    @Test
    func codable() throws {
        let original = Template.AnalysisSummary(sequenceCount: 3,
                                                mergedCount: 1,
                                                skippedVariants: [Template.Variant(isInverted: true,
                                                                                   isRetrograde: false,
                                                                                   timeFactor: 2,
                                                                                   transposition: ascending(.major3))])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Template.AnalysisSummary.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func hashable() {
        let summaries: Set = [Template.AnalysisSummary(),
                              Template.AnalysisSummary(),
                              Template.AnalysisSummary(sequenceCount: 2)]

        #expect(summaries.count == 2)
    }

    @Test
    func init_defaults() {
        let summary = Template.AnalysisSummary()

        #expect(summary.mergedCount == 0)
        #expect(summary.sequenceCount == 1)
        #expect(summary.skippedVariants.isEmpty)
    }

    @Test
    func init_storesValues() {
        let summary = Template.AnalysisSummary(sequenceCount: 4, mergedCount: 2)

        #expect(summary.mergedCount == 2)
        #expect(summary.sequenceCount == 4)
    }
}
