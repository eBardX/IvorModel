// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct TemplateMixTests {
}

// MARK: -

extension TemplateMixTests {
    @Test
    func blend_noSharedStates_stopsAtEnd_staysInOneTemplate() throws {
        let cs = try _analyze(_beatWork(Array(repeating: .c4, count: 6)))
        let ds = try _analyze(_beatWork(Array(repeating: .d4, count: 6)))
        var seen: Set<Pitch> = []

        for seed: UInt64 in 1...20 {
            let pitches = try _pitches(of: cs.generateWork(name: "G",
                                                           options: _blend(with: ds,
                                                                           stopsAtEnd: true),
                                                           seed: seed,
                                                           mixingWith: [ds]))

            #expect(Set(pitches).count == 1)

            seen.formUnion(pitches)
        }

        #expect(seen == [.c4, .d4])
    }

    //
    // Without stopping at the end, an unseen context backs off to order 0 (XestiMarkov), so even
    // templates with no states in common mix.
    //
    @Test
    func blend_noSharedStates_runningOn_mixes() throws {
        let cs = try _analyze(_beatWork(Array(repeating: .c4, count: 6)))
        let ds = try _analyze(_beatWork(Array(repeating: .d4, count: 6)))

        let pitches = try _pitches(of: cs.generateWork(name: "G",
                                                       options: _blend(with: ds, weight: 0.5),
                                                       seed: 2,
                                                       mixingWith: [ds]))

        #expect(Set(pitches) == [.c4, .d4])
    }

    @Test
    func blend_sharedStates_mixesFollowers() throws {
        let thirds = try _analyze(_beatWork([.c4, .e4, .c4, .e4, .c4, .e4]))
        let fifths = try _analyze(_beatWork([.c4, .g4, .c4, .g4, .c4, .g4]))

        let pitches = try _pitches(of: thirds.generateWork(name: "G",
                                                           options: _blend(with: fifths, weight: 0.5),
                                                           seed: 3,
                                                           mixingWith: [fifths]))

        #expect(pitches.contains(.e4))
        #expect(pitches.contains(.g4))
    }

    @Test
    func morph_withBackOff_endsInOtherTemplate() throws {
        let cs = try _analyze(_beatWork(Array(repeating: .c4, count: 6)))
        let ds = try _analyze(_beatWork(Array(repeating: .d4, count: 6)))
        let options = Options(length: .noteCount(30),
                              stopsAtEnd: false,
                              backsOff: true,
                              templateMix: .morph(to: .init(ds), over: 10, curve: .linear))

        let pitches = try _pitches(of: cs.generateWork(name: "G",
                                                       options: .standardBeat(options),
                                                       seed: 5,
                                                       mixingWith: [ds]))

        #expect(pitches.count == 30)
        #expect(pitches.first == .c4)
        #expect(pitches.suffix(10).allSatisfy { $0 == .d4 })
    }

    @Test
    func blend_separatedTemplates_mixesBothChains() throws {
        let separated = Template.AnalysisOptions.StateRecipe(separatesPitchAndDuration: true)
        let thirds = try _analyze(_beatWork([.c4, .e4, .c4, .e4]), states: separated)
        let fifths = try _analyze(_beatWork([.c4, .g4, .c4, .g4]), states: separated)

        let pitches = try _pitches(of: thirds.generateWork(name: "G",
                                                           options: _blend(with: fifths, weight: 0.5),
                                                           seed: 3,
                                                           mixingWith: [fifths]))

        #expect(pitches.contains(.e4))
        #expect(pitches.contains(.g4))
    }

    @Test
    func mix_sameSeed_sameWork_andRecorded() throws {
        let thirds = try _analyze(_beatWork([.c4, .e4, .c4, .e4]))
        let fifths = try _analyze(_beatWork([.c4, .g4, .c4, .g4]))
        let options = _blend(with: fifths, weight: 0.5)

        let work1 = try thirds.generateWork(name: "G", options: options, seed: 9, mixingWith: [fifths])
        let work2 = try thirds.generateWork(name: "G", options: options, seed: 9, mixingWith: [fifths, thirds])
        let decoded = try JSONDecoder().decode(Template.AnyGenerationOptions.self,
                                               from: JSONEncoder().encode(options))

        #expect(try _pitches(of: work1) == _pitches(of: work2))
        #expect(work1.generation?.options == options)
        #expect(decoded == options)
        #expect(options.otherTemplates.map(\.templateName) == ["Analysis of “Fifths”"])
    }

