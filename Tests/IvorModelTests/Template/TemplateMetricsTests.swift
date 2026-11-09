// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateMetricsTests {
}

// MARK: -

extension TemplateMetricsTests {
    @Test
    func equality() {
        let lhs = Template.Metrics(branchingRatio: 1.5, order: 1, recommendedOrder: 2, stateCount: 4, transitionCount: 6)
        let rhs = Template.Metrics(branchingRatio: 1.5, order: 1, recommendedOrder: 2, stateCount: 4, transitionCount: 6)

        #expect(lhs == rhs)
    }

    @Test
    func inequality() {
        #expect(Template.Metrics(branchingRatio: 1.5, order: 1, recommendedOrder: 2, stateCount: 4, transitionCount: 6)
                != Template.Metrics(branchingRatio: 1.5, order: 1, recommendedOrder: nil, stateCount: 4, transitionCount: 6))
    }

    @Test
    func metrics_fromTemplate_describeTrainedChain() throws {
        let template = try makeBranchingTemplate(maximumOrder: 2)
        let metrics = try #require(template.metrics(for: .joint))

        #expect(metrics.order == 2)
        #expect(metrics.stateCount > 0)
        #expect(metrics.transitionCount > 0)
        #expect(metrics.branchingRatio > 0)
    }
}
