// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

struct TemplateGenerationOptionsTests {
}

// MARK: -

extension TemplateGenerationOptionsTests {
    typealias Options = Template.GenerationOptions<BeatTime, Pitch>

    @Test
    func anyOptions_codable_roundTrip() throws {
        let options = Template.AnyGenerationOptions.standardBeat(Options(order: 2,
                                                                         length: .duration(16),
                                                                         stopsAtEnd: false,
                                                                         contrast: 1.5,
                                                                         constraints: .init(pitchRange: .c4 ... .g4,
                                                                                            allowsRests: false),
                                                                         mixing: .morph(to: 0,
                                                                                        over: 8,
                                                                                        curve: .logistic(steepness: 6)),
                                                                         cadence: .init(pitches: [.c4],
                                                                                        minimumLength: .noteCount(4))))
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(Template.AnyGenerationOptions.self,
                                               from: data)

        #expect(decoded == options)
        #expect(decoded.pitchNotation == .standard)
        #expect(decoded.timeBasis == .beat)
    }

    @Test
    func anyOptions_init_fromTypedOptions() {
        #expect(Template.AnyGenerationOptions(Options()) == .standardBeat(Options()))
        #expect(Template.AnyGenerationOptions(Template.GenerationOptions<WallTime, NoteNumber>()) == .keyboardWall(.init()))
    }

    @Test
    func backsOff_reachesLength() throws {
        let tmpl = try makeBranchingTemplate(maximumOrder: 2)

        for seed in UInt64(0)..<10 {
            let work = try tmpl.generateWork(name: "G",
                                             partName: "Part",
                                             options: Options(order: 2,
                                                              length: .noteCount(40),
                                                              backsOff: true),
                                             seed: seed)

            #expect(try standardBeatNoteEvents(of: work).count == 40)
        }
    }

    @Test
    func cadence_endsOnMatchAfterMinimum() throws {
        let tmpl = try makeBranchingTemplate()
        let cadence = Options.Cadence(pitches: [.c4],
                                      minimumLength: .noteCount(5))

        for seed in UInt64(0)..<10 {
            let work = try tmpl.generateWork(name: "G",
                                             partName: "Part",
                                             options: Options(length: .noteCount(200),
                                                              stopsAtEnd: false,
                                                              cadence: cadence),
                                             seed: seed)
            let events = try standardBeatNoteEvents(of: work)

            #expect(events.count >= 5)
            #expect(events.count < 200)
            #expect(try cadence.matches(#require(events.last)))
            #expect(!events.dropLast().enumerated().contains { $0.offset >= 4 && cadence.matches($0.element) })
        }
    }

    @Test
    func constraints_areRespected() throws {
        let tmpl = try makeBranchingTemplate()
        let constraints = Options.Constraints(pitchRange: .c4 ... .d4,
                                              allowsRests: false)

        for seed in UInt64(0)..<10 {
            let work = try tmpl.generateWork(name: "G",
                                             partName: "Part",
                                             options: Options(length: .noteCount(30),
                                                              stopsAtEnd: false,
                                                              backsOff: true,
                                                              constraints: constraints),
                                             seed: seed)
            let events = try standardBeatNoteEvents(of: work)

            #expect(!events.isEmpty)
            #expect(events.allSatisfy { constraints.allows($0) })
        }
    }

    @Test
    func generation_isRecordedOnWork() throws {
        let tmpl = try makeBranchingTemplate()
        let options = Options(order: 1,
                              length: .noteCount(12),
                              contrast: 2)
        let work = try tmpl.generateWork(name: "G",
                                         partName: "Part",
                                         options: options,
                                         seed: 99)
        let generation = try #require(work.generation)

        #expect(generation.templateID == tmpl.templateID)
        #expect(generation.templateName == tmpl.name)
        #expect(generation.options == .standardBeat(options))
        #expect(generation.seed == 99)
        #expect(work.duplicated().generation == generation)
    }

    @Test
    func generation_regenerate_reproducesWork() throws {
        let tmpl = try makeBranchingTemplate()
        let work = try tmpl.generateWork(name: "G",
                                         partName: "Part",
                                         order: 1,
                                         limit: 50)
        let generation = try #require(work.generation)
        let again = try tmpl.generateWork(name: "G",
                                          partName: "Part",
                                          options: generation.options,
                                          seed: generation.seed)

        #expect(try standardBeatNoteTriples(of: again) == standardBeatNoteTriples(of: work))
    }

    @Test
    func incompatibleOptions_throws() throws {
        let tmpl = try makeBranchingTemplate()

        #expect(throws: Template.Error.incompatibleOptions) {
            try tmpl.generateWork(name: "G",
                                  partName: "Part",
                                  options: Template.GenerationOptions<WallTime, Pitch>(),
                                  seed: 0)
        }

