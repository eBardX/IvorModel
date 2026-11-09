// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateModelTests {
}

// MARK: -

extension TemplateModelTests {
    @Test
    func codable() throws {
        let markovChain = try #require(MarkovChain<StandardBeatState>(maximumOrder: 2))
        let vocabulary = Template.Vocabulary<BeatTime, Pitch>(durations: [beats(1): 3],
                                                              pitches: [.c4: 2, .e4: 1])
        let original = Template.Model(chains: .joint(markovChain),
                                      vocabulary: vocabulary)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Template.Model<BeatTime, Pitch>.self,
                                               from: data)

        #expect(decoded.chains.maximumOrder == 2)
        #expect(decoded.vocabulary == vocabulary)
    }

    @Test
    func init_defaultVocabularyIsEmpty() throws {
        let markovChain = try #require(MarkovChain<StandardBeatState>(maximumOrder: 1))
        let model = Template.Model<BeatTime, Pitch>(chains: .joint(markovChain))

        #expect(model.chains.maximumOrder == 1)
        #expect(model.vocabulary == Template.Vocabulary())
    }

    @Test
    func init_storesVocabulary() throws {
        let markovChain = try #require(MarkovChain<StandardBeatState>(maximumOrder: 1))
        let vocabulary = Template.Vocabulary<BeatTime, Pitch>(pitches: [.c4: 1])
        let model = Template.Model(chains: .joint(markovChain),
                                   vocabulary: vocabulary)

        #expect(model.vocabulary == vocabulary)
    }
}
