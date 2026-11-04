// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct TemplateGenerationOptionsTemplateMixTests {
}

// MARK: -

extension TemplateGenerationOptionsTemplateMixTests {
    //
    // Without stopping at the end, an unseen context backs off to order 0 (XestiMarkov), so even
    // templates with no states in common mix.
    //
    @Test
    func blend_noSharedStates_runningOn_mixes() throws {
        let cs = try analyzeMixTemplate(makeOneBeatWork(Array(repeating: .c4, count: 6)))
        let ds = try analyzeMixTemplate(makeOneBeatWork(Array(repeating: .d4, count: 6)))

        let pitches = try standardBeatPitches(of: cs.generateWork(name: "G",
                                                                  partName: "Part",
                                                                  options: blendOptions(with: ds, weight: 0.5),
                                                                  seed: 2,
                                                                  mixingWith: [ds]))

        #expect(Set(pitches) == [.c4, .d4])
    }

    @Test
    func blend_noSharedStates_stopsAtEnd_staysInOneTemplate() throws {
        let cs = try analyzeMixTemplate(makeOneBeatWork(Array(repeating: .c4, count: 6)))
        let ds = try analyzeMixTemplate(makeOneBeatWork(Array(repeating: .d4, count: 6)))
        var seen: Set<Pitch> = []

        for seed: UInt64 in 1...20 {
            let pitches = try standardBeatPitches(of: cs.generateWork(name: "G",
                                                                      partName: "Part",
                                                                      options: blendOptions(with: ds,
                                                                                            stopsAtEnd: true),
                                                                      seed: seed,
                                                                      mixingWith: [ds]))

            #expect(Set(pitches).count == 1)

            seen.formUnion(pitches)
        }

        #expect(seen == [.c4, .d4])
    }

    @Test
    func blend_separatedTemplates_mixesBothChains() throws {
        let separated = Template.AnalysisOptions.StateRecipe(separatesPitchAndDuration: true)
        let thirds = try analyzeMixTemplate(makeOneBeatWork([.c4, .e4, .c4, .e4]), states: separated)
        let fifths = try analyzeMixTemplate(makeOneBeatWork([.c4, .g4, .c4, .g4]), states: separated)

        let pitches = try standardBeatPitches(of: thirds.generateWork(name: "G",
                                                                      partName: "Part",
                                                                      options: blendOptions(with: fifths, weight: 0.5),
                                                                      seed: 3,
                                                                      mixingWith: [fifths]))

        #expect(pitches.contains(.e4))
        #expect(pitches.contains(.g4))
    }

    @Test
    func blend_sharedStates_mixesFollowers() throws {
        let thirds = try analyzeMixTemplate(makeOneBeatWork([.c4, .e4, .c4, .e4, .c4, .e4]))
        let fifths = try analyzeMixTemplate(makeOneBeatWork([.c4, .g4, .c4, .g4, .c4, .g4]))

        let pitches = try standardBeatPitches(of: thirds.generateWork(name: "G",
                                                                      partName: "Part",
                                                                      options: blendOptions(with: fifths, weight: 0.5),
                                                                      seed: 3,
                                                                      mixingWith: [fifths]))

        #expect(pitches.contains(.e4))
        #expect(pitches.contains(.g4))
    }

