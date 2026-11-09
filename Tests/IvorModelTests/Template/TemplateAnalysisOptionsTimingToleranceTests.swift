// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing

struct TemplateAnalysisOptionsTimingToleranceTests {
}

// MARK: -

extension TemplateAnalysisOptionsTimingToleranceTests {
    @Test
    func codable() throws {
        let tolerances: [Template.AnalysisOptions.TimingTolerance] = [.grid(factors: [2, 3]), .window(wallDuration(30))]

        for tolerance in tolerances {
            let data = try JSONEncoder().encode(tolerance)
            let decoded = try JSONDecoder().decode(Template.AnalysisOptions.TimingTolerance.self,
                                                   from: data)

            #expect(decoded == tolerance)
        }
    }

    @Test
    func hashable() {
        let tolerances: Set<Template.AnalysisOptions.TimingTolerance> = [.grid(factors: [2]),
                                                                         .grid(factors: [2]),
                                                                         .grid(factors: [3]),
                                                                         .window(wallDuration(30))]

        #expect(tolerances.count == 3)
    }

    @Test
    func validate_grid_emptyFactors_throws() {
        #expect(throws: Template.Error.invalidTolerance) {
            try Template.AnalysisOptions.TimingTolerance.grid(factors: []).validate()
        }
    }

    @Test(arguments: [[0], [2, -1]])
    func validate_grid_nonPositiveFactor_throws(factors: [Int]) {
        #expect(throws: Template.Error.invalidTolerance) {
            try Template.AnalysisOptions.TimingTolerance.grid(factors: factors).validate()
        }
    }

    @Test
    func validate_grid_positiveFactors_succeeds() throws {
        try Template.AnalysisOptions.TimingTolerance.grid(factors: [2, 3]).validate()
    }

    @Test
    func validate_window_nonZero_succeeds() throws {
        try Template.AnalysisOptions.TimingTolerance.window(wallDuration(30)).validate()
    }

    @Test
    func validate_window_zero_throws() {
        #expect(throws: Template.Error.invalidTolerance) {
            try Template.AnalysisOptions.TimingTolerance.window(.zero).validate()
        }
    }
}
