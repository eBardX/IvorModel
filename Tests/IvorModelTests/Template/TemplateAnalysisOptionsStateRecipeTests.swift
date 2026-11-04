// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

struct TemplateAnalysisOptionsStateRecipeTests {
}

// MARK: -

extension TemplateAnalysisOptionsStateRecipeTests {
    @Test
    func generationOptions_withoutSamplesMembers_failsToDecode() throws {
        let data = try JSONEncoder().encode(Template.GenerationOptions<BeatTime, Pitch>(order: 2))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        object["samplesMembers"] = nil

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Template.GenerationOptions<BeatTime, Pitch>.self,
                                     from: JSONSerialization.data(withJSONObject: object))
        }
    }

    @Test
    func interval_chordShapeOverMovingBass_isOneShape() throws {
        let work = makeStandardBeatWork([(0, 1, .c4),
                                         (0, 1, .e4),
                                         (0, 1, .g4),
                                         (1, 1, .d4),
                                         (1, 1, .fSharp4),
                                         (1, 1, .a4)])
        let states = try sortedJointStates(of: analyzeRecipeTemplate(work, pitch: .interval))

        let shapes = Set(states.compactMap { state -> [Template.Tone<DirectedInterval<Interval>>]? in
            guard case let .interval(_, shape) = state.pitches
            else { return nil }

            return shape
        })

        #expect(states.count == 2)
        #expect(shapes.count == 1)
    }

    @Test
    func interval_transposition_hasSameStates() throws {
        let melody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 1, .e4), (2, 2, .g4), (4, 1, .d4)]
        let transposed: [(Number, Number, Pitch)] = [(0, 1, .f4), (1, 1, .a4), (2, 2, .c5), (4, 1, .g4)]

        let original = try sortedJointStates(of: analyzeRecipeTemplate(makeStandardBeatWork(melody), pitch: .interval))
        let moved = try sortedJointStates(of: analyzeRecipeTemplate(makeStandardBeatWork(transposed), pitch: .interval))

        #expect(original == moved)
        #expect(try sortedJointStates(of: analyzeRecipeTemplate(makeStandardBeatWork(melody), pitch: .absolute))
                != sortedJointStates(of: analyzeRecipeTemplate(makeStandardBeatWork(transposed), pitch: .absolute)))
    }

    @Test
    func invalidStateRecipe_throws() {
        #expect(throws: Template.Error.invalidStateRecipe) {
            try Template.analyzeNoteEvents(in: makeStandardBeatWork([(0, 1, .c4)]),
                                           at: 0,
                                           options: .init(maximumOrder: 1,
                                                          states: .init(pitch: .omitted,
                                                                        duration: .omitted)),
                                           name: "Test")
        }
    }

    @Test
    func pitchClass_octaveDisplacement_hasSameStates() throws {
        let melody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 1, .e4), (2, 1, .g4)]
        let displaced: [(Number, Number, Pitch)] = [(0, 1, .c5), (1, 1, .e3), (2, 1, .g4)]

        #expect(try sortedJointStates(of: analyzeRecipeTemplate(makeStandardBeatWork(melody), pitch: .pitchClass))
                == sortedJointStates(of: analyzeRecipeTemplate(makeStandardBeatWork(displaced), pitch: .pitchClass)))
    }

    @Test
    func range_constraintNarrowsIt() throws {
        let melody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 1, .e4), (2, 1, .g4), (3, 1, .c5)]
        let template = try analyzeRecipeTemplate(makeStandardBeatWork(melody), pitch: .interval)
        let range = Pitch.d4...Pitch.a4

        let work = try template.generateWork(name: "G",
                                             partName: "Part",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                                                  length: .noteCount(30),
                                                                                                  stopsAtEnd: false,
                                                                                                  constraints: .init(pitchRange: range),
                                                                                                  startPitch: .e4),
                                             seed: 4)

        #expect(try standardBeatNoteTriples(of: work).allSatisfy { range.contains($0.pitch) })
    }

    @Test
    func range_keepsRelativeGenerationWithinSource() throws {
        //
        // Always rising: unchecked, a looped interval template would climb out of sight.
        //
        let melody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 1, .e4), (2, 1, .g4), (3, 1, .c5)]
        let template = try analyzeRecipeTemplate(makeStandardBeatWork(melody), pitch: .interval)

        let work = try template.generateWork(name: "G",
                                             partName: "Part",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                                                  length: .noteCount(40),
                                                                                                  stopsAtEnd: false),
                                             seed: 9)
        let pitches = try standardBeatNoteTriples(of: work).map(\.pitch)

        #expect(pitches.count == 40)
        #expect(pitches.allSatisfy { (Pitch.c4...Pitch.c5).contains($0) })
    }

    @Test
    func realization_relativeRecipe_reproducesSource() throws {
        //
        // Every interval and ratio is different, so order 1 has one path: the source itself.
        //
        let melody: [(Number, Number, Pitch)] = [(0, 1, .c4),
                                                 (1, 2, .d4),
                                                 (3, Number(numerator: 1, denominator: 2), .f4),
                                                 (Number(numerator: 7, denominator: 2), 3, .b4)]
        let template = try analyzeRecipeTemplate(makeStandardBeatWork(melody),
                                                 pitch: .interval,
                                                 duration: .relative)

        let work = try template.generateWork(name: "G",
                                             partName: "Part",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(length: .noteCount(10)),
                                             seed: 1)

        #expect(try standardBeatNoteTriples(of: work) == standardBeatNoteTriples(of: makeStandardBeatWork(melody)))
    }

    @Test
    func realization_startAnchors_transposeAndScale() throws {
        let melody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 2, .d4), (3, 1, .f4)]
        let template = try analyzeRecipeTemplate(makeStandardBeatWork(melody),
                                                 pitch: .interval,
                                                 duration: .relative)

        let work = try template.generateWork(name: "G",
                                             partName: "Part",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(length: .noteCount(10),
                                                                                                  startPitch: .g4,
                                                                                                  startDuration: 2),
                                             seed: 1)

        #expect(try standardBeatNoteTriples(of: work) == standardBeatNoteTriples(of: makeStandardBeatWork([(0, 2, .g4), (2, 4, .a4), (6, 2, .c5)])))
    }

    @Test
    func relativeDuration_augmentation_hasSameStates() throws {
        let melody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 2, .d4), (3, 1, .e4)]
        let augmented: [(Number, Number, Pitch)] = [(0, 2, .c4), (2, 4, .d4), (6, 2, .e4)]

        #expect(try sortedJointStates(of: analyzeRecipeTemplate(makeStandardBeatWork(melody), duration: .relative))
                == sortedJointStates(of: analyzeRecipeTemplate(makeStandardBeatWork(augmented), duration: .relative)))
    }

    @Test
    func samplesMembers_drawsMembersReproducibly() throws {
        var noteTable = NoteTable<WallTime, Pitch>()
        var attack: UInt = 0

        for milliseconds: UInt in [500, 510, 505, 500, 510, 505, 500, 510] {
            noteTable.insert(attack: wallTime(attack), duration: wallDuration(milliseconds), pitch: .c4)
            attack += milliseconds
        }

        let template = try Template.analyzeNoteEvents(in: Work(content: .standardWall([Part(name: "Flute", noteTable: noteTable)])),
                                                      at: 0,
                                                      options: .init(maximumOrder: 1,
                                                                     durations: .proportional(0.05)),
                                                      name: "Test")
        let options = Template.GenerationOptions<WallTime, Pitch>(order: 0,
                                                                  length: .noteCount(20),
                                                                  stopsAtEnd: false,
                                                                  samplesMembers: true)

        let durations1 = try standardWallDurations(of: template.generateWork(name: "G", partName: "Part", options: options, seed: 2))
        let durations2 = try standardWallDurations(of: template.generateWork(name: "G", partName: "Part", options: options, seed: 2))

        #expect(durations1 == durations2)
        #expect(Set(durations1).isSubset(of: [wallDuration(500), wallDuration(505), wallDuration(510)]))
        #expect(Set(durations1).count > 1)
    }

    @Test
    func template_roundTripsThroughProject() throws {
        let template = try analyzeRecipeTemplate(makeStandardBeatWork([(0, 1, .c4), (1, 2, .e4), (0, 1, .g4)]),
                                                 pitch: .interval,
                                                 duration: .relative)
        var project = Project()

        project.updateTemplate(template)

        let loaded = try #require(Project.load(from: project.save()).fetchTemplate(template.templateID))

        #expect(loaded.analysisOptions == template.analysisOptions)
        #expect(try sortedJointStates(of: loaded) == sortedJointStates(of: template))
    }
}