    @Test
    func mix_differentStateRecipe_throws() throws {
        let thirds = try analyzeMixTemplate(makeOneBeatWork([.c4, .e4]))
        let intervals = try analyzeMixTemplate(makeOneBeatWork([.c4, .g4]), states: .init(pitch: .interval))

        #expect(throws: Template.Error.incompatibleTemplates) {
            try thirds.generateWork(name: "G", partName: "Part", options: blendOptions(with: intervals), seed: 1, mixingWith: [intervals])
        }
    }

    @Test(arguments: [0.0, 1.0, -0.5])
    func mix_invalidWeight_throws(weight: Double) throws {
        let thirds = try analyzeMixTemplate(makeOneBeatWork([.c4, .e4]))
        let fifths = try analyzeMixTemplate(makeOneBeatWork([.c4, .g4]))

        #expect(throws: Template.Error.invalidMixing) {
            try thirds.generateWork(name: "G", partName: "Part", options: blendOptions(with: fifths, weight: weight), seed: 1, mixingWith: [fifths])
        }
    }

    @Test
    func mix_missingTemplate_throws() throws {
        let thirds = try analyzeMixTemplate(makeOneBeatWork([.c4, .e4]))
        let fifths = try analyzeMixTemplate(makeOneBeatWork([.c4, .g4]))

        #expect(throws: Template.Error.templateNotFound(fifths.templateID)) {
            try thirds.generateWork(name: "G", partName: "Part", options: blendOptions(with: fifths), seed: 1)
        }
    }

    @Test
    func mix_otherTooLowOrder_throws() throws {
        let thirds = try analyzeMixTemplate(makeOneBeatWork([.c4, .e4, .g4]), maximumOrder: 2)
        let fifths = try analyzeMixTemplate(makeOneBeatWork([.c4, .g4]), maximumOrder: 1)
        let options = StandardBeatOptions(order: 2,
                                          templateMix: .blend([.init(template: .init(fifths), weight: 0.5)]))

        #expect(throws: Template.Error.incompatibleTemplates) {
            try thirds.generateWork(name: "G", partName: "Part", options: .standardBeat(options), seed: 1, mixingWith: [fifths])
        }
    }

    @Test
    func mix_sameSeed_sameWork_andRecorded() throws {
        let thirds = try analyzeMixTemplate(makeOneBeatWork([.c4, .e4, .c4, .e4]))
        let fifths = try analyzeMixTemplate(makeOneBeatWork([.c4, .g4, .c4, .g4]))
        let options = blendOptions(with: fifths, weight: 0.5)

        let work1 = try thirds.generateWork(name: "G", partName: "Part", options: options, seed: 9, mixingWith: [fifths])
        let work2 = try thirds.generateWork(name: "G", partName: "Part", options: options, seed: 9, mixingWith: [fifths, thirds])
        let decoded = try JSONDecoder().decode(Template.AnyGenerationOptions.self,
                                               from: JSONEncoder().encode(options))

        #expect(try standardBeatPitches(of: work1) == standardBeatPitches(of: work2))
        #expect(work1.generation?.options == options)
        #expect(decoded == options)
        #expect(options.otherTemplates.map(\.templateName) == ["Fifths"])
    }

    @Test
    func mix_withOrderMixing_throws() throws {
        let thirds = try analyzeMixTemplate(makeOneBeatWork([.c4, .e4, .g4]), maximumOrder: 2)
        let fifths = try analyzeMixTemplate(makeOneBeatWork([.c4, .g4, .d5]), maximumOrder: 2)
        let options = StandardBeatOptions(order: 2,
                                          mixing: .blend(with: 1, weight: 0.5),
                                          templateMix: .blend([.init(template: .init(fifths), weight: 0.5)]))

        #expect(throws: Template.Error.incompatibleOptions) {
            try thirds.generateWork(name: "G", partName: "Part", options: .standardBeat(options), seed: 1, mixingWith: [fifths])
        }
    }

    @Test
    func morph_withBackOff_endsInOtherTemplate() throws {
        let cs = try analyzeMixTemplate(makeOneBeatWork(Array(repeating: .c4, count: 6)))
        let ds = try analyzeMixTemplate(makeOneBeatWork(Array(repeating: .d4, count: 6)))
        let options = StandardBeatOptions(length: .noteCount(30),
                                          stopsAtEnd: false,
                                          backsOff: true,
                                          templateMix: .morph(to: .init(ds), over: 10, curve: .linear))

        let pitches = try standardBeatPitches(of: cs.generateWork(name: "G",
                                                                  partName: "Part",
                                                                  options: .standardBeat(options),
                                                                  seed: 5,
                                                                  mixingWith: [ds]))

        #expect(pitches.count == 30)
        #expect(pitches.first == .c4)
        #expect(pitches.suffix(10).allSatisfy { $0 == .d4 })
    }
}
