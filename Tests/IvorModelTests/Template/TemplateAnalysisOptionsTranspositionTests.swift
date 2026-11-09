// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TemplateAnalysisOptionsTranspositionTests {
}

// MARK: -

extension TemplateAnalysisOptionsTranspositionTests {
    @Test
    func codable() throws {
        let transpositions: [Template.AnalysisOptions.Transposition] = [ascending(.major3),
                                                                        descending(5),
                                                                        .ratio(DirectedInterval(interval: Ratio(cents: 100),
                                                                                                direction: .ascending))]

        for transposition in transpositions {
            let data = try JSONEncoder().encode(transposition)
            let decoded = try JSONDecoder().decode(Template.AnalysisOptions.Transposition.self,
                                                   from: data)

            #expect(decoded == transposition)
        }
    }

    @Test
    func hashable() {
        let transpositions: Set<Template.AnalysisOptions.Transposition> = [ascending(.major3),
                                                                           ascending(.major3),
                                                                           descending(.major3),
                                                                           ascending(4)]

        #expect(transpositions.count == 3)
    }

    @Test
    func isUnison_interval() {
        #expect(Template.AnalysisOptions.Transposition.interval(DirectedInterval(interval: .perfect1,
                                                                                 direction: .same)).isUnison)
        #expect(!ascending(.major3).isUnison)
    }

    @Test
    func isUnison_noteDistance() {
        // swiftlint:disable:next force_unwrapping
        #expect(Template.AnalysisOptions.Transposition.noteDistance(DirectedInterval(interval: NoteDistance(uintValue: 0)!,
                                                                                     direction: .same)).isUnison)
        #expect(!ascending(2).isUnison)
    }

    @Test
    func isUnison_ratio() {
        #expect(Template.AnalysisOptions.Transposition.ratio(DirectedInterval(interval: .unison,
                                                                              direction: .same)).isUnison)
        #expect(!Template.AnalysisOptions.Transposition.ratio(DirectedInterval(interval: .octave,
                                                                               direction: .ascending)).isUnison)
    }
}