        #expect(throws: Template.Error.incompatibleOptions) {
            try tmpl.generateWork(name: "G",
                                  partName: "Part",
                                  options: .keyboardBeat(.init()),
                                  seed: 0)
        }
    }

    @Test
    func invalidOptions_throw() throws {
        let tmpl = try makeBranchingTemplate(maximumOrder: 2)

        let cases: [(Options, Template.Error)] = [(Options(order: 3), .invalidOrder(2)),
                                                  (Options(length: .noteCount(0)), .invalidLimit),
                                                  (Options(length: .duration(0)), .invalidLimit),
                                                  (Options(contrast: 0), .invalidContrast),
                                                  (Options(contrast: .infinity), .invalidContrast),
                                                  (Options(mixing: .blend(with: 3, weight: 0.5)), .invalidOrder(2)),
                                                  (Options(mixing: .blend(with: 0, weight: 1)), .invalidMixing),
                                                  (Options(mixing: .morph(to: 0, over: 0, curve: .linear)), .invalidMixing),
                                                  (Options(mixing: .morph(to: 0, over: 4, curve: .power(-1))), .invalidMixing),
                                                  (Options(cadence: .init(pitches: [], minimumLength: .noteCount(0))), .invalidLimit)]

        for (options, error) in cases {
            #expect(throws: error) {
                try tmpl.generateWork(name: "G",
                                      partName: "Part",
                                      options: options,
                                      seed: 0)
            }
        }
    }

    @Test
    func length_duration_stopsOnceReached() throws {
        let tmpl = try makeBranchingTemplate()

        for seed in UInt64(0)..<10 {
            let work = try tmpl.generateWork(name: "G",
                                             partName: "Part",
                                             options: Options(length: .duration(12),
                                                              stopsAtEnd: false),
                                             seed: seed)
            let events = try standardBeatNoteEvents(of: work)

            #expect(endTime(of: events) >= 12)
            #expect(endTime(of: events.dropLast()) < 12)
        }
    }

    @Test
    func loops_reachesLength() throws {
        let tmpl = try makeBranchingTemplate()
        let work = try tmpl.generateWork(name: "G",
                                         partName: "Part",
                                         options: Options(order: 1,
                                                          length: .noteCount(60),
                                                          loops: true),
                                         seed: 5)

        #expect(try standardBeatNoteEvents(of: work).count == 60)
    }

    @Test
    func mixing_blendAndMorph_generate() throws {
        let tmpl = try makeBranchingTemplate(maximumOrder: 2)

        for mixing in [Options.Mixing.blend(with: 0, weight: 0.3),
                       .morph(to: 0, over: 10, curve: .cosine),
                       .morph(to: 1, over: 10, curve: .power(2))] {
            let options = Options(order: 2,
                                  length: .noteCount(30),
                                  backsOff: true,
                                  mixing: mixing)
            let work1 = try tmpl.generateWork(name: "G", partName: "Part", options: options, seed: 3)
            let work2 = try tmpl.generateWork(name: "G", partName: "Part", options: options, seed: 3)

            //
            // Back-off means 30 events are generated; a note table can't keep a final rest, so 29
            // come back if the last is one.
            //
            #expect(try standardBeatNoteEvents(of: work1).count >= 29)
            #expect(try standardBeatNoteTriples(of: work1) == standardBeatNoteTriples(of: work2))
        }
    }

    @Test
    func seed_sameSeed_sameNotes_differentSeed_differentNotes() throws {
        let tmpl = try makeBranchingTemplate()
        let options = Options(length: .noteCount(60),
                              stopsAtEnd: false)
        let work1 = try tmpl.generateWork(name: "G", partName: "Part", options: options, seed: 1)
        let work2 = try tmpl.generateWork(name: "G", partName: "Part", options: options, seed: 1)
        let work3 = try tmpl.generateWork(name: "G", partName: "Part", options: options, seed: 2)

        #expect(try standardBeatNoteTriples(of: work1) == standardBeatNoteTriples(of: work2))
        #expect(try standardBeatNoteTriples(of: work1) != standardBeatNoteTriples(of: work3))
    }

    @Test
    func startsAtBegin_false_variesOpening() throws {
        let tmpl = try makeBranchingTemplate(maximumOrder: 3)
        var anchoredOpenings: Set<[NoteEvent<BeatTime, Pitch>]> = []
        var freeOpenings: Set<[NoteEvent<BeatTime, Pitch>]> = []

        for seed in UInt64(0)..<30 {
            let anchored = try tmpl.generateWork(name: "G",
                                                 partName: "Part",
                                                 options: Options(order: 3, length: .noteCount(3)),
                                                 seed: seed)
            let free = try tmpl.generateWork(name: "G",
                                             partName: "Part",
                                             options: Options(order: 3, length: .noteCount(3), startsAtBegin: false),
                                             seed: seed)

            try anchoredOpenings.insert(standardBeatNoteEvents(of: anchored))
            try freeOpenings.insert(standardBeatNoteEvents(of: free))
        }

        #expect(anchoredOpenings.count == 1)
        #expect(freeOpenings.count > 1)
    }

    @Test
    func stopsAtEnd_false_reachesLength() throws {
        let tmpl = try makeBranchingTemplate(maximumOrder: 3)
        let stopping = try tmpl.generateWork(name: "G",
                                             partName: "Part",
                                             options: Options(order: 3, length: .noteCount(500)),
                                             seed: 0)
        let endless = try tmpl.generateWork(name: "G",
                                            partName: "Part",
                                            options: Options(order: 3, length: .noteCount(500), stopsAtEnd: false),
                                            seed: 0)

        #expect(try standardBeatNoteEvents(of: stopping).count < 500)
        #expect(try standardBeatNoteEvents(of: endless).count == 500)
    }

    @Test
    func work_codable_withAndWithoutGeneration() throws {
        let tmpl = try makeBranchingTemplate()
        let generated = try tmpl.generateWork(name: "G",
                                              partName: "Part",
                                              options: Options(length: .noteCount(8)),
                                              seed: .max)
        let plain = Work(name: "Plain")

        let generatedData = try JSONEncoder().encode(generated)
        let plainData = try JSONEncoder().encode(plain)
        let plainJSON = try #require(String(data: plainData, encoding: .utf8))

        #expect(try JSONDecoder().decode(Work.self, from: generatedData).generation == generated.generation)
        #expect(try JSONDecoder().decode(Work.self, from: plainData).generation == nil)
        #expect(!plainJSON.contains("generation"))
    }
}