    @Test
    func mix_missingTemplate_throws() throws {
        let thirds = try _analyze(_beatWork([.c4, .e4]))
        let fifths = try _analyze(_beatWork([.c4, .g4]))

        #expect(throws: Template.Error.templateNotFound(fifths.templateID)) {
            try thirds.generateWork(name: "G", options: _blend(with: fifths), seed: 1)
        }
    }

    @Test
    func mix_differentStateRecipe_throws() throws {
        let thirds = try _analyze(_beatWork([.c4, .e4]))
        let intervals = try _analyze(_beatWork([.c4, .g4]), states: .init(pitch: .interval))

        #expect(throws: Template.Error.incompatibleTemplates) {
            try thirds.generateWork(name: "G", options: _blend(with: intervals), seed: 1, mixingWith: [intervals])
        }
    }

    @Test
    func mix_otherTooLowOrder_throws() throws {
        let thirds = try _analyze(_beatWork([.c4, .e4, .g4]), maximumOrder: 2)
        let fifths = try _analyze(_beatWork([.c4, .g4]), maximumOrder: 1)
        let options = Options(order: 2,
                              templateMix: .blend([.init(template: .init(fifths), weight: 0.5)]))

        #expect(throws: Template.Error.incompatibleTemplates) {
            try thirds.generateWork(name: "G", options: .standardBeat(options), seed: 1, mixingWith: [fifths])
        }
    }

    @Test(arguments: [0.0, 1.0, -0.5])
    func mix_invalidWeight_throws(weight: Double) throws {
        let thirds = try _analyze(_beatWork([.c4, .e4]))
        let fifths = try _analyze(_beatWork([.c4, .g4]))

        #expect(throws: Template.Error.invalidMixing) {
            try thirds.generateWork(name: "G", options: _blend(with: fifths, weight: weight), seed: 1, mixingWith: [fifths])
        }
    }

    @Test
    func mix_withOrderMixing_throws() throws {
        let thirds = try _analyze(_beatWork([.c4, .e4, .g4]), maximumOrder: 2)
        let fifths = try _analyze(_beatWork([.c4, .g4, .d5]), maximumOrder: 2)
        let options = Options(order: 2,
                              mixing: .blend(with: 1, weight: 0.5),
                              templateMix: .blend([.init(template: .init(fifths), weight: 0.5)]))

        #expect(throws: Template.Error.incompatibleOptions) {
            try thirds.generateWork(name: "G", options: .standardBeat(options), seed: 1, mixingWith: [fifths])
        }
    }
}

// MARK: - Private Type Aliases

private typealias Options = Template.GenerationOptions<BeatTime, Pitch>

// MARK: - Private Functions

private func _analyze(_ work: Work,
                      maximumOrder: Int = 1,
                      states: Template.AnalysisOptions.StateRecipe = .exact) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   at: 0,
                                   options: .init(maximumOrder: maximumOrder,
                                                  states: states))
}

//
// One beat each.  Named after its second pitch, so that templates read sensibly in failures.
//
private func _beatWork(_ pitches: [Pitch]) -> Work {
    var noteTable = NoteTable<BeatTime, Pitch>()

    for (index, pitch) in pitches.enumerated() {
        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: BeatTime(numberValue: Number(index))!,
                         duration: 1,
                         pitch: pitch)
    }

    let name = switch pitches.dropFirst().first {
    case .e4:
        "Thirds"

    case .g4:
        "Fifths"

    default:
        "Melody"
    }

    return Work(name: name,
                content: .standardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap()))
}

private func _blend(with other: Template,
                    weight: Double = 0.4,
                    stopsAtEnd: Bool = false) -> Template.AnyGenerationOptions {
    .standardBeat(Options(length: .noteCount(30),
                          stopsAtEnd: stopsAtEnd,
                          templateMix: .blend([.init(template: .init(other), weight: weight)])))
}

private func _pitches(of work: Work) throws -> [Pitch] {
    guard case let .standardBeat(parts, _) = work.content
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteTriplesSB(#require(parts.first).noteTable).map(\.pitch)
}
